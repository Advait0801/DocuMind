//
//  APIService.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import Foundation

@MainActor
class APIService {
    static let shared = APIService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Document Methods
    func getDocuments() async throws -> DocumentListResponse {
        try await networkService.request(endpoint: "/documents", method: .get)
    }
    
    func getDocument(docId: String) async throws -> DocumentInfo {
        try await networkService.request(endpoint: "/documents/\(docId)", method: .get)
    }
    
    func deleteDocument(docId: String) async throws {
        let _: EmptyResponse = try await networkService.request(
            endpoint: "/documents/\(docId)",
            method: .delete
        )
    }
    
    func uploadDocument(fileURL: URL, fileName: String) async throws -> UploadResponse {
        try await networkService.upload(
            endpoint: "/upload",
            fileURL: fileURL,
            fileName: fileName
        )
    }
    
    // MARK: - Query Methods
    func queryDocuments(
        query: String,
        docIds: [String]? = nil,
        topK: Int = 5,
        stream: Bool = false
    ) async throws -> QueryResponse {
        let request = QueryRequest(query: query, doc_ids: docIds, top_k: topK, stream: stream)
        return try await networkService.request(
            endpoint: "/query",
            method: .post,
            body: request
        )
    }
    
    func streamQuery(
        query: String,
        docIds: [String]? = nil,
        topK: Int = 5
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        let request = QueryRequest(query: query, doc_ids: docIds, top_k: topK, stream: true)
        return networkService.streamQuery(request: request)
    }
    
    // MARK: - Search Methods
    func searchDocuments(
        query: String,
        docIds: [String]? = nil,
        topK: Int = 10
    ) async throws -> SearchResponse {
        let request = SearchRequest(query: query, doc_ids: docIds, top_k: topK)
        return try await networkService.request(
            endpoint: "/search",
            method: .post,
            body: request
        )
    }
}
