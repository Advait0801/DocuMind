//
//  NetworkService.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import Foundation

@MainActor
class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "http://localhost:8000"
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Generic Request Methods
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            if let token = AuthService.shared.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle error status codes
            if httpResponse.statusCode >= 400 {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: errorMessage?.detail ?? "Unknown error"
                )
            }
            
            // Handle 204 No Content
            if httpResponse.statusCode == 204 {
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
            }
            
            do {
                let decoder = JSONDecoder()
                // Try ISO8601 with fractional seconds first, then fallback to standard
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Create formatter inside closure to avoid Sendable warning
                    let formatterWithFractional = ISO8601DateFormatter()
                    formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    if let date = formatterWithFractional.date(from: dateString) {
                        return date
                    }
                    
                    // Try without fractional seconds
                    let formatterStandard = ISO8601DateFormatter()
                    formatterStandard.formatOptions = [.withInternetDateTime]
                    return formatterStandard.date(from: dateString) ?? Date()
                }
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Upload Request
    func upload(
        endpoint: String,
        fileURL: URL,
        fileName: String
    ) async throws -> UploadResponse {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        guard let token = AuthService.shared.accessToken else {
            throw APIError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        
        let fileData = try Data(contentsOf: fileURL)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode >= 400 {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: errorMessage?.detail ?? "Unknown error"
                )
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(UploadResponse.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Streaming Request
    func streamQuery(
        request: QueryRequest
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                guard let url = URL(string: "\(baseURL)/query") else {
                    continuation.finish(throwing: APIError.invalidURL)
                    return
                }
                
                guard let token = AuthService.shared.accessToken else {
                    continuation.finish(throwing: APIError.unauthorized)
                    return
                }
                
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                do {
                    urlRequest.httpBody = try JSONEncoder().encode(request)
                } catch {
                    continuation.finish(throwing: APIError.encodingError(error))
                    return
                }
                
                do {
                    let (asyncBytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        continuation.finish(throwing: APIError.httpError(
                            statusCode: httpResponse.statusCode,
                            message: "Request failed"
                        ))
                        return
                    }
                    
                    var buffer = Data()
                    for try await byte in asyncBytes {
                        buffer.append(byte)
                        
                        // Look for newline to process complete lines
                        if let newlineIndex = buffer.firstIndex(of: 0x0A) { // \n
                            let lineData = buffer.prefix(upTo: newlineIndex)
                            buffer.removeSubrange(..<buffer.index(after: newlineIndex))
                            
                            if let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) {
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if let jsonData = jsonString.data(using: .utf8) {
                                        do {
                                            let chunk = try JSONDecoder().decode(StreamChunk.self, from: jsonData)
                                            continuation.yield(chunk)
                                            
                                            if chunk.type == .done {
                                                continuation.finish()
                                                return
                                            }
                                        } catch {
                                            // Skip invalid JSON lines
                                            continue
                                        }
                                    }
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: APIError.networkError(error))
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct ErrorResponse: Codable {
    let detail: String
}

struct EmptyResponse: Codable {}
