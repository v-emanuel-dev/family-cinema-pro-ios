//
//  StreamingView.swift
//  Family Cinema Pro
//
//  VERSÃO FINAL CORRIGIDA
//

import SwiftUI
import AVKit

struct StreamingView: View {
    @StateObject private var playerService = VideoPlayerService()
    @StateObject private var configService = ConfigService()
    
    @State private var channels: [Channel] = Channel.defaultFreeChannels
    @State private var selectedChannel: Channel?
    @State private var isChannelsTabActive = true
    @State private var showingControls = false
    @State private var showingAdminSheet = false
    @State private var showingPremiumPopup = false
    @State private var isFullScreen = false
    @State private var controlsTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                playerArea
                    .frame(width: geometry.size.width * (isFullScreen ? 1.0 : 0.65))
                
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("configurationChanged"))) { _ in
            Task { await loadNewConfiguration() }
        }
        .sheet(isPresented: $showingAdminSheet) {
            AdminView(configService: configService)
        }
        .sheet(isPresented: $showingPremiumPopup) {
            PremiumPopupView()
        }
    }
    
    private var playerArea: some View {
        ZStack {
            Color.black
            
            if playerService.player != nil {
                VideoPlayerView(playerService: playerService)
            }
            
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
            
            if showingControls {
                playerControlsOverlay
            }
        }
        .onTapGesture {
            toggleControls()
        }
    }
    
    private var playerControlsOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
            
            VStack {
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
    
    private var sidePanel: some View {
        VStack(spacing: 0) {
            sideHeader
            tabButtons
            
            if isChannelsTabActive {
                channelsSection
            } else {
                infoSection
            }
        }
        .background(Color.surfaceDark)
    }
    
    private var sideHeader: some View {
        HStack {
            Image(systemName: "play.tv")
                .font(.title2)
                .foregroundColor(.primaryColor)
            
            Text("Epic Cinema Pro")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                showingAdminSheet = true
            }) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundColor(.primaryColor)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.cardBackground)
    }
    
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
    
    private var channelsSection: some View {
        VStack(spacing: 0) {
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
    
    private var infoSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("TRANSMISSÃO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Qualidade: Automática")
                        Text("Protocolo: HLS/HTTP")
                        Text("Buffer: Adaptativo")
                        Text("Total de canais: \(channels.count)")
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
    
    private var playerStateText: String {
        switch playerService.playerState {
        case .idle: return "⚪ Aguardando..."
        case .loading: return "🔄 Carregando..."
        case .ready, .playing: return "📺 AO VIVO"
        case .paused: return "⏸️ Pausado"
        case .error: return "❌ Erro"
        }
    }
    
    private func setupInitialState() {
        if channels.isEmpty {
            channels = Channel.defaultFreeChannels
        }
        
        if let firstChannel = channels.first {
            selectChannel(firstChannel)
        }
        
        Task { await loadNewConfiguration() }
    }
    
    private func schedulePremiumPopup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showingPremiumPopup = true
        }
    }
    
    private func loadNewConfiguration() async {
        print("📺 === LOAD NEW CONFIGURATION ===")
        
        guard configService.config.configChanged else {
            print("📺 Config não mudou - pulando")
            return
        }
        
        if !configService.config.playlistUrl.isEmpty {
            print("📺 Iniciando download...")
            
            // Marcar como processado ANTES do download
            await MainActor.run {
                configService.config.configChanged = false
                configService.saveConfigurationSilent()
            }
            
            let newChannels = await configService.downloadPlaylist()
            print("📺 Download concluído: \(newChannels.count) canais")
            
            await MainActor.run {
                if !newChannels.isEmpty {
                    print("📺 Atualizando lista de canais")
                    channels = newChannels
                    
                    if let firstChannel = newChannels.first {
                        selectChannel(firstChannel)
                    }
                } else if channels.isEmpty {
                    channels = Channel.defaultFreeChannels
                    if let firstChannel = channels.first {
                        selectChannel(firstChannel)
                    }
                }
            }
        } else {
            await MainActor.run {
                configService.config.configChanged = false
                configService.saveConfigurationSilent()
            }
        }
        
        print("📺 === FIM LOAD NEW CONFIGURATION ===")
    }
    
    private func selectChannel(_ channel: Channel) {
        selectedChannel = channel
        playerService.loadChannel(channel)
        switchToInfoTab()
    }
    
    private func skipToNextChannel() {
        guard let currentChannel = selectedChannel,
              let currentIndex = channels.firstIndex(where: { $0.id == currentChannel.id }),
              currentIndex < channels.count - 1 else {
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

#if DEBUG
struct StreamingView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
