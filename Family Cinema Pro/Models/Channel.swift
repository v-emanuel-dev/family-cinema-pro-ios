//
//  Channel.swift
//  Family Cinema Pro
//
//  Modelo de dados para representar um canal de TV
//

import Foundation

// MARK: - Channel Model
struct Channel: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let url: String
    let category: String
    let logo: String?
    let isLive: Bool
    
    // Construtor padrão
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

// MARK: - Canais Gratuitos Padrão
extension Channel {
    static let defaultFreeChannels: [Channel] = [
        Channel(
            id: 1,
            name: "Red Bull TV",
            description: "Esportes radicais e eventos",
            url: "https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8",
            category: "Esportes"
        ),
        Channel(
            id: 2,
            name: "RT News",
            description: "Russia Today - Notícias 24/7",
            url: "https://rt-glb.rttv.com/live/rtnews/playlist.m3u8",
            category: "Notícias"
        ),
        Channel(
            id: 3,
            name: "Al Jazeera English",
            description: "Canal de notícias internacional",
            url: "https://live-hls-web-aje.getaj.net/AJE/index.m3u8",
            category: "Notícias"
        ),
        Channel(
            id: 4,
            name: "Fashion TV",
            description: "Moda e estilo de vida",
            url: "https://fashiontv-fashiontv-1-eu.rakuten.wurl.tv/playlist.m3u8",
            category: "Estilo"
        ),
        Channel(
            id: 5,
            name: "Bloomberg TV",
            description: "Notícias financeiras",
            url: "https://bloomberg.com/media-manifest/streams/phoenix-us.m3u8",
            category: "Economia"
        )
    ]
}

// MARK: - IPTVConfig Model
struct IPTVConfig: Codable {
    var hostDns: String
    var username: String
    var password: String
    var port: String
    var alternativeDns: String
    var playlistFormat: String
    var playlistUrl: String
    var updateInterval: String
    var autoReconnect: Bool
    var hardwareAcceleration: Bool
    var isDirectM3U: Bool
    var configChanged: Bool
    var lastConfigUpdate: Date
    
    // Construtor com valores padrão
    init() {
        self.hostDns = ""
        self.username = ""
        self.password = ""
        self.port = "80"
        self.alternativeDns = ""
        self.playlistFormat = "ts"
        self.playlistUrl = ""
        self.updateInterval = "30"
        self.autoReconnect = true
        self.hardwareAcceleration = true
        self.isDirectM3U = false
        self.configChanged = false
        self.lastConfigUpdate = Date()
    }
}
