//
//  Colors.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

extension Color {
    // Primary Colors
    static let dmPrimary = Color(light: "#2952E3", dark: "#4A6EE8")
    static let dmSecondary = Color(light: "#3E3B92", dark: "#5D5AB8")
    static let dmAccent = Color(light: "#8B5CF6", dark: "#A78BFA")
    
    // Background Colors
    static let dmBackground = Color(light: "#F8FAFC", dark: "#0A0F1F")
    static let dmSurface = Color(light: "#FFFFFF", dark: "#1E293B")
    static let dmSurfaceSecondary = Color(light: "#F1F5F9", dark: "#334155")
    
    // Text Colors
    static let dmTextPrimary = Color(light: "#111827", dark: "#F1F5F9")
    static let dmTextSecondary = Color(light: "#475569", dark: "#94A3B8")
    static let dmTextTertiary = Color(light: "#64748B", dark: "#64748B")
    
    // Chart Colors
    static let dmChartBlue = Color(light: "#3B82F6", dark: "#60A5FA")
    static let dmChartPurple = Color(light: "#8B5CF6", dark: "#A78BFA")
    static let dmChartTeal = Color(light: "#14B8A6", dark: "#2DD4BF")
    
    // Semantic Colors
    static let dmError = Color(light: "#EF4444", dark: "#F87171")
    static let dmSuccess = Color(light: "#10B981", dark: "#34D399")
    static let dmWarning = Color(light: "#F59E0B", dark: "#FBBF24")
    static let dmInfo = Color(light: "#3B82F6", dark: "#60A5FA")
    
    // Border Colors
    static let dmBorder = Color(light: "#E2E8F0", dark: "#475569")
    static let dmDivider = Color(light: "#E2E8F0", dark: "#334155")
}

extension Color {
    /// Initialize color from hex string with light/dark mode support
    init(light: String, dark: String) {
        self.init(
            UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(hex: dark) ?? UIColor(hex: light) ?? .systemBackground
                } else {
                    return UIColor(hex: light) ?? .systemBackground
                }
            }
        )
    }
}

extension UIColor {
    /// Initialize UIColor from hex string
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
