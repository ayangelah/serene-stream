import SwiftUI
import Combine
import Foundation

class TrackViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var showOthersLikeYou = false
    private var cancellables = Set<AnyCancellable>()

    // Function to handle the connect action
    func connect(track: Track) {
        guard let url = track.fileURL else { return }

        var request = URLRequest(url: URL(string: "https://your-api-endpoint/connect")!) // Your endpoint here
        request.httpMethod = "POST"

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = url.lastPathComponent
        let fileData = try! Data(contentsOf: url) // Read the file data
        
        // Add the file part to the body
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: audio/mp3\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")

        request.httpBody = body
        
        // Send the request
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error connecting: \(error.localizedDescription)")
                case .finished:
                    break
                }
            }, receiveValue: { data, response in
                // Handle the response if needed, e.g., show playable tracks
                print("Connected successfully")
            })
            .store(in: &cancellables)
    }
}
