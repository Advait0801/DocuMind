//
//  AuthModels.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import Foundation

// MARK: - Request Models
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct LoginRequest: Codable {
    let username_or_email: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refresh_token: String
}

// MARK: - Response Models
struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let token_type: String
}

struct CurrentUser: Codable {
    let id: String
    let username: String
    let email: String
}
