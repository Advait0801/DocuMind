//
//  RegisterView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: Spacing.xl) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.dmBody)
                    .foregroundColor(.dmPrimary)
                    
                    Spacer()
                    
                    Text("Create Account")
                        .font(.dmH3)
                        .foregroundColor(.dmTextPrimary)
                    
                    Spacer()
                    
                    // Balance for Cancel button
                    Text("Cancel")
                        .font(.dmBody)
                        .foregroundColor(.clear)
                }
                .padding(.top, Spacing.lg)
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        DMTextField(
                            title: "Username",
                            placeholder: "Enter username",
                            text: $viewModel.username,
                            focused: $isFieldFocused,
                            errorMessage: viewModel.usernameError
                        )
                        
                        DMTextField(
                            title: "Email",
                            placeholder: "Enter email",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            focused: $isFieldFocused,
                            errorMessage: viewModel.emailError
                        )
                        
                        DMTextField(
                            title: "Password",
                            placeholder: "Enter password",
                            text: $viewModel.password,
                            isSecure: true,
                            focused: $isFieldFocused,
                            errorMessage: viewModel.passwordError
                        )
                        
                        DMTextField(
                            title: "Confirm Password",
                            placeholder: "Confirm password",
                            text: $viewModel.confirmPassword,
                            isSecure: true,
                            focused: $isFieldFocused,
                            errorMessage: viewModel.confirmPasswordError
                        )
                        
                        DMButton(title: "Register", style: .primary) {
                            isFieldFocused = false
                            hideKeyboard()
                            Task {
                                await viewModel.register()
                                if !viewModel.showError {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(viewModel.isLoading)
                        
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                    .padding(.top, Spacing.xl)
                }
            }
        }
        .background(Color.dmBackground)
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage ?? "An error occurred")
    }
}
