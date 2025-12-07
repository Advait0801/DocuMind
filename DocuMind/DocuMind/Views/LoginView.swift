//
//  LoginView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showRegister = false
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ResponsiveContainer {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Logo/Title
                VStack(spacing: Spacing.sm) {
                    Text("DocuMind")
                        .font(.dmH1)
                        .foregroundColor(.dmPrimary)
                    
                    Text("Your AI Knowledge Assistant")
                        .font(.dmBody)
                        .foregroundColor(.dmTextSecondary)
                }
                .padding(.bottom, Spacing.xxl)
                
                // Login Form
                VStack(spacing: Spacing.lg) {
                    DMTextField(
                        title: "Username or Email",
                        placeholder: "Enter username or email",
                        text: $viewModel.usernameOrEmail,
                        keyboardType: .emailAddress,
                        focused: $isFieldFocused,
                        errorMessage: viewModel.usernameOrEmailError
                    )
                    
                    DMTextField(
                        title: "Password",
                        placeholder: "Enter password",
                        text: $viewModel.password,
                        isSecure: true,
                        focused: $isFieldFocused,
                        errorMessage: viewModel.passwordError
                    )
                    
                    DMButton(title: "Login", style: .primary) {
                        isFieldFocused = false
                        hideKeyboard()
                        Task {
                            await viewModel.login()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                
                // Register Link
                HStack {
                    Text("Don't have an account?")
                        .font(.dmBody)
                        .foregroundColor(.dmTextSecondary)
                    
                    Button("Register") {
                        showRegister = true
                    }
                    .font(.dmBodyBold)
                    .foregroundColor(.dmPrimary)
                }
                
                Spacer()
            }
            .padding(.vertical, Spacing.xl)
        }
        .background(Color.dmBackground)
        .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage ?? "An error occurred")
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
        }
    }
}
