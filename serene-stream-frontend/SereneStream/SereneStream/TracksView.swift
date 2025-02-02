import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct TracksView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var connectTaskViewModel = ConnectTaskViewModel()
    
    @State private var tracks: [Track] = []
    @State private var showOthersLikeYou: Bool = false
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayerManager: AudioPlayerManager?
    @State private var isPlaying: Bool = false
    @State private var currentlyPlayingFileURL: URL?
    
    private let fileManager: FileManager = FileManager.default
    private let documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    var body: some View {
        ZStack {
            if connectTaskViewModel.isLoading {
                ProgressView("Connecting Your Tracks...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 200)
                    .zIndex(1)
            }
            
            VStack {
                List {
                    ForEach(tracks) { track in
                        HStack {
                            Text(track.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Button(action: {
                                handlePlayButton(for: track)
                            }) {
                                if isPlaying && currentlyPlayingFileURL == track.fileURL {
                                    SoundWaveView()
                                        .frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(Color(hex: "#ffffff"))
                                }
                            }
                            .padding(.leading, 8)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteTrack(track)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                showOthersLikeYou = true
                                connectTaskViewModel.findConnect(with: authViewModel.token ?? "", documentsDirectory: documentsDirectory, inputTrackURL: track.fileURL)
                            } label: {
                                Label("Connect", systemImage: "person.2.circle")
                            }
                            .tint(.blue)
                        }
                    }
                }
                Spacer()
            }
            .sheet(isPresented: Binding(get: {showOthersLikeYou && !connectTaskViewModel.isLoading}, set: { showOthersLikeYou = $0})
            ) {
                OthersLikeYouView(similarTrackFiles: connectTaskViewModel.similarTrackFiles, playAudio: playAudio)
                    .onDisappear {
                        audioPlayer?.stop()
                        isPlaying = false
                        currentlyPlayingFileURL = URL(filePath: "")
                        
                        for fileURL in connectTaskViewModel.similarTrackFiles ?? [] {
                            do {
                                try fileManager.removeItem(at: fileURL)
                            } catch {
                                print("Error deleting file \(fileURL): \(error.localizedDescription)")
                            }
                        }
                        loadSavedTracks()
                    }
            }
            .navigationTitle("Tracks")
            .onAppear {
                setupAudioSession()
                loadSavedTracks()
            }
        }
    }
    
    // MARK: - Track Management
    private func loadSavedTracks() {
        do {
            let files: [URL] = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            tracks = files.filter { $0.pathExtension == "mp3" }
                .map { Track(id: UUID(), name: $0.lastPathComponent, fileURL: $0) }
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }
    
    private func deleteTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        do {
            try fileManager.removeItem(at: track.fileURL)
        } catch {
            print("Error deleting file \(track.name): \(error.localizedDescription)")
        }
        
        loadSavedTracks()
    }
    
    private func handlePlayButton(for track: Track) {
        if isPlaying && currentlyPlayingFileURL == track.fileURL {
            audioPlayer?.stop()
            isPlaying = false
            currentlyPlayingFileURL = URL(filePath: "")
        } else {
            playAudio(audioFileURL: track.fileURL)
        }
    }
    
    private func playAudio(audioFileURL: URL) {
        do {
            if isPlaying {
                audioPlayer?.stop()
                isPlaying = false
                currentlyPlayingFileURL = URL(filePath: "")
            }
            
            audioPlayerManager = AudioPlayerManager {
                isPlaying = false
                currentlyPlayingFileURL = URL(filePath: "")
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.delegate = audioPlayerManager
            audioPlayer?.play()
            isPlaying = true
            currentlyPlayingFileURL = audioFileURL
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
}

struct Track: Identifiable {
    let id: UUID
    let name: String
    let fileURL: URL
}
