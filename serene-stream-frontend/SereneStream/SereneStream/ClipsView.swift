import SwiftUI
import AVFoundation

struct ClipsView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var recordedFiles: [String] = []

    private let fileManager = FileManager.default
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    var body: some View {
        VStack {
            // List of recorded audio files
            List(recordedFiles, id: \.self) { fileName in
                HStack {
                    Text(fileName)
                    Spacer()
                    Button("Play") {
                        playAudio(fileName: fileName)
                    }
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

        }
        .onAppear {
            loadSavedAudioFiles()
        }
        .padding()
        .navigationTitle("ClipsView")
    }

    // Start recording audio
    private func startRecording() {
        let audioFilename = getAudioFileURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
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
        return documentsDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
    }

    // Load saved audio files from local storage
    private func loadSavedAudioFiles() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            recordedFiles = files.filter { $0.pathExtension == "m4a" }
                                  .map { $0.lastPathComponent }
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }
}
