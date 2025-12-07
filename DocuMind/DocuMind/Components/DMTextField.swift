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
    var focused: FocusState<Bool>.Binding?
    var errorMessage: String? = nil
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.dmSmallBold)
                .foregroundColor(.dmTextSecondary)
            
            HStack {
                Group {
                    if isSecure && showPassword {
                        // Show password as plain text
                        if let focused = focused {
                            TextField(placeholder, text: $text)
                                .focused(focused)
                        } else {
                            TextField(placeholder, text: $text)
                        }
                    } else if isSecure {
                        // Show password as secure
                        if let focused = focused {
                            SecureField(placeholder, text: $text)
                                .focused(focused)
                        } else {
                            SecureField(placeholder, text: $text)
                        }
                    } else {
                        // Regular text field
                        if let focused = focused {
                            TextField(placeholder, text: $text)
                                .keyboardType(keyboardType)
                                .textInputAutocapitalization(autocapitalization)
                                .focused(focused)
                        } else {
                            TextField(placeholder, text: $text)
                                .keyboardType(keyboardType)
                                .textInputAutocapitalization(autocapitalization)
                        }
                    }
                }
                .font(.dmBody)
                .foregroundColor(.dmTextPrimary)
                
                // Password visibility toggle
                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.dmTextSecondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.dmSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorMessage != nil ? Color.dmError : Color.dmBorder, lineWidth: 1)
            )
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.dmCaption)
                    .foregroundColor(.dmError)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }
}
