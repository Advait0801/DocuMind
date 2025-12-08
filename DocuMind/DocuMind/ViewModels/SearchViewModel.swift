//
//  SearchViewModel.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
internal import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedDocIds: [String] = []
    @Published var topK: Int = 10
    @Published var documents: [DocumentInfo] = []
    @Published var isLoadingDocuments = false
    
    private let apiService = APIService.shared
    
    func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.searchDocuments(
                query: searchQuery,
                docIds: selectedDocIds.isEmpty ? nil : selectedDocIds,
                topK: topK
            )
            searchResults = response.results
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            searchResults = []
        }
        
        isLoading = false
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
    
    func loadDocuments() async {
        guard !isLoadingDocuments else { return }
        isLoadingDocuments = true
        do {
            let response = try await apiService.getDocuments()
            documents = response.documents
        } catch {
            // Non-fatal: search can still work without document filter list
        }
        isLoadingDocuments = false
    }
    
    func toggleSelection(for docId: String) {
        if let index = selectedDocIds.firstIndex(of: docId) {
            selectedDocIds.remove(at: index)
        } else {
            selectedDocIds.append(docId)
        }
    }
    
    func clearFilters() {
        selectedDocIds = []
        topK = 10
    }
    
    func documentName(for docId: String) -> String {
        documents.first(where: { $0.doc_id == docId })?.filename ?? docId
    }
}
