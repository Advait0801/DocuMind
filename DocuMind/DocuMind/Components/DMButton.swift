//
//  DMButton.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct DMButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case accent
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .dmPrimary
            case .secondary: return .dmSecondary
            case .accent: return .dmAccent
            case .destructive: return .dmError
            }
        }
        
        var foregroundColor: Color {
            return .white
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.dmBodyBold)
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(style.backgroundColor)
                .cornerRadius(12)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
