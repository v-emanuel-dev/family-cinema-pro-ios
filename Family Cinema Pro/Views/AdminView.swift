//
//  AdminView.swift
//  Family Cinema Pro
//
//  VERSÃO COMPLETA FINAL
//

import SwiftUI

struct AdminView: View {
    @ObservedObject var configService: ConfigService
    @Environment(\.dismiss) private var dismiss
    
    @State private var localHost = ""
    @State private var localUsername = ""
    @State private var localPassword = ""
    @State private var localAlternativeDns = ""
    @State private var localPort = ""
    @State private var localUpdateInterval = ""
    @State private var localPlaylistFormat = "ts"
    @State private var localAutoReconnect = true
    @State private var localHardwareAcceleration = true
    
    @State private var isTestingConnection = false
    @State private var testResult: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()
            
            adminConfigView
            
            VStack {
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
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
        .onAppear {
            loadLocalValues()
        }
        .alert("Resultado", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var adminConfigView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer().frame(height: 35)
                
                HStack {
                    Text("CONFIGURAÇÕES PRINCIPAIS")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryColor)
                    Spacer()
                }
                .padding(.horizontal)
                
                requiredConfigSection
                advancedConfigSection
                exampleConfigSection
                
                Spacer().frame(height: 20)
            }
        }
        .background(Color.backgroundDark)
    }
    
    private var requiredConfigSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Campos de Configuração")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Host/DNS/M3U *")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Ex: seuservidor.com.br", text: $localHost)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Usuário (opcional)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Ex: 929431775851", text: $localUsername)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Senha (opcional)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    SecureField("Ex: 028531357846", text: $localPassword)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                HStack(spacing: 6) {
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("🔍")
                            }
                            Text("Testar")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isTestingConnection)
                    
                    Button(action: saveConfiguration) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("💾")
                            }
                            Text("Salvar")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSaving)
                }
                
                if let testResult = testResult {
                    Text(testResult)
                        .font(.caption2)
                        .foregroundColor(testResult.contains("✅") ? .successColor : .errorColor)
                        .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private var advancedConfigSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🔧")
                    .font(.headline)
                Text("CONFIGURAÇÕES AVANÇADAS")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlue)
            }
            
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Formato da Playlist:")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    HStack {
                        Button(action: { localPlaylistFormat = "ts" }) {
                            HStack {
                                Image(systemName: localPlaylistFormat == "ts" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.primaryColor)
                                Text("TS")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { localPlaylistFormat = "hls" }) {
                            HStack {
                                Image(systemName: localPlaylistFormat == "hls" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.primaryColor)
                                Text("HLS")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DNS Alternativo")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("Ex: servidor2.com.br", text: $localAlternativeDns)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Porta")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("Padrão: 80", text: $localPort)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intervalo (min)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("30", text: $localUpdateInterval)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Reconexão Automática", isOn: $localAutoReconnect)
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Toggle("Aceleração por Hardware", isOn: $localHardwareAcceleration)
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                HStack(spacing: 6) {
                    Button(action: exportConfiguration) {
                        Text("📤")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: clearCache) {
                        Text("🗑️")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private var exampleConfigSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("💡")
                    .font(.headline)
                Text("EXEMPLOS DE CONFIGURAÇÃO")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.successColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("1️⃣ M3U Direto (sem usuário/senha):")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.accentBlue)
                    
                    Text("Host: http://exemplo.com/playlist.m3u8")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.backgroundDark)
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("2️⃣ IPTV com credenciais:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.accentBlue)
                    
                    Text("""
                    Host: seuservidor.com.br
                    User: 123456 | Pass: 123456
                    """)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.backgroundDark)
                        .cornerRadius(6)
                }
                
                Text("URL Atual: \(generateExampleURL())")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color.successColor.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Methods
    private func loadLocalValues() {
        localHost = configService.config.hostDns
        localUsername = configService.config.username
        localPassword = configService.config.password
        localAlternativeDns = configService.config.alternativeDns
        localPort = configService.config.port
        localUpdateInterval = configService.config.updateInterval
        localPlaylistFormat = configService.config.playlistFormat
        localAutoReconnect = configService.config.autoReconnect
        localHardwareAcceleration = configService.config.hardwareAcceleration
    }
    
    private func saveLocalValues() {
        configService.config.hostDns = localHost
        configService.config.username = localUsername
        configService.config.password = localPassword
        configService.config.alternativeDns = localAlternativeDns
        configService.config.port = localPort
        configService.config.updateInterval = localUpdateInterval
        configService.config.playlistFormat = localPlaylistFormat
        configService.config.autoReconnect = localAutoReconnect
        configService.config.hardwareAcceleration = localHardwareAcceleration
    }
    
    private func testConnection() {
        guard !localHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "❌ O campo Host/DNS é obrigatório"
            showingAlert = true
            return
        }
        
        isTestingConnection = true
        testResult = nil
        saveLocalValues()
        
        Task {
            let success = await configService.testConnection()
            
            await MainActor.run {
                isTestingConnection = false
                
                if success {
                    testResult = "✅ Conexão bem-sucedida!"
                } else {
                    testResult = "❌ Falha na conexão: \(configService.lastError ?? "Erro desconhecido")"
                }
            }
        }
    }
    
    private func saveConfiguration() {
        guard !localHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "❌ O campo Host/DNS é obrigatório"
            showingAlert = true
            return
        }
        
        isSaving = true
        
        print("🔧 [DEBUG] ===== INICIANDO SALVAMENTO =====")
        print("🔧 [DEBUG] Host: \(localHost)")
        print("🔧 [DEBUG] User: \(localUsername)")
        
        saveLocalValues()
        configService.generatePlaylistURL()
        configService.saveConfiguration()
        
        isSaving = false
        alertMessage = "✅ Configuração salva com sucesso!\n🔄 A lista de canais será atualizada automaticamente."
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func exportConfiguration() {
        saveLocalValues()
        
        let config = """
        Configuração Epic Cinema Pro
        ===========================
        Host/DNS: \(localHost)
        Usuário: \(localUsername)
        Formato: \(localPlaylistFormat)
        Porta: \(localPort)
        URL Playlist: \(configService.config.playlistUrl)
        Data: \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))
        """
        
        UIPasteboard.general.string = config
        
        alertMessage = "💾 Configurações exportadas!\n📋 Dados copiados para o clipboard"
        showingAlert = true
    }
    
    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        
        alertMessage = "🗑️ Cache limpo com sucesso!\n📱 Espaço liberado"
        showingAlert = true
    }
    
    private func generateExampleURL() -> String {
        if localHost.isEmpty {
            return "Configure o Host/DNS para ver a URL"
        }
        
        let isDirectM3U = localHost.contains(".m3u") || localHost.contains("playlist") ||
                         localUsername.isEmpty || localPassword.isEmpty
        
        if isDirectM3U {
            return localHost
        } else {
            let baseUrl = localHost.hasPrefix("http") ? localHost : "http://\(localHost)"
            return "\(baseUrl)/get.php?username=\(localUsername)&password=\(localPassword)&type=m3u_plus&output=\(localPlaylistFormat)"
        }
    }
}

#if DEBUG
struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView(configService: ConfigService())
    }
}
#endif
