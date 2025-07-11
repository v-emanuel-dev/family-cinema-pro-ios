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
            .padding(12) // Padding adequado
            .background(Color.surfaceDark)
            .cornerRadius(8) // Menor radius
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primaryColor.opacity(0.3), lineWidth: 1)
            )
            .autocorrectionDisabled() // IMPORTANTE: Desabilitar autocorreção
            .textInputAutocapitalization(.never) // IMPORTANTE: Sem capitalização
    }
}
