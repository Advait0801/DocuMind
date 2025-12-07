//
//  UploadViewModel.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
internal import Combine

@MainActor
class UploadViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var uploadedDocument: DocumentInfo?
    
    private let apiService = APIService.shared
    
    func uploadDocument(fileURL: URL, fileName: String) async {
        isUploading = true
        uploadProgress = 0
        errorMessage = nil
        uploadedDocument = nil
        
        do {
            let response = try await apiService.uploadDocument(fileURL: fileURL, fileName: fileName)
            
            // Fetch the full document info
            let document = try await apiService.getDocument(docId: response.doc_id)
            uploadedDocument = document
            uploadProgress = 1.0
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isUploading = false
    }
}
