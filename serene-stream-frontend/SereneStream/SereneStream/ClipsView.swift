import SwiftUI
import AVFoundation

struct ClipsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var generateTaskViewModel = GenerateTaskViewModel()
    
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var recordedFiles: [String] = []
    @State private var selectedFiles: Set<String> = [] // Track selected files for deletion/generation
    @State private var showGeneratePage = false
    @Binding var selectedTab: Int // Track the current tab

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
                // List of recorded audio files with checkboxes
                List(recordedFiles, id: \.self, selection: $selectedFiles) { fileName in
                    HStack {
                        // Checkbox for selecting the file
                        Image(systemName: selectedFiles.contains(fileName) ? "checkmark.square" : "square")
                            .onTapGesture {
                                toggleSelection(fileName: fileName)
                            }
                        
                        Text(fileName)
                        Spacer()
                        
                        // Play button for each audio file
                        Button("Play") {
                            playAudio(fileName: fileName)
                        }
                        .padding(.leading, 8)
                    }
                }

                Spacer()

                // Record Button
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                // Delete Button
                if !selectedFiles.isEmpty {
                    Button(action: {
                        deleteSelectedFiles()
                    }) {
                        Text("Delete Selected")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                // Generate Button
                Button(action: {
                    showGeneratePage.toggle()
                }) {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .sheet(isPresented: $showGeneratePage) {
                    GeneratePageView(
                        selectedTab: $selectedTab, startGenerateTask: { title, prompt in
                            generateTaskViewModel.generateSong(with: authViewModel.token!, title: title, prompt: prompt, filenames: selectedFiles
                            )
                        })
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
            .navigationTitle("ClipsView")
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
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    // Stop recording audio
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        loadSavedAudioFiles() // Reload the list after stopping recording
    }

    // Play the selected audio file
    private func playAudio(fileName: String) {
        let audioFileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.play()
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
