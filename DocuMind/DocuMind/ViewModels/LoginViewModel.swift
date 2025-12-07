//
//  LoginViewModel.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
internal import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var usernameOrEmail = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Field-specific error messages
    @Published var usernameOrEmailError: String?
    @Published var passwordError: String?
    
    private let authService = AuthService.shared
    
    func login() async {
        // Clear previous errors
        usernameOrEmailError = nil
        passwordError = nil
        errorMessage = nil
        showError = false
        
        // Validate username/email
        if usernameOrEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            usernameOrEmailError = "Username or email cannot be empty"
            return
        }
        
        // Validate password
        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }
        
        isLoading = true
        
        do {
            try await authService.login(usernameOrEmail: usernameOrEmail.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}
