//
//  Typography.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

extension Font {
    // Headings
    static let dmH1 = Font.system(size: 32, weight: .bold, design: .default)
    static let dmH2 = Font.system(size: 24, weight: .semibold, design: .default)
    static let dmH3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let dmH4 = Font.system(size: 18, weight: .medium, design: .default)
    
    // Body
    static let dmBody = Font.system(size: 16, weight: .regular, design: .default)
    static let dmBodyBold = Font.system(size: 16, weight: .semibold, design: .default)
    static let dmBodyLarge = Font.system(size: 18, weight: .regular, design: .default)
    
    // Small
    static let dmSmall = Font.system(size: 14, weight: .regular, design: .default)
    static let dmSmallBold = Font.system(size: 14, weight: .semibold, design: .default)
    
    // Caption
    static let dmCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let dmCaptionBold = Font.system(size: 12, weight: .semibold, design: .default)
}

extension Text {
    func dmStyle(_ style: TextStyle) -> some View {
        self.font(style.font)
            .foregroundColor(style.color)
    }
}

enum TextStyle {
    case h1, h2, h3, h4
    case body, bodyBold, bodyLarge
    case small, smallBold
    case caption, captionBold
    case primary, secondary, tertiary
    
    var font: Font {
        switch self {
        case .h1: return .dmH1
        case .h2: return .dmH2
        case .h3: return .dmH3
        case .h4: return .dmH4
        case .body, .primary: return .dmBody
        case .bodyBold: return .dmBodyBold
        case .bodyLarge: return .dmBodyLarge
        case .small, .secondary: return .dmSmall
        case .smallBold: return .dmSmallBold
        case .caption, .tertiary: return .dmCaption
        case .captionBold: return .dmCaptionBold
        }
    }
    
    var color: Color {
        switch self {
        case .h1, .h2, .h3, .h4, .body, .bodyBold, .bodyLarge, .primary:
            return .dmTextPrimary
        case .small, .smallBold, .secondary:
            return .dmTextSecondary
        case .caption, .captionBold, .tertiary:
            return .dmTextTertiary
        }
    }
}
