//
//  DocumentDetailView.swift
//  DocuMind
//
//  Created by Advait Naik on 12/6/25.
//

import SwiftUI

struct DocumentDetailView: View {
    let document: DocumentInfo
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ResponsiveContainer {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    DMCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Document Information")
                                .font(.dmH4)
                                .foregroundColor(.dmTextPrimary)
                            
                            DetailRow(label: "Filename", value: document.filename)
                            DetailRow(label: "Size", value: document.formattedSize)
                            DetailRow(label: "Chunks", value: "\(document.chunk_count)")
                            DetailRow(label: "Uploaded", value: document.formattedDate)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, Spacing.lg)
            }
            .background(Color.dmBackground)
            .navigationTitle("Document Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.dmPrimary)
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.dmSmall)
                .foregroundColor(.dmTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.dmSmallBold)
                .foregroundColor(.dmTextPrimary)
        }
    }
}
