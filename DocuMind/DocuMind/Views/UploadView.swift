//
//  UploadView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationView {
            ResponsiveContainer {
                VStack(spacing: Spacing.xl) {
                    if viewModel.isUploading {
                        VStack(spacing: Spacing.lg) {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("Uploading...")
                                .font(.dmBody)
                                .foregroundColor(.dmTextSecondary)
                        }
                        .padding(Spacing.xl)
                    } else if viewModel.uploadedDocument != nil {
                        VStack(spacing: Spacing.lg) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.dmSuccess)
                            
                            Text("Upload Successful!")
                                .font(.dmH3)
                                .foregroundColor(.dmTextPrimary)
                            
                            if let document = viewModel.uploadedDocument {
                                Text(document.filename)
                                    .font(.dmBody)
                                    .foregroundColor(.dmTextSecondary)
                            }
                            
                            DMButton(title: "Done", style: .primary) {
                                dismiss()
                            }
                            .frame(maxWidth: 200)
                        }
                        .padding(Spacing.xl)
                    } else {
                        VStack(spacing: Spacing.xl) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 64))
                                .foregroundColor(.dmPrimary)
                            
                            Text("Upload PDF Document")
                                .font(.dmH3)
                                .foregroundColor(.dmTextPrimary)
                            
                            Text("Select a PDF file to upload and process")
                                .font(.dmBody)
                                .foregroundColor(.dmTextSecondary)
                                .multilineTextAlignment(.center)
                            
                            DMButton(title: "Choose File", style: .primary) {
                                showFilePicker = true
                            }
                            .frame(maxWidth: 200)
                        }
                        .padding(Spacing.xl)
                    }
                }
            }
            .background(Color.dmBackground)
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dmPrimary)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        let fileName = url.lastPathComponent
                        Task {
                            await viewModel.uploadDocument(fileURL: url, fileName: fileName)
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            }
            .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage ?? "An error occurred")
        }
    }
}
