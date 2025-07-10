//
//  ConfigService.swift
//
//  Serviço para gerenciar configurações e playlists
//

import Foundation
import Combine

// MARK: - Configuration Service
class ConfigService: ObservableObject {
    // MARK: - Published Properties
    @Published var config = IPTVConfig()
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let configKey = "IPTVConfig"
    
    // MARK: - Initialization
    init() {
        loadConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// Salvar configuração
    func saveConfiguration() {
        do {
            let data = try JSONEncoder().encode(config)
            userDefaults.set(data, forKey: configKey)
            config.configChanged = true
            config.lastConfigUpdate = Date()
            
            print("✅ Configuração salva")
            
            // Notificar mudança
            NotificationCenter.default.post(
                name: .configurationChanged,
                object: nil,
                userInfo: ["config": config]
            )
        } catch {
            lastError = "Erro ao salvar configuração: \(error.localizedDescription)"
            print("❌ Erro ao salvar: \(error)")
        }
    }
    
    /// Carregar configuração salva
    func loadConfiguration() {
        guard let data = userDefaults.data(forKey: configKey),
              let savedConfig = try? JSONDecoder().decode(IPTVConfig.self, from: data) else {
            print("📱 Usando configuração padrão")
            return
        }
        
        config = savedConfig
        print("✅ Configuração carregada")
    }
    
    /// Testar conexão
    func testConnection() async -> Bool {
        isLoading = true
        lastError = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        // Verificar se é M3U direto
        if config.isDirectM3U || config.hostDns.contains(".m3u") {
            return await testM3UConnection()
        } else {
            return await testIPTVConnection()
        }
    }
    
    /// Baixar e processar playlist M3U
    func downloadPlaylist() async -> [Channel] {
        isLoading = true
        lastError = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard !config.playlistUrl.isEmpty else {
            DispatchQueue.main.async {
                self.lastError = "URL da playlist não configurada"
            }
            return []
        }
        
        do {
            let channels = try await downloadAndParseM3U(url: config.playlistUrl)
            print("✅ \(channels.count) canais baixados")
            return channels
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Erro ao baixar playlist: \(error.localizedDescription)"
            }
            print("❌ Erro no download: \(error)")
            return []
        }
    }
    
    /// Gerar URL da playlist automaticamente
    func generatePlaylistURL() {
        if config.isDirectM3U {
            config.playlistUrl = config.hostDns
        } else {
            let baseUrl = config.hostDns.hasPrefix("http") ? config.hostDns : "http://\(config.hostDns)"
            config.playlistUrl = "\(baseUrl)/get.php?username=\(config.username)&password=\(config.password)&type=m3u_plus&output=\(config.playlistFormat)"
        }
    }
    
    /// Limpar configuração
    func clearConfiguration() {
        userDefaults.removeObject(forKey: configKey)
        config = IPTVConfig()
        print("🗑️ Configuração limpa")
    }
    
    // MARK: - Private Methods
    
    private func testM3UConnection() async -> Bool {
        guard let url = URL(string: config.hostDns) else {
            await MainActor.run {
                lastError = "URL inválida"
            }
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                
                await MainActor.run {
                    if success {
                        lastError = nil
                    } else {
                        lastError = "HTTP \(httpResponse.statusCode)"
                    }
                }
                
                return success
            }
            
            return false
        } catch {
            await MainActor.run {
                lastError = "Erro de conexão: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func testIPTVConnection() async -> Bool {
        generatePlaylistURL()
        
        let testUrl = "\(config.hostDns.hasPrefix("http") ? config.hostDns : "http://\(config.hostDns)")/player_api.php?username=\(config.username)&password=\(config.password)&action=get_info"
        
        guard let url = URL(string: testUrl) else {
            await MainActor.run {
                lastError = "URL de teste inválida"
            }
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                
                await MainActor.run {
                    if success {
                        lastError = nil
                    } else {
                        lastError = "Credenciais inválidas (HTTP \(httpResponse.statusCode))"
                    }
                }
                
                return success
            }
            
            return false
        } catch {
            await MainActor.run {
                lastError = "Erro de conexão: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func downloadAndParseM3U(url: String) async throws -> [Channel] {
        guard let playlistURL = URL(string: url) else {
            throw ConfigError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: playlistURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ConfigError.networkError
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConfigError.invalidData
        }
        
        return parseM3UContent(content)
    }
    
    private func parseM3UContent(_ content: String) -> [Channel] {
        var channels: [Channel] = []
        let lines = content.components(separatedBy: .newlines)
        
        var channelId = 1
        var currentChannelName = ""
        var currentChannelGroup = "Geral"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("#EXTINF:") {
                // Extrair informações do canal
                currentChannelName = extractChannelName(from: trimmedLine)
                currentChannelGroup = extractChannelGroup(from: trimmedLine)
                
            } else if trimmedLine.hasPrefix("http") && !currentChannelName.isEmpty {
                // URL do canal
                let channel = Channel(
                    id: channelId,
                    name: currentChannelName.isEmpty ? "Canal \(channelId)" : currentChannelName,
                    description: "Canal \(currentChannelGroup)",
                    url: trimmedLine,
                    category: currentChannelGroup.isEmpty ? "Geral" : currentChannelGroup
                )
                
                channels.append(channel)
                channelId += 1
                currentChannelName = ""
                
                // Limite para não travar o app
                if channels.count >= 1000 {
                    break
                }
            }
        }
        
        return channels
    }
    
    private func extractChannelName(from line: String) -> String {
        // Pegar o nome após a última vírgula
        if let range = line.range(of: ",", options: .backwards) {
            return String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Canal Desconhecido"
    }
    
    private func extractChannelGroup(from line: String) -> String {
        // Procurar por group-title="..."
        if let range = line.range(of: "group-title=\"") {
            let startIndex = range.upperBound
            if let endRange = line[startIndex...].range(of: "\"") {
                return String(line[startIndex..<endRange.lowerBound])
            }
        }
        return "Geral"
    }
}

// MARK: - Configuration Errors
enum ConfigError: LocalizedError {
    case invalidURL
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .networkError:
            return "Erro de rede"
        case .invalidData:
            return "Dados inválidos"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let configurationChanged = Notification.Name("configurationChanged")
}
