//
//  DocumentListViewModel.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
internal import Combine

@MainActor
class DocumentListViewModel: ObservableObject {
    @Published var documents: [DocumentInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let apiService = APIService.shared
    
    func loadDocuments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getDocuments()
            documents = response.documents
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func deleteDocument(_ document: DocumentInfo) async {
        do {
            try await apiService.deleteDocument(docId: document.doc_id)
            await loadDocuments()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func refresh() async {
        await loadDocuments()
    }
}
