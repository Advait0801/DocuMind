//
//  DocuMindApp.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

@main
struct DocuMindApp: App {
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .preferredColorScheme(.light) // Can be changed to .dark or nil for system
        }
    }
}
