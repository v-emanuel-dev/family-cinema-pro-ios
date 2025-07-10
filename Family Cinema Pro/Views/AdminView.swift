//
//  AdminView.swift
//  Family Cinema Pro
//
//  Tela de configurações administrativas
//

import SwiftUI

struct AdminView: View {
    // MARK: - Properties
    @ObservedObject var configService: ConfigService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Variables
    @State private var showingAuthSheet = true
    @State private var isAuthenticated = false
    @State private var username = ""
    @State private var password = ""
    @State private var isTestingConnection = false
    @State private var testResult: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // MARK: - Admin Credentials
    private let adminUsername = "admin"
    private let adminPassword = "admin"
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundDark
                .ignoresSafeArea()
            
            // Conteúdo principal (SEM VStack que cria espaço)
            Group {
                if isAuthenticated {
                    adminConfigView
                } else {
                    authenticationView
                }
            }
            
            // Botão fechar sobreposto (posição absoluta)
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
                Spacer() // Manter botão no topo
            }
        }
        .alert("Resultado", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Authentication View (MUITO SUBIDA)
    private var authenticationView: some View {
        ScrollView {
            VStack(spacing: 8) { // Spacing mínimo
                // Spacer pequeno para botão fechar
                Spacer().frame(height: 35) // REDUZIDO de 120 para 80
                
                // Logo e título (compactos)
                VStack(spacing: 6) { // REDUZIDO de 8 para 6
                    Text("ACESSO ADMINISTRATIVO")
                        .font(.title3) // REDUZIDO de .title2
                        .fontWeight(.bold)
                        .foregroundColor(.primaryColor)
                    
                    Text("Área restrita para administradores")
                        .font(.caption) // REDUZIDO de .subheadline
                        .foregroundColor(.textSecondary)
                }
                
                // Formulário de login (compacto)
                VStack(spacing: 12) { // REDUZIDO de 16 para 12
                    VStack(alignment: .leading, spacing: 6) { // REDUZIDO de 8 para 6
                        Text("CREDENCIAIS DE ACESSO")
                            .font(.caption2) // REDUZIDO
                            .fontWeight(.bold)
                            .foregroundColor(.primaryColor)
                        
                        TextField("Usuário Administrador", text: $username)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        SecureField("Senha de Administrador", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    Button(action: authenticateUser) {
                        Text("ACESSAR ADMINISTRAÇÃO")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(18) // REDUZIDO de 24 para 18
                .modifier(CardBackground())
                .padding(.horizontal)
                
                Spacer() // Espaço restante
            }
        }
        .background(Color.backgroundDark)
    }
    
    // MARK: - Admin Configuration View (OTIMIZADA)
    private var adminConfigView: some View {
        ScrollView {
            VStack(spacing: 16) { // Espaçamento reduzido
                // Spacer mínimo para o botão fechar
                Spacer().frame(height: 35) // REDUZIDO de 100 para 80
                
                // Título (compacto)
                HStack {
                    Text("CONFIGURAÇÕES PRINCIPAIS")
                        .font(.headline) // REDUZIDO de .title3
                        .fontWeight(.bold)
                        .foregroundColor(.primaryColor)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Configurações obrigatórias
                requiredConfigSection
                
                // Configurações avançadas
                advancedConfigSection
                
                // Exemplo de configuração
                exampleConfigSection
                
                // Spacer final mínimo
                Spacer().frame(height: 20)
            }
        }
        .background(Color.backgroundDark)
    }
    
    // MARK: - Required Config Section (SUPER COMPACTA)
    private var requiredConfigSection: some View {
        VStack(alignment: .leading, spacing: 8) { // REDUZIDO de 12 para 8
            Text("Campos Obrigatórios *")
                .font(.subheadline) // REDUZIDO de .headline
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) { // REDUZIDO de 10 para 8
                VStack(alignment: .leading, spacing: 2) {
                    Text("Host/DNS *")
                        .font(.caption) // REDUZIDO de .subheadline
                        .foregroundColor(.textSecondary)
                    TextField("Ex: seuservidor.com.br", text: $configService.config.hostDns)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Usuário *")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("Ex: 929431775851", text: $configService.config.username)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Senha *")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    SecureField("Ex: 028531357846", text: $configService.config.password)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                HStack(spacing: 6) { // REDUZIDO de 8 para 6
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
                        Text("💾 Salvar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // Resultado do teste
                if let testResult = testResult {
                    Text(testResult)
                        .font(.caption2) // REDUZIDO
                        .foregroundColor(testResult.contains("✅") ? .successColor : .errorColor)
                        .padding(.top, 2)
                }
            }
        }
        .padding(12) // REDUZIDO de 16 para 12
        .modifier(CardBackground())
        .padding(.horizontal)
    }
    
    // MARK: - Advanced Config Section (SUPER COMPACTA)
    private var advancedConfigSection: some View {
        VStack(alignment: .leading, spacing: 8) { // REDUZIDO de 12 para 8
            HStack {
                Text("🔧")
                    .font(.headline) // REDUZIDO
                Text("CONFIGURAÇÕES AVANÇADAS")
                    .font(.subheadline) // REDUZIDO
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlue)
            }
            
            VStack(spacing: 8) { // REDUZIDO de 10 para 8
                // Formato da playlist
                VStack(alignment: .leading, spacing: 4) { // REDUZIDO de 6 para 4
                    Text("Formato da Playlist:")
                        .font(.caption) // REDUZIDO
                        .foregroundColor(.white)
                    
                    HStack {
                        Button(action: { configService.config.playlistFormat = "ts" }) {
                            HStack {
                                Image(systemName: configService.config.playlistFormat == "ts" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.primaryColor)
                                Text("TS")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { configService.config.playlistFormat = "hls" }) {
                            HStack {
                                Image(systemName: configService.config.playlistFormat == "hls" ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.primaryColor)
                                Text("HLS")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("DNS Alternativo")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("Ex: servidor2.com.br", text: $configService.config.alternativeDns)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Porta")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("Padrão: 80", text: $configService.config.port)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Intervalo (min)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextField("30", text: $configService.config.updateInterval)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Reconexão Automática", isOn: $configService.config.autoReconnect)
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Toggle("Aceleração por Hardware", isOn: $configService.config.hardwareAcceleration)
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
                    
                    Button(action: logout) {
                        Text("🚪")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(12) // REDUZIDO de 16 para 12
        .modifier(CardBackground())
        .padding(.horizontal)
    }
    
    // MARK: - Example Config Section (COMPACTA)
    private var exampleConfigSection: some View {
        VStack(alignment: .leading, spacing: 6) { // REDUZIDO de 12 para 6
            HStack {
                Text("💡")
                    .font(.headline)
                Text("EXEMPLO")
                    .font(.subheadline) // REDUZIDO
                    .fontWeight(.bold)
                    .foregroundColor(.successColor)
            }
            
            VStack(alignment: .leading, spacing: 4) { // REDUZIDO de 6 para 4
                Text("Dados de Exemplo:")
                    .font(.caption) // REDUZIDO
                    .fontWeight(.bold)
                    .foregroundColor(.successColor)
                
                Text("""
                Host: seuservidor.com.br
                User: 123456 | Pass: 123456
                """)
                    .font(.system(.caption2, design: .monospaced)) // REDUZIDO
                    .foregroundColor(.white)
                    .padding(8) // REDUZIDO de 12 para 8
                    .background(Color.backgroundDark)
                    .cornerRadius(6)
                
                Text("URL: \(generateExampleURL())")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(6) // REDUZIDO de 8 para 6
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .lineLimit(2)
            }
        }
        .padding(12) // REDUZIDO de 16 para 12
        .background(Color.successColor.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Methods
    private func authenticateUser() {
        if username == adminUsername && password == adminPassword {
            withAnimation {
                isAuthenticated = true
            }
        } else {
            alertMessage = "❌ Credenciais inválidas\nTente: admin / admin"
            showingAlert = true
            password = ""
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            let success = await configService.testConnection()
            
            DispatchQueue.main.async {
                self.isTestingConnection = false
                
                if success {
                    self.testResult = "✅ Conexão bem-sucedida!"
                } else {
                    self.testResult = "❌ Falha na conexão: \(configService.lastError ?? "Erro desconhecido")"
                }
            }
        }
    }
    
    private func saveConfiguration() {
        // Gerar URL da playlist
        configService.generatePlaylistURL()
        
        // Salvar configuração
        configService.saveConfiguration()
        
        alertMessage = "✅ Configuração salva com sucesso!\nA lista de canais será atualizada."
        showingAlert = true
        
        // Fechar tela de admin após salvar
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func exportConfiguration() {
        let config = """
        Configuração Epic Cinema Pro
        ===========================
        Host/DNS: \(configService.config.hostDns)
        Usuário: \(configService.config.username)
        Formato: \(configService.config.playlistFormat)
        Porta: \(configService.config.port)
        URL Playlist: \(configService.config.playlistUrl)
        Data: \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))
        """
        
        UIPasteboard.general.string = config
        
        alertMessage = "💾 Configurações exportadas!\n📋 Dados copiados para o clipboard"
        showingAlert = true
    }
    
    private func clearCache() {
        // Limpar cache (implementação básica)
        URLCache.shared.removeAllCachedResponses()
        
        alertMessage = "🗑️ Cache limpo com sucesso!\n📱 Espaço liberado"
        showingAlert = true
    }
    
    private func logout() {
        withAnimation {
            isAuthenticated = false
            username = ""
            password = ""
        }
    }
    
    private func generateExampleURL() -> String {
        if configService.config.hostDns.isEmpty {
            return "http://servidor.com/get.php?user=user&pass=pass&type=m3u_plus"
        } else {
            configService.generatePlaylistURL()
            return configService.config.playlistUrl
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView(configService: ConfigService())
    }
}
