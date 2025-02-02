import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct Track: Identifiable {
    let id: UUID
    let name: String
    let fileURL: URL
    let createdDate: Date
}

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
                    .background(Color(hex: "bb8a52").opacity(1)) // Semi-transparent background
                    .cornerRadius(15)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 200)
                    .shadow(radius: 20)
                    .zIndex(1) // Ensure it appears on top of other UI
            }
            
            VStack {
                Text("My Tracks")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#0c3b2e"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, -10)
                
                List {
                    ForEach(tracks) { track in
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(Color(hex: "bb8a52"))
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading) {
                                Text(track.name)
                                    .font(.system(size: 16, weight: .medium))
                                Text("Created: \(formattedDate(track.createdDate))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                handlePlayButton(for: track)
                            }) {
                                if isPlaying && currentlyPlayingFileURL == track.fileURL {
                                    SoundWaveView()
                                        .frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(Color(hex: "bb8a52"))
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
                    .listRowBackground(Color.white)
                }
                .listStyle(PlainListStyle())
                .background(Color.white)
                Spacer()
            }
            .sheet(isPresented: Binding(get: {showOthersLikeYou && !connectTaskViewModel.isLoading}, set: { showOthersLikeYou = $0})
            ) {
                OthersLikeYouView(similarTrackFiles: connectTaskViewModel.similarTrackFiles, similarTrackNames: connectTaskViewModel.similarTrackNames, playAudio: playAudio)
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
            .padding()
            .navigationBarHidden(true)
            .frame(maxHeight: .infinity, alignment: .top)
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
                .map { Track(id: UUID(), name: $0.lastPathComponent, fileURL: $0, createdDate: Date()) }
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
                currentlyPlayingFileURL = nil
            }
            
            audioPlayerManager = AudioPlayerManager {
                isPlaying = false
                currentlyPlayingFileURL = nil
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
}
