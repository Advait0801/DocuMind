//
//  ChatViewModel.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
internal import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentQuery = ""
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedDocIds: [String]?
    
    private let apiService = APIService.shared
    private var currentStreamTask: Task<Void, Never>?
    
    func sendMessage() async {
        guard !currentQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: currentQuery,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let query = currentQuery
        currentQuery = ""
        isLoading = true
        isStreaming = true
        errorMessage = nil
        
        // Cancel any existing stream
        currentStreamTask?.cancel()
        
        currentStreamTask = Task {
            do {
                let stream = apiService.streamQuery(
                    query: query,
                    docIds: selectedDocIds,
                    topK: 5
                )
                
                var assistantMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: "",
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(assistantMessage)
                
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    
                    switch chunk.type {
                    case .chunks:
                        // Handle chunks metadata if needed
                        break
                    case .token:
                        if let content = chunk.content {
                            if let lastIndex = messages.indices.last, messages[lastIndex].id == assistantMessage.id {
                                messages[lastIndex].content += content
                            }
                        }
                    case .done:
                        isLoading = false
                        isStreaming = false
                        return
                    case .error:
                        if let error = chunk.error {
                            errorMessage = error
                            showError = true
                        }
                        isLoading = false
                        isStreaming = false
                        return
                    }
                }
                
                isLoading = false
                isStreaming = false
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    isStreaming = false
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
        currentStreamTask?.cancel()
        isLoading = false
        isStreaming = false
    }
    
    deinit {
        currentStreamTask?.cancel()
    }
}

struct ChatMessage: Identifiable {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
}
