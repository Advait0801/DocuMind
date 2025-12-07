//
//  RegisterViewModel.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI
internal import Combine

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Field-specific error messages
    @Published var usernameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
    private let authService = AuthService.shared
    
    func register() async {
        // Clear previous errors
        usernameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        errorMessage = nil
        showError = false
        
        // Validate username
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        if trimmedUsername.isEmpty {
            usernameError = "Username cannot be empty"
            return
        }
        
        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            emailError = "Email cannot be empty"
            return
        }
        
        // Basic email format validation
        if !isValidEmail(trimmedEmail) {
            emailError = "Please enter a valid email address"
            return
        }
        
        // Validate password
        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }
        
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            return
        }
        
        // Validate confirm password
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
            return
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            return
        }
        
        isLoading = true
        
        do {
            try await authService.register(username: trimmedUsername, email: trimmedEmail, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
