//
//  DMTextField.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct DMTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var focused: Binding<Bool>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.dmSmallBold)
                .foregroundColor(.dmTextSecondary)
            
            Group {
                if isSecure {
                    if let focused = focused {
                        SecureField(placeholder, text: $text)
                            .focused(focused)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                } else {
                    if let focused = focused {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(autocapitalization)
                            .focused(focused)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(autocapitalization)
                    }
                }
            }
            .font(.dmBody)
            .foregroundColor(.dmTextPrimary)
            .padding(Spacing.md)
            .background(Color.dmSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dmBorder, lineWidth: 1)
            )
        }
    }
}
