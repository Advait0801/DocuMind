//
//  AuthService.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import Foundation
internal import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: CurrentUser?
    
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let userKey = "current_user"
    
    var accessToken: String? {
        UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    var refreshToken: String? {
        UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    private init() {
        // Check if user is already authenticated
        if accessToken != nil {
            loadUser()
            isAuthenticated = true
        }
    }
    
    // MARK: - Authentication Methods
    func register(username: String, email: String, password: String) async throws {
        let request = RegisterRequest(username: username, email: email, password: password)
        let response: TokenResponse = try await NetworkService.shared.request(
            endpoint: "/auth/register",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        saveTokens(accessToken: response.access_token, refreshToken: response.refresh_token)
        isAuthenticated = true
    }
    
    func login(usernameOrEmail: String, password: String) async throws {
        let request = LoginRequest(username_or_email: usernameOrEmail, password: password)
        let response: TokenResponse = try await NetworkService.shared.request(
            endpoint: "/auth/login",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        saveTokens(accessToken: response.access_token, refreshToken: response.refresh_token)
        isAuthenticated = true
    }
    
    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw APIError.unauthorized
        }
        
        let request = RefreshTokenRequest(refresh_token: refreshToken)
        let response: TokenResponse = try await NetworkService.shared.request(
            endpoint: "/auth/refresh",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        saveTokens(accessToken: response.access_token, refreshToken: response.refresh_token)
    }
    
    func logout() async {
        guard let refreshToken = refreshToken else {
            clearSession()
            return
        }
        
        let request = RefreshTokenRequest(refresh_token: refreshToken)
        
        // Best-effort revoke on the backend; still clear local session
        _ = try? await NetworkService.shared.request(
            endpoint: "/auth/logout",
            method: .post,
            body: request,
            requiresAuth: true
        ) as EmptyResponse
        
        clearSession()
    }
    
    // MARK: - Token Management
    private func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
    }
    
    private func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(CurrentUser.self, from: userData) {
            currentUser = user
        }
    }
    
    func setCurrentUser(_ user: CurrentUser) {
        currentUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        isAuthenticated = false
        currentUser = nil
    }
}
