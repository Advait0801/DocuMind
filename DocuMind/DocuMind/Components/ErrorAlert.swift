//
//  ErrorAlert.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct ErrorAlert: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented) {
                Button("OK", role: .cancel, action: {
                    action?()
                })
            } message: {
                Text(message)
            }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, message: String, action: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(isPresented: isPresented, message: message, action: action))
    }
}
