//
//  CustomTextFieldStyle.swift
//  Family Cinema Pro
//
//  Estilo customizado para campos de texto
//

import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.white)
            .padding()
            .background(Color.surfaceDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primaryColor.opacity(0.3), lineWidth: 1)
            )
    }
}
