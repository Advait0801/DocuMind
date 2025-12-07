//
//  DocumentListView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct DocumentListView: View {
    @StateObject private var viewModel = DocumentListViewModel()
    @State private var showUpload = false
    @State private var selectedDocument: DocumentInfo?
    
    var body: some View {
        NavigationView {
            ResponsiveContainer {
                VStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.documents.isEmpty {
                        LoadingView()
                    } else if viewModel.documents.isEmpty {
                        EmptyDocumentsView(showUpload: $showUpload)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Spacing.md) {
                                ForEach(viewModel.documents) { document in
                                    DocumentCard(document: document) {
                                        selectedDocument = document
                                    } onDelete: {
                                        Task {
                                            await viewModel.deleteDocument(document)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.md)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .background(Color.dmBackground)
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showUpload = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.dmPrimary)
                    }
                }
            }
            .sheet(isPresented: $showUpload) {
                UploadView()
            }
            .sheet(item: $selectedDocument) { document in
                DocumentDetailView(document: document)
            }
            .task {
                await viewModel.loadDocuments()
            }
            .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct DocumentCard: View {
    let document: DocumentInfo
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        DMCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(document.filename)
                            .font(.dmBodyBold)
                            .foregroundColor(.dmTextPrimary)
                            .lineLimit(2)
                        
                        Text(document.formattedDate)
                            .font(.dmCaption)
                            .foregroundColor(.dmTextTertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.dmError)
                    }
                }
                
                HStack {
                    Label(document.formattedSize, systemImage: "doc.fill")
                        .font(.dmSmall)
                        .foregroundColor(.dmTextSecondary)
                    
                    Spacer()
                    
                    Label("\(document.chunk_count) chunks", systemImage: "square.stack.3d.up")
                        .font(.dmSmall)
                        .foregroundColor(.dmTextSecondary)
                }
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct EmptyDocumentsView: View {
    @Binding var showUpload: Bool
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.dmTextTertiary)
            
            Text("No Documents")
                .font(.dmH3)
                .foregroundColor(.dmTextPrimary)
            
            Text("Upload your first PDF to get started")
                .font(.dmBody)
                .foregroundColor(.dmTextSecondary)
                .multilineTextAlignment(.center)
            
            DMButton(title: "Upload Document", style: .primary) {
                showUpload = true
            }
            .frame(maxWidth: 200)
        }
        .padding(Spacing.xl)
    }
}
