//
//  Channel.swift
//  Family Cinema Pro
//
//  VERSÃO FINAL CORRIGIDA
//

import Foundation
import Combine

// MARK: - Channel Model
struct Channel: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let url: String
    let category: String
    let logo: String?
    let isLive: Bool
    
    init(id: Int, name: String, description: String, url: String, category: String, logo: String? = nil, isLive: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.url = url
        self.category = category
        self.logo = logo
        self.isLive = isLive
    }
}

// MARK: - Canais Padrão
extension Channel {
    static let defaultFreeChannels: [Channel] = [
        Channel(id: 1, name: "Red Bull TV", description: "Esportes radicais e eventos", url: "https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8", category: "Esportes"),
        Channel(id: 2, name: "RT News", description: "Russia Today - Notícias 24/7", url: "https://rt-glb.rttv.com/live/rtnews/playlist.m3u8", category: "Notícias"),
        Channel(id: 3, name: "Al Jazeera English", description: "Canal de notícias internacional", url: "https://live-hls-web-aje.getaj.net/AJE/index.m3u8", category: "Notícias"),
        Channel(id: 4, name: "Fashion TV", description: "Moda e estilo de vida", url: "https://fashiontv-fashiontv-1-eu.rakuten.wurl.tv/playlist.m3u8", category: "Estilo"),
        Channel(id: 5, name: "Bloomberg TV", description: "Notícias financeiras", url: "https://bloomberg.com/media-manifest/streams/phoenix-us.m3u8", category: "Economia")
    ]
}

// MARK: - IPTVConfig Model
struct IPTVConfig: Codable {
    var hostDns: String = ""
    var username: String = ""
    var password: String = ""
    var port: String = "80"
    var alternativeDns: String = ""
    var playlistFormat: String = "ts"
    var playlistUrl: String = ""
    var updateInterval: String = "30"
    var autoReconnect: Bool = true
    var hardwareAcceleration: Bool = true
    var isDirectM3U: Bool = false
    var configChanged: Bool = false
    var lastConfigUpdate: Date = Date()
}

// MARK: - ConfigService
class ConfigService: ObservableObject {
    @Published var config = IPTVConfig()
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "IPTVConfig"
    private var isSaving = false
    
    init() {
        loadConfiguration()
    }
    
    func saveConfiguration() {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        do {
            let data = try JSONEncoder().encode(config)
            userDefaults.set(data, forKey: configKey)
            config.lastConfigUpdate = Date()
            config.configChanged = true
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("configurationChanged"), object: nil)
                print("📻 NOTIFICAÇÃO ENVIADA!")
            }
        } catch {
            lastError = "Erro ao salvar: \(error.localizedDescription)"
        }
    }
    
    func saveConfigurationSilent() {
        do {
            let data = try JSONEncoder().encode(config)
            userDefaults.set(data, forKey: configKey)
            config.lastConfigUpdate = Date()
            print("✅ Configuração salva silenciosamente")
        } catch {
            lastError = "Erro ao salvar: \(error.localizedDescription)"
        }
    }
    
    func loadConfiguration() {
        guard let data = userDefaults.data(forKey: configKey),
              let savedConfig = try? JSONDecoder().decode(IPTVConfig.self, from: data) else {
            return
        }
        config = savedConfig
    }
    
    func generatePlaylistURL() {
        let isDirectM3U = config.hostDns.contains(".m3u") || config.hostDns.contains("playlist") ||
                         config.username.isEmpty || config.password.isEmpty
        
        if isDirectM3U {
            config.playlistUrl = config.hostDns
            config.isDirectM3U = true
        } else {
            let baseUrl = config.hostDns.hasPrefix("http") ? config.hostDns : "http://\(config.hostDns)"
            let port = config.port.isEmpty ? "" : ":\(config.port)"
            config.playlistUrl = "\(baseUrl)\(port)/get.php?username=\(config.username)&password=\(config.password)&type=m3u_plus&output=\(config.playlistFormat)"
            config.isDirectM3U = false
        }
        print("🔗 URL gerada: \(config.playlistUrl)")
    }
    
    func testConnection() async -> Bool {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        generatePlaylistURL()
        guard let url = URL(string: config.playlistUrl) else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
            return false
        }
    }
    
    func downloadPlaylist() async -> [Channel] {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        guard !config.playlistUrl.isEmpty,
              let url = URL(string: config.playlistUrl) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) else { return [] }
            return parseM3U(content)
        } catch {
            return []
        }
    }
    
    private func parseM3U(_ content: String) -> [Channel] {
        var channels: [Channel] = []
        let lines = content.components(separatedBy: .newlines)
        var channelId = 1
        var currentName = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("#EXTINF:") {
                if let range = trimmed.range(of: ",", options: .backwards) {
                    currentName = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if trimmed.hasPrefix("http") && !currentName.isEmpty {
                let channel = Channel(
                    id: channelId,
                    name: currentName,
                    description: "Canal ao vivo",
                    url: trimmed,
                    category: "Geral"
                )
                channels.append(channel)
                channelId += 1
                currentName = ""
                
                if channels.count >= 500 { break }
            }
        }
        
        return channels
    }
}
