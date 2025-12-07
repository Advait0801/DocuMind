//
//  ResponsiveContent.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct ResponsiveContainer<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    content
                        .frame(maxWidth: maxContentWidth(for: geometry.size.width))
                    Spacer()
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }
    
    private func maxContentWidth(for screenWidth: CGFloat) -> CGFloat {
        if horizontalSizeClass == .regular {
            // iPad or large iPhone in landscape
            return min(800, screenWidth * 0.8)
        } else {
            // iPhone
            return screenWidth
        }
    }
    
    private var horizontalPadding: CGFloat {
        if horizontalSizeClass == .regular {
            return Spacing.xl
        } else {
            return Spacing.screenPadding
        }
    }
}
