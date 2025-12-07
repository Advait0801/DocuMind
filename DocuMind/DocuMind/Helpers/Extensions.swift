//
//  Extensions.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
