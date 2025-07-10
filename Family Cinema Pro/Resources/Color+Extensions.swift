//
//  Color+Extensions.swift
//  Family Cinema Pro
//
//  Cores personalizadas do app
//

import SwiftUI

extension Color {
    // MARK: - Cores Principais
    static let primaryColor = Color(hex: "#FF6B35")
    static let backgroundDark = Color(hex: "#0D1117")
    static let surfaceDark = Color(hex: "#161B22")
    static let cardBackground = Color(hex: "#21262D")
    
    // MARK: - Cores de Texto
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8B949E")
    
    // MARK: - Cores Funcionais
    static let successColor = Color(hex: "#238636")
    static let errorColor = Color(hex: "#F85149")
    static let warningColor = Color(hex: "#F79009")
    static let accentBlue = Color(hex: "#58A6FF")
    static let accentPurple = Color(hex: "#BC8CFF")
    static let gold = Color(hex: "#FFD700")
    
    // MARK: - Cores Específicas
    static let whatsappGreen = Color(hex: "#25D366")
    static let telegramBlue = Color(hex: "#229ED9")
    
    // MARK: - Construtor de cores hex
    init(hex: String) {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Estilos de Botão
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .background(Color.primaryColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.textPrimary)
            .font(.headline)
            .padding()
            .background(Color.surfaceDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primaryColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Estilos de Card
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
