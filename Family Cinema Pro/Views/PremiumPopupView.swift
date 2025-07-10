//
//  PremiumPopupView.swift
//  Family Cinema Pro
//
//  Pop-up para acesso premium
//

import SwiftUI

struct PremiumPopupView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.cardBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Botão fechar (posicionado mais embaixo)
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Botão fechar mais embaixo
                
                // Conteúdo principal (mais compacto e subido)
                VStack(spacing: 12) {
                    // Coroa
                    Text("👑")
                        .font(.system(size: 50))
                    
                    // Título
                    Text("ACESSO PREMIUM")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gold)
                    
                    // Subtítulo
                    Text("Desbloqueie todos os FILMES, SÉRIES e TV AO VIVO")
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer().frame(height: 8)
                    
                    // Botões WhatsApp
                    HStack(spacing: 12) {
                        whatsappButton(
                            number: "+55 27 99910-9882",
                            action: { openWhatsApp("5527999109882") }
                        )
                        
                        whatsappButton(
                            number: "+55 27 98891-1261",
                            action: { openWhatsApp("5527988911261") }
                        )
                    }
                    
                    // Botão Telegram
                    telegramButton(
                        number: "+55 27 99509-7169",
                        action: { openTelegram("5527995097169") }
                    )
                }
                .padding(.top, -20) // Subir todo o conteúdo
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - WhatsApp Button
    private func whatsappButton(number: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.white)
                
                Text(number)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.whatsappGreen)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Telegram Button
    private func telegramButton(number: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                
                Text(number)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.telegramBlue)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions
    private func openWhatsApp(_ number: String) {
        let urlString = "https://api.whatsapp.com/send?phone=\(number)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTelegram(_ number: String) {
        let urlString = "https://t.me/\(number)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PremiumPopupView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPopupView()
    }
}
