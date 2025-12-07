//
//  ChatView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isStreaming {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.dmSmall)
                                        .foregroundColor(.dmTextSecondary)
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                        .padding(Spacing.md)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.dmDivider)
                
                // Input Area
                HStack(spacing: Spacing.sm) {
                    TextField("Ask a question...", text: $viewModel.currentQuery, axis: .vertical)
                        .font(.dmBody)
                        .foregroundColor(.dmTextPrimary)
                        .padding(Spacing.md)
                        .background(Color.dmSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dmBorder, lineWidth: 1)
                        )
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .disabled(viewModel.isLoading || viewModel.isStreaming)
                        .onSubmit {
                            isInputFocused = false
                            hideKeyboard()
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                    
                    Button {
                        isInputFocused = false
                        hideKeyboard()
                        Task {
                            await viewModel.sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.currentQuery.isEmpty ? .dmTextTertiary : .dmPrimary)
                    }
                    .disabled(viewModel.currentQuery.isEmpty || viewModel.isLoading || viewModel.isStreaming)
                }
                .padding(Spacing.md)
                .background(Color.dmBackground)
            }
            .background(Color.dmBackground)
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.clearChat()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.dmError)
                    }
                }
            }
            .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: Spacing.xs) {
                Text(message.content)
                    .font(.dmBody)
                    .foregroundColor(message.isUser ? .white : .dmTextPrimary)
                    .padding(Spacing.md)
                    .background(message.isUser ? Color.dmPrimary : Color.dmSurface)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.dmCaption)
                    .foregroundColor(.dmTextTertiary)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}
