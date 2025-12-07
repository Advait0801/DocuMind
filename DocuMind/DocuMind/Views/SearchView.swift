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
                                SearchResultCard(result: result)
                            }
                        }
                        .padding(Spacing.md)
                    }
                }
            }
            .background(Color.dmBackground)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    
    var body: some View {
        DMCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Score: \(String(format: "%.2f", result.score))")
                        .font(.dmCaptionBold)
                        .foregroundColor(.dmAccent)
                    
                    Spacer()
                    
                    Text(result.doc_id)
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
