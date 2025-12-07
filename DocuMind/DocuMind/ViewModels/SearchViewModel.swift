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
    @Published var selectedDocIds: [String]?
    
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
                docIds: selectedDocIds,
                topK: 10
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
}
