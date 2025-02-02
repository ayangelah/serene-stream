import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct TracksView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var tracks: [Track] = []
    @State private var showOthersLikeYou = false
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayerManager: AudioPlayerManager?
    @State private var isPlaying = false
    @State private var currentlyPlayingFileURL: URL?
    
    
    private let fileManager = FileManager.default
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    var body: some View {
        VStack {
            List {
                ForEach(tracks) { track in
                    HStack {
                        Text(track.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Button(action: {
                            if isPlaying && currentlyPlayingFileURL == track.fileURL {
                                // If this file is currently playing, stop it
                                audioPlayer?.stop()
                                isPlaying = false
                                currentlyPlayingFileURL = URL(filePath: "")
                            } else {
                                // If this file is not playing, play it
                                playAudio(audioFileURL: track.fileURL)
                            }
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
                        // Delete Action
                        Button(role: .destructive) {
                            deleteTrack(track)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        // Connect Action
                        Button {
                            showOthersLikeYou = true
                        } label: {
                            Label("Connect", systemImage: "person.2.circle")
                        }
                        .tint(.blue)
                    }
                }
            }

            Spacer()
        }
        .sheet(isPresented: $showOthersLikeYou) {
            OthersLikeYouView()
        }
        .navigationTitle("Tracks")
        .onAppear {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set audio session category: \(error)")
            }
            loadSavedTracks()
        }
    }

    // MARK: - Track Management
    private func loadSavedTracks() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
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
    
    private func playAudio(audioFileURL: URL) {
        do {
            // Stop any currently playing audio
            if isPlaying {
                audioPlayer?.stop()
                isPlaying = false
                currentlyPlayingFileURL = URL(filePath: "")
            }
            
            // Create a new audio player manager
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
}

struct Track: Identifiable {
    let id: UUID
    let name: String
    let fileURL: URL
}
