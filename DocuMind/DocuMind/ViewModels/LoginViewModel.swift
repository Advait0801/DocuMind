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
    
    private let authService = AuthService.shared
    
    func login() async {
        guard !usernameOrEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.login(usernameOrEmail: usernameOrEmail, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}
