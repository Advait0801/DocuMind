//
//  SearchView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.dmTextSecondary)
                    
                    TextField("Search documents...", text: $viewModel.searchQuery)
                        .font(.dmBody)
                        .foregroundColor(.dmTextPrimary)
                        .focused($isSearchFocused)
                        .onSubmit {
                            isSearchFocused = false
                            hideKeyboard()
                            Task {
                                await viewModel.performSearch()
                            }
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            isSearchFocused = false
                            hideKeyboard()
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.dmTextTertiary)
                        }
                    }
                    
                    Button {
                        isSearchFocused = false
                        hideKeyboard()
                        Task {
                            await viewModel.performSearch()
                        }
                    } label: {
                        Text("Search")
                            .font(.dmSmallBold)
                            .foregroundColor(.dmPrimary)
                    }
                    .disabled(viewModel.searchQuery.isEmpty || viewModel.isLoading)
                }
                .padding(Spacing.md)
                .background(Color.dmSurface)
                .cornerRadius(12)
                .padding(Spacing.md)
                
                filterBar
                
                Divider()
                    .background(Color.dmDivider)
                
                // Results
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    EmptySearchView()
                } else if viewModel.searchResults.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(viewModel.searchResults) { result in
                                SearchResultCard(
                                    result: result,
                                    docName: viewModel.documentName(for: result.doc_id)
                                )
                            }
                        }
                        .padding(Spacing.md)
                    }
                }
            }
            .background(Color.dmBackground)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    isPresented: $showFilters,
                    documents: viewModel.documents,
                    selectedDocIds: $viewModel.selectedDocIds,
                    topK: $viewModel.topK,
                    onClear: viewModel.clearFilters
                )
            }
            .task {
                await viewModel.loadDocuments()
            }
        }
    }
    
    private var filterBar: some View {
        HStack {
            Button {
                showFilters = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.dmPrimary)
                    Text("Filters")
                        .font(.dmSmallBold)
                        .foregroundColor(.dmPrimary)
                    if !viewModel.selectedDocIds.isEmpty || viewModel.topK != 10 {
                        Text("\(activeFiltersLabel)")
                            .font(.dmSmall)
                            .foregroundColor(.dmTextSecondary)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 4)
                            .background(Color.dmSurfaceSecondary)
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            if !viewModel.selectedDocIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(viewModel.selectedDocIds, id: \.self) { docId in
                            let name = viewModel.documentName(for: docId)
                            HStack(spacing: Spacing.xs) {
                                Text(name)
                                    .font(.dmSmall)
                                    .foregroundColor(.dmTextPrimary)
                                    .lineLimit(1)
                                Button {
                                    viewModel.toggleSelection(for: docId)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.dmTextTertiary)
                                }
                            }
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 6)
                            .background(Color.dmSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.dmBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .frame(height: 36)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }
    
    private var activeFiltersLabel: String {
        var parts: [String] = []
        if !viewModel.selectedDocIds.isEmpty {
            parts.append("\(viewModel.selectedDocIds.count) docs")
        }
        if viewModel.topK != 10 {
            parts.append("top \(viewModel.topK)")
        }
        return parts.joined(separator: " • ")
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    let docName: String
    
    var body: some View {
        DMCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(docName)
                            .font(.dmCaptionBold)
                            .foregroundColor(.dmTextPrimary)
                            .lineLimit(1)
                        
                        Text("Score: \(String(format: "%.2f", result.score))")
                            .font(.dmCaption)
                            .foregroundColor(.dmAccent)
                    }
                    
                    Spacer()
                    
                    Text("#\(result.chunk_id.prefix(6))")
                        .font(.dmCaption)
                        .foregroundColor(.dmTextTertiary)
                }
                
                Text(result.content)
                    .font(.dmBody)
                    .foregroundColor(.dmTextPrimary)
                    .lineLimit(3)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.dmTextTertiary)
            
            Text("Search Your Documents")
                .font(.dmH3)
                .foregroundColor(.dmTextPrimary)
            
            Text("Enter a query to search through your uploaded documents")
                .font(.dmBody)
                .foregroundColor(.dmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.dmTextTertiary)
            
            Text("No Results")
                .font(.dmH3)
                .foregroundColor(.dmTextPrimary)
            
            Text("Try a different search query")
                .font(.dmBody)
                .foregroundColor(.dmTextSecondary)
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Filter Sheet
private struct FilterSheet: View {
    @Binding var isPresented: Bool
    let documents: [DocumentInfo]
    @Binding var selectedDocIds: [String]
    @Binding var topK: Int
    let onClear: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section("Documents") {
                        if documents.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Loading documents...")
                                    .foregroundColor(.dmTextSecondary)
                                    .font(.dmBody)
                            }
                        } else {
                            ForEach(documents) { doc in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.filename)
                                            .foregroundColor(.dmTextPrimary)
                                        Text(doc.formattedDate)
                                            .font(.dmCaption)
                                            .foregroundColor(.dmTextTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedDocIds.contains(doc.doc_id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedDocIds.contains(doc.doc_id) ? .dmPrimary : .dmBorder)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggle(doc.doc_id)
                                }
                            }
                        }
                    }
                    
                    Section("Results per query") {
                        Stepper(value: $topK, in: 3...25, step: 1) {
                            Text("Top \(topK) results")
                                .foregroundColor(.dmTextPrimary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .background(Color.dmBackground)
                
                HStack {
                    Button("Clear") {
                        onClear()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.dmSurfaceSecondary)
                    .foregroundColor(.dmTextPrimary)
                    .cornerRadius(12)
                    
                    Button("Apply") {
                        isPresented = false
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.dmPrimary)
                    .foregroundColor(.dmSurface)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                        .foregroundColor(.dmTextPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func toggle(_ docId: String) {
        if let index = selectedDocIds.firstIndex(of: docId) {
            selectedDocIds.remove(at: index)
        } else {
            selectedDocIds.append(docId)
        }
    }
}
