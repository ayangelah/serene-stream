import SwiftUI
import AVFoundation

// Create a class to handle the audio player delegate
class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    var onPlaybackFinished: () -> Void
    
    init(onPlaybackFinished: @escaping () -> Void) {
        self.onPlaybackFinished = onPlaybackFinished
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.onPlaybackFinished()
        }
    }
}

struct ClipsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var generateTaskViewModel = GenerateTaskViewModel()
    
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioPlayerManager: AudioPlayerManager?
    @State private var isRecording = false
    @State private var recordedFiles: [String] = []
    @State private var selectedFiles: Set<String> = []
    @State private var showGeneratePage = false
    @Binding var selectedTab: Int

    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?

    @State private var isPlaying = false
    @State private var currentlyPlayingFile: String?

    private let fileManager = FileManager.default
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    var body: some View {
        ZStack {
            // Show ProgressView when the task is running
            if generateTaskViewModel.isLoading {
                ProgressView("Running Task...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.black.opacity(0.5)) // Semi-transparent background
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 200)
                    .zIndex(1) // Ensure it appears on top of other UI
            }
            
            VStack {
                // Heading "My Clips"
                Text("My Clips")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "#0c3b2e"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, -10)

                // List of recorded audio files with checkboxes
                List(recordedFiles, id: \.self, selection: $selectedFiles) { fileName in
                    HStack {
                        Image(systemName: selectedFiles.contains(fileName) ? "checkmark.square.fill" : "square")
                            .foregroundColor(.white)
                            .onTapGesture {
                                toggleSelection(fileName: fileName)
                            }
                        
                        Text(fileName)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            if isPlaying && currentlyPlayingFile == fileName {
                                // If this file is currently playing, stop it
                                audioPlayer?.stop()
                                isPlaying = false
                                currentlyPlayingFile = nil
                            } else {
                                // If this file is not playing, play it
                                playAudio(fileName: fileName)
                            }
                        }) {
                            if isPlaying && currentlyPlayingFile == fileName {
                                SoundWaveView()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "play.fill")
                                    .foregroundColor(selectedFiles.contains(fileName) ? Color(hex: "#0c3b2e") : Color(hex: "#ffffff"))
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(selectedFiles.contains(fileName) ? Color(hex: "6d9773") : Color(hex: "#0c3b2e"))
                    .foregroundColor(selectedFiles.contains(fileName) ? Color(hex: "#0c3b2e") : Color(hex: "#ffffff"))
                    .cornerRadius(8)
                    .listRowBackground(Color.white)
                }
                .listStyle(PlainListStyle()) // Remove default list styling

                Spacer()

                // Record Button (Microphone Icon) and Timer
                if selectedFiles.isEmpty {
                    VStack {
                        if isRecording {
                            Text(timeFormatted(recordingTime))
                                .font(.system(size: 24, design: .monospaced))
                                .foregroundColor(Color(hex: "#0c3b2e"))
                                .padding(.bottom, 8)
                        }

                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#ffffff"))
                                .padding()
                                .background(isRecording ? Color(hex: "#E63946") : Color(hex: "#0c3b2e"))
                                .clipShape(Circle())
                                .overlay(
                                    isRecording ? SoundWaveView().offset(y: 30) : nil
                                )
                        }
                        .padding()
                    }
                }

                // Delete and Generate Buttons
                if !selectedFiles.isEmpty {
                    HStack {
                        Button(action: {
                            deleteSelectedFiles()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#D62828"))
                                .clipShape(Circle())
                        }
                        .padding()

                        Button(action: {
                            showGeneratePage.toggle()
                        }) {
                            Image("Add")
                                .resizable()
                                .frame(width: 98, height: 98) // Adjust size as needed
                                .foregroundColor(.white)
                        }
                        .padding()
                        .sheet(isPresented: $showGeneratePage) {
                            GeneratePageView(
                                selectedTab: $selectedTab, startGenerateTask: { title, prompt in
                                    generateTaskViewModel.generateSong(with: authViewModel.token!, documentsDirectory: documentsDirectory, title: title, prompt: prompt, filenames: selectedFiles)
                                })
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                        }
                    }
                }

                if let message = generateTaskViewModel.resultMessage {
                    Text(message)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .onAppear {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Failed to set audio session category: \(error)")
                }
                loadSavedAudioFiles()
            }
            .padding()
            .navigationBarHidden(true)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    // Start recording audio
    private func startRecording() {
        let audioFilename = getAudioFileURL()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatFLAC, // WAV uses PCM
            AVSampleRateKey: 44100.0, // Standard sample rate
            AVNumberOfChannelsKey: 1, // Mono
            AVLinearPCMBitDepthKey: 16, // 16-bit audio
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            startTimer()
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    // Stop recording audio
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        loadSavedAudioFiles() // Reload the list after stopping recording
    }

    // Start the recording timer
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingTime += 1
        }
    }

    // Stop the recording timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Format the recording time as "00:00"
    private func timeFormatted(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Play the selected audio file
    private func playAudio(fileName: String) {
        let audioFileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            // Stop any currently playing audio
            if isPlaying {
                audioPlayer?.stop()
                isPlaying = false
                currentlyPlayingFile = nil
            }
            
            // Create a new audio player manager
            audioPlayerManager = AudioPlayerManager {
                isPlaying = false
                currentlyPlayingFile = nil
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.delegate = audioPlayerManager
            audioPlayer?.play()
            isPlaying = true
            currentlyPlayingFile = fileName
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }

    // Get the URL for the audio file to be saved
    private func getAudioFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss a" // Format for date and time
        let dateString = formatter.string(from: Date()) // Get the current date and time as a string
        let fileName = "\(dateString).flac" // Combine the date string with the file extension
        
        return documentsDirectory.appendingPathComponent(fileName)
    }

    // Load saved audio files from local storage
    private func loadSavedAudioFiles() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            recordedFiles = files.filter { $0.pathExtension == "flac" }
                                  .map { $0.lastPathComponent }
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }
    
    // Toggle selection of a file
    private func toggleSelection(fileName: String) {
        if selectedFiles.contains(fileName) {
            selectedFiles.remove(fileName)
        } else {
            selectedFiles.insert(fileName)
        }
    }
    
    // Delete selected files
    private func deleteSelectedFiles() {
        for fileName in selectedFiles {
            let audioFileURL = documentsDirectory.appendingPathComponent(fileName)
            do {
                try fileManager.removeItem(at: audioFileURL)
            } catch {
                print("Error deleting file \(fileName): \(error.localizedDescription)")
            }
        }
        
        // Reload files after deletion
        loadSavedAudioFiles()
        selectedFiles.removeAll() // Reset the selected files
    }
}

struct SoundWaveView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor(Color(hex: "#ffba00"))
                    .frame(width: 4, height: animate ? CGFloat.random(in: 10...30) : 10)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.1), value: animate)
                    .onAppear {
                        animate = true
                    }
            }
        }
        .frame(height: 30)
    }
}
