//
//  StreamingView.swift
//  Family Cinema Pro
//
//  Tela principal de streaming com player e lista de canais
//

import SwiftUI
import AVKit

struct StreamingView: View {
    // MARK: - State Objects
    @StateObject private var playerService = VideoPlayerService()
    @StateObject private var configService = ConfigService()
    
    // MARK: - State Variables
    @State private var channels: [Channel] = Channel.defaultFreeChannels
    @State private var selectedChannel: Channel?
    @State private var isChannelsTabActive = true
    @State private var showingControls = false
    @State private var showingAdminSheet = false
    @State private var showingPremiumPopup = false
    @State private var isFullScreen = false
    
    // MARK: - Timer para esconder controles
    @State private var controlsTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - Player Area (65%)
                playerArea
                    .frame(width: geometry.size.width * (isFullScreen ? 1.0 : 0.65))
                
                // MARK: - Side Panel (35%)
                if !isFullScreen {
                    sidePanel
                        .frame(width: geometry.size.width * 0.35)
                }
            }
        }
        .background(Color.backgroundDark)
        .ignoresSafeArea()
        .onAppear {
            setupInitialState()
            schedulePremiumPopup()
        }
        .onReceive(NotificationCenter.default.publisher(for: .configurationChanged)) { _ in
            loadNewConfiguration()
        }
        .sheet(isPresented: $showingAdminSheet) {
            AdminView(configService: configService)
        }
        .sheet(isPresented: $showingPremiumPopup) {
            PremiumPopupView()
                .presentationDetents([.large])
        }
    }
    
    // MARK: - Player Area
    private var playerArea: some View {
        ZStack {
            // Background preto
            Color.black
            
            // Video Player
            if let player = playerService.player {
                VideoPlayerView(playerService: playerService)
            }
            
            // Loading indicator
            if playerService.playerState == .loading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("🔄 Carregando...")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top)
                }
            }
            
            // Error state
            if case .error(let errorMessage) = playerService.playerState {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("❌ Erro na reprodução")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Text(errorMessage)
                        .foregroundColor(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Player Controls Overlay
            if showingControls {
                playerControlsOverlay
            }
        }
        .onTapGesture {
            toggleControls()
        }
    }
    
    // MARK: - Player Controls Overlay
    private var playerControlsOverlay: some View {
        ZStack {
            // Background escuro semi-transparente
            Color.black.opacity(0.5)
            
            VStack {
                // Top controls
                HStack {
                    Spacer()
                    
                    Button(action: skipToNextChannel) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: toggleFullScreen) {
                        Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Center controls
                HStack(spacing: 30) {
                    Button(action: playerService.togglePlayPause) {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Button(action: playerService.toggleMute) {
                        Image(systemName: playerService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingControls)
    }
    
    // MARK: - Side Panel
    private var sidePanel: some View {
        VStack(spacing: 0) {
            // Header with logo and admin button
            sideHeader
            
            // Tab buttons
            tabButtons
            
            // Content area
            if isChannelsTabActive {
                channelsSection
            } else {
                infoSection
            }
        }
        .background(Color.surfaceDark)
    }
    
    // MARK: - Side Header
    private var sideHeader: some View {
        HStack {
            // Logo
            Image(systemName: "play.tv")
                .font(.title2)
                .foregroundColor(.primaryColor)
            
            Text("Family Cinema Pro")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Admin settings button
            Button(action: { showingAdminSheet = true }) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundColor(.primaryColor)
            }
        }
        .padding()
        .background(Color.cardBackground)
    }
    
    // MARK: - Tab Buttons
    private var tabButtons: some View {
        HStack(spacing: 2) {
            Button(action: { switchToChannelsTab() }) {
                Text("Canais")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isChannelsTabActive ? .white : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isChannelsTabActive ? Color.primaryColor : Color.surfaceDark)
            }
            
            Button(action: { switchToInfoTab() }) {
                Text("Info")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(!isChannelsTabActive ? .white : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(!isChannelsTabActive ? Color.primaryColor : Color.surfaceDark)
            }
        }
        .background(Color.surfaceDark)
    }
    
    // MARK: - Channels Section
    private var channelsSection: some View {
        VStack(spacing: 0) {
            // Premium banner
            Button(action: { showingPremiumPopup = true }) {
                HStack {
                    Text("👑")
                        .font(.title2)
                    
                    Text("ACESSO PREMIUM ★★★★★")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gold)
            }
            
            // Channels list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(channels) { channel in
                        ChannelRowView(
                            channel: channel,
                            isSelected: selectedChannel?.id == channel.id
                        ) {
                            selectChannel(channel)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Current channel info
                if let channel = selectedChannel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CANAL ATUAL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.textSecondary)
                        
                        Text(channel.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(channel.description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        // Live indicator
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(playerStateText)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                
                // Transmission info
                VStack(alignment: .leading, spacing: 8) {
                    Text("TRANSMISSÃO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Qualidade: Automática")
                        Text("Protocolo: HLS/HTTP")
                        Text("Buffer: Adaptativo")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }
                .padding()
                .background(Color.backgroundDark)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var playerStateText: String {
        switch playerService.playerState {
        case .idle:
            return "⚪ Aguardando..."
        case .loading:
            return "🔄 Carregando..."
        case .ready, .playing:
            return "📺 AO VIVO"
        case .paused:
            return "⏸️ Pausado"
        case .error:
            return "❌ Erro"
        }
    }
    
    // MARK: - Methods
    private func setupInitialState() {
        // Carregar primeiro canal automaticamente
        if let firstChannel = channels.first {
            selectChannel(firstChannel)
        }
        
        // Verificar se há nova configuração
        loadNewConfiguration()
    }
    
    private func schedulePremiumPopup() {
        // Mostrar popup premium após 4 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showingPremiumPopup = true
        }
    }
    
    private func loadNewConfiguration() {
        if configService.config.configChanged {
            Task {
                let newChannels = await configService.downloadPlaylist()
                
                DispatchQueue.main.async {
                    if !newChannels.isEmpty {
                        self.channels = newChannels
                        
                        // Selecionar primeiro canal da nova playlist
                        if let firstChannel = newChannels.first {
                            self.selectChannel(firstChannel)
                        }
                        
                        // Marcar como processado
                        self.configService.config.configChanged = false
                        self.configService.saveConfiguration()
                    }
                }
            }
        }
    }
    
    private func selectChannel(_ channel: Channel) {
        selectedChannel = channel
        playerService.loadChannel(channel)
        
        // Mudar para aba info quando selecionar canal
        switchToInfoTab()
    }
    
    private func skipToNextChannel() {
        guard let currentChannel = selectedChannel,
              let currentIndex = channels.firstIndex(where: { $0.id == currentChannel.id }),
              currentIndex < channels.count - 1 else {
            // Se chegou ao final, voltar ao primeiro
            if let firstChannel = channels.first {
                selectChannel(firstChannel)
            }
            return
        }
        
        let nextChannel = channels[currentIndex + 1]
        selectChannel(nextChannel)
        scheduleHideControls()
    }
    
    private func toggleControls() {
        showingControls.toggle()
        
        if showingControls {
            scheduleHideControls()
        }
    }
    
    private func scheduleHideControls() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                showingControls = false
            }
        }
    }
    
    private func toggleFullScreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFullScreen.toggle()
        }
        scheduleHideControls()
    }
    
    private func switchToChannelsTab() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isChannelsTabActive = true
        }
    }
    
    private func switchToInfoTab() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isChannelsTabActive = false
        }
    }
}

// MARK: - Channel Row View
struct ChannelRowView: View {
    let channel: Channel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Live indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .textPrimary)
                        .lineLimit(1)
                    
                    Text(channel.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(channel.category)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .primaryColor : .accentBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white : Color.clear)
                    .cornerRadius(8)
            }
            .padding(12)
            .background(isSelected ? Color.primaryColor : Color.surfaceDark)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
