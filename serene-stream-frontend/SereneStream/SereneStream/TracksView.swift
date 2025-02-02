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
            // Heading "My Tracks"
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
                            if isPlaying && currentlyPlayingFileURL == track.fileURL {
                                audioPlayer?.stop()
                                isPlaying = false
                                currentlyPlayingFileURL = nil
                            } else {
                                playAudio(audioFileURL: track.fileURL)
                            }
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
                    .padding()
                    .swipeActions(edge: .trailing) {
                        Button {
                            // Magic wand functionality will be added later
                        } label: {
                            Label("Magic", systemImage: "wand.and.stars")
                        }
                        .tint(.yellow)
                        
                        Button(role: .destructive) {
                            deleteTrack(track)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Color.white)
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.white)
        }
        .padding()
        .navigationBarHidden(true)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            setupAudioSession()
            loadSavedTracks()
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
    
    private func loadSavedTracks() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey])
            tracks = try files.filter { $0.pathExtension == "mp3" }
                .map { url in
                    let resourceValues = try url.resourceValues(forKeys: [.creationDateKey])
                    let creationDate = resourceValues.creationDate ?? Date()
                    return Track(
                        id: UUID(),
                        name: url.deletingPathExtension().lastPathComponent,
                        fileURL: url,
                        createdDate: creationDate
                    )
                }
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
}
