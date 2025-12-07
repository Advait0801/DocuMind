//
//  MainTabView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        TabView {
            DocumentListView()
                .tabItem {
                    Label("Documents", systemImage: "doc.on.doc")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
        .accentColor(.dmPrimary)
    }
}
