import Foundation

class ConnectTaskViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var resultMessage: String?
    @Published var similarTrackFiles: [URL]?
    @Published var similarTrackNames: [String]?
    
    func findConnect(with token: String, documentsDirectory: URL, inputTrackURL: URL) {
        isLoading = true
        resultMessage = nil
        similarTrackFiles = []
        similarTrackNames = []
        
        DispatchQueue.global().async { [weak self] in
            Task {
                do {
                    let boundary = "Boundary-\(UUID().uuidString)"
                    var inputTrackUploadRequest = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/connect")!)
                    inputTrackUploadRequest.httpMethod = "POST"
                    inputTrackUploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    var inputTrackBody = Data()
                    let fileData = try! Data(contentsOf: inputTrackURL)


                    func appendStringToBody(_ string: String) {
                        if let stringData = string.data(using: .utf8) {
                            inputTrackBody.append(stringData)
                        }
                    }
                    appendStringToBody("--\(boundary)\r\n")
                    appendStringToBody("Content-Disposition: form-data; name=\"file\"; filename=\"input.mp3\"\r\n")
                    appendStringToBody("Content-Type: application/octet-stream\r\n\r\n")

                    inputTrackBody.append(fileData)
                    appendStringToBody("\r\n")
                    appendStringToBody("--\(boundary)--\r\n")
                    inputTrackUploadRequest.httpBody = inputTrackBody

                    inputTrackUploadRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    let (inputTrackUploadResponse, _) = try await URLSession.shared.data(for: inputTrackUploadRequest)

                    var similarTrackIDs: [String] = []
                    var names: [String] = []
                    if let inputTrackUploadJson = try? JSONSerialization.jsonObject(with: inputTrackUploadResponse) {
                        let topTracks = (inputTrackUploadJson as! Dictionary<String, Any>)["top_3_clips"]
                        for trackItem in topTracks as! any Sequence {
                            similarTrackIDs.append((trackItem as! Dictionary<String, Any>)["track_id"] as! String)
                            
                            names.append((trackItem as! Dictionary<String, Any>)["track_filename"] as! String)
                        }
                    }
                    
                    var fileURLs: [URL] = []
                    for similarTrackId in similarTrackIDs {
                        var similarTrackReq = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/track/\(similarTrackId)")!)
                        similarTrackReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                        let (similarTrackData, similarTrackResponse) = try await URLSession.shared.data(for: similarTrackReq)

                        var fileURL: URL = documentsDirectory
                        if let httpResponse = similarTrackResponse as? HTTPURLResponse,
                           let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String
                            {
                            let filename = UUID().uuidString + ".mp3"
                            // Create the destination URL
                            fileURL = documentsDirectory.appendingPathComponent(filename)

                            // Write the file
                            try similarTrackData.write(to: fileURL)
                            
                            fileURLs.append(fileURL)
                         }
                    }
                    
                    DispatchQueue.main.async {
                        self!.isLoading = false
                        self!.resultMessage = "Success"
                        self!.similarTrackFiles = fileURLs
                        self!.similarTrackNames = names
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self!.isLoading = false
                        self!.resultMessage = "Error: \(error)"
                    }
                }
            }
        }
    }
}
