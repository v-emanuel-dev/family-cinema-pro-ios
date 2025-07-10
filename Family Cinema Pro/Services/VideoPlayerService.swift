//
//  VideoPlayerService.swift
//
//  Serviço para controlar reprodução de vídeo
//

import AVKit
import AVFoundation
import SwiftUI
import Combine

// MARK: - Player States
enum PlayerState: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case error(String)
    
    // Implementação do Equatable para casos com valores associados
    static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.ready, .ready),
             (.playing, .playing),
             (.paused, .paused):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Video Player Service
class VideoPlayerService: ObservableObject {
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    @Published var playerState: PlayerState = .idle
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var currentChannel: Channel?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    // MARK: - Initialization
    init() {
        setupPlayer()
    }
    
    // MARK: - Public Methods
    
    /// Carregar e reproduzir um canal
    func loadChannel(_ channel: Channel) {
        print("🎬 Carregando canal: \(channel.name)")
        print("🔗 URL: \(channel.url)")
        
        currentChannel = channel
        playerState = .loading
        
        // Validar URL
        guard let url = URL(string: channel.url),
              isValidStreamURL(channel.url) else {
            playerState = .error("URL inválida: \(channel.url)")
            return
        }
        
        // Parar reprodução atual
        stopPlayback()
        
        // Criar novo PlayerItem
        playerItem = AVPlayerItem(url: url)
        
        // Configurar observers para o PlayerItem
        setupPlayerItemObservers()
        
        // Configurar player com novo item
        if player == nil {
            setupPlayer()
        }
        
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        
        print("✅ Player configurado para: \(channel.name)")
    }
    
    /// Play/Pause
    func togglePlayPause() {
        guard let player = player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
            print("⏸️ Player pausado")
        } else {
            player.play()
            isPlaying = true
            print("▶️ Player reproduzindo")
        }
    }
    
    /// Mute/Unmute
    func toggleMute() {
        guard let player = player else { return }
        
        player.isMuted.toggle()
        isMuted = player.isMuted
        print("🔊 Mute: \(isMuted)")
    }
    
    /// Parar reprodução
    func stopPlayback() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerItem = nil
        isPlaying = false
        playerState = .idle
    }
    
    /// Limpar recursos
    func cleanup() {
        // Remover observers
        removeObservers()
        
        // Limpar player
        stopPlayback()
        player = nil
        
        // Limpar cancellables
        cancellables.removeAll()
        
        print("🧹 VideoPlayerService limpo")
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer() {
        // Configurar audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Erro ao configurar AVAudioSession: \(error)")
        }
        
        // Criar player
        player = AVPlayer()
        
        // Configurar observers do player
        setupPlayerObservers()
        
        print("✅ AVPlayer configurado")
    }
    
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        // Observer para status de reprodução
        player.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .playing:
                        self?.isPlaying = true
                        self?.playerState = .playing
                        print("🎬 Player: PLAYING")
                    case .paused:
                        self?.isPlaying = false
                        if self?.playerState == .loading {
                            // Ainda carregando
                        } else {
                            self?.playerState = .paused
                        }
                        print("⏸️ Player: PAUSED")
                    case .waitingToPlayAtSpecifiedRate:
                        self?.playerState = .loading
                        print("⏳ Player: LOADING")
                    @unknown default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observer para volume
        player.publisher(for: \.isMuted)
            .sink { [weak self] muted in
                DispatchQueue.main.async {
                    self?.isMuted = muted
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupPlayerItemObservers() {
        guard let playerItem = playerItem else { return }
        
        // Observer para status do item
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        self?.playerState = .ready
                        print("✅ PlayerItem: READY TO PLAY")
                    case .failed:
                        let error = playerItem.error?.localizedDescription ?? "Erro desconhecido"
                        self?.playerState = .error("Falha na reprodução: \(error)")
                        print("❌ PlayerItem: FAILED - \(error)")
                    case .unknown:
                        self?.playerState = .loading
                        print("❓ PlayerItem: UNKNOWN")
                    @unknown default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observer para buffer vazio
        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .sink { [weak self] isEmpty in
                if isEmpty {
                    DispatchQueue.main.async {
                        self?.playerState = .loading
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observer para buffer mantendo reprodução
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .sink { [weak self] likelyToKeepUp in
                if likelyToKeepUp && playerItem.status == .readyToPlay {
                    DispatchQueue.main.async {
                        self?.playerState = .ready
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observer para erros de rede
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime)
            .sink { [weak self] notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                    DispatchQueue.main.async {
                        self?.playerState = .error("Erro de reprodução: \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        cancellables.removeAll()
    }
    
    private func isValidStreamURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty,
              urlString.hasPrefix("http"),
              urlString.count > 10 else {
            return false
        }
        
        // Verificar se é uma URL de stream válida
        let validExtensions = [".m3u8", "playlist", "hls"]
        return validExtensions.contains { urlString.contains($0) }
    }
}

// MARK: - VideoPlayerView para SwiftUI
struct VideoPlayerView: UIViewControllerRepresentable {
    @ObservedObject var playerService: VideoPlayerService
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false // Usar controles customizados
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = playerService.player
    }
}
