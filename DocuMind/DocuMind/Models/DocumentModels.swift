//
//  DocumentModels.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import Foundation

// MARK: - Document Models
struct DocumentInfo: Codable, Identifiable {
    let doc_id: String
    let filename: String
    let uploaded_at: Date
    let chunk_count: Int
    let file_size: Int
    
    var id: String { doc_id }
    
    enum CodingKeys: String, CodingKey {
        case doc_id, filename, uploaded_at, chunk_count, file_size
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        doc_id = try container.decode(String.self, forKey: .doc_id)
        filename = try container.decode(String.self, forKey: .filename)
        chunk_count = try container.decode(Int.self, forKey: .chunk_count)
        file_size = try container.decode(Int.self, forKey: .file_size)
        
        // Handle date decoding with multiple formats
        let dateString = try container.decode(String.self, forKey: .uploaded_at)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            uploaded_at = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            uploaded_at = formatter.date(from: dateString) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(doc_id, forKey: .doc_id)
        try container.encode(filename, forKey: .filename)
        try container.encode(chunk_count, forKey: .chunk_count)
        try container.encode(file_size, forKey: .file_size)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        try container.encode(formatter.string(from: uploaded_at), forKey: .uploaded_at)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(file_size), countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: uploaded_at)
    }
}

struct DocumentListResponse: Codable {
    let documents: [DocumentInfo]
    let total: Int
}

struct UploadResponse: Codable {
    let doc_id: String
    let filename: String
    let chunks_created: Int
    let message: String
}

// MARK: - Query Models
struct QueryRequest: Codable {
    let query: String
    let doc_ids: [String]?
    let top_k: Int
    let stream: Bool
    
    init(query: String, doc_ids: [String]? = nil, top_k: Int = 5, stream: Bool = true) {
        self.query = query
        self.doc_ids = doc_ids
        self.top_k = top_k
        self.stream = stream
    }
}

struct QueryChunk: Codable {
    let content: String
    let doc_id: String
    let chunk_id: String
    let score: Double
    let metadata: [String: String]
}

struct QueryResponse: Codable {
    let answer: String
    let chunks: [QueryChunk]
    let query: String
}

// MARK: - Search Models
struct SearchRequest: Codable {
    let query: String
    let doc_ids: [String]?
    let top_k: Int
    
    init(query: String, doc_ids: [String]? = nil, top_k: Int = 10) {
        self.query = query
        self.doc_ids = doc_ids
        self.top_k = top_k
    }
}

struct SearchResult: Codable, Identifiable {
    let content: String
    let doc_id: String
    let chunk_id: String
    let score: Double
    let metadata: [String: String]
    
    var id: String { chunk_id }
}

struct SearchResponse: Codable {
    let results: [SearchResult]
    let query: String
    let total: Int
}

// MARK: - Streaming Models
enum StreamEventType: String, Codable {
    case chunks
    case token
    case done
    case error
}

struct StreamChunk: Codable {
    let type: StreamEventType
    let chunks: [StreamChunkInfo]?
    let content: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case type, chunks, content, error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(StreamEventType.self, forKey: .type)
        chunks = try? container.decodeIfPresent([StreamChunkInfo].self, forKey: .chunks)
        content = try? container.decodeIfPresent(String.self, forKey: .content)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
    }
}

struct StreamChunkInfo: Codable {
    let doc_id: String
    let chunk_id: String
    let score: Double
}

