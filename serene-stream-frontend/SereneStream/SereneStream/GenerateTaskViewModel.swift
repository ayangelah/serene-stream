import Foundation
import SwiftUI

class GenerateTaskViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var resultMessage: String?
    
    func generateSong(with token: String, documentsDirectory: URL,
                      title: String, prompt: String, filenames: Set<String>) {
        isLoading = true
        resultMessage = nil

        // Simulate long-running task
        DispatchQueue.global().async { [weak self] in
            Task {
                do {
                    var serverFilenames: Set<String> = []
                    
                    var currentClipsReq = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/clips")!)
                    currentClipsReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    let (currentClipsData, _) = try await URLSession.shared.data(for: currentClipsReq)
                    if let currentClipsJson = try? JSONSerialization.jsonObject(with: currentClipsData) {
                        for fileItem in currentClipsJson as! any Sequence {
                            serverFilenames.insert((fileItem as! Dictionary<String, Any>)["filename"] as! String)
                        }
                    }
                    
                    let filenamesToUpload = filenames.subtracting(serverFilenames)
                    
                    for filenameToUpload in filenamesToUpload {
                        let boundary = "Boundary-\(UUID().uuidString)"
                        var clipUploadRequest = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/clips")!)
                        clipUploadRequest.httpMethod = "POST"
                        clipUploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        var clipBody = Data()
                        let fileData = try! Data(contentsOf: documentsDirectory.appendingPathComponent(filenameToUpload))
                        
                        
                        func appendStringToBody(_ string: String) {
                            if let stringData = string.data(using: .utf8) {
                                clipBody.append(stringData)
                            }
                        }
                        appendStringToBody("--\(boundary)\r\n")
                        appendStringToBody("Content-Disposition: form-data; name=\"file\"; filename=\"\(filenameToUpload)\"\r\n")
                        appendStringToBody("Content-Type: application/octet-stream\r\n\r\n")
                        
                        clipBody.append(fileData)
                        appendStringToBody("\r\n")
                        appendStringToBody("--\(boundary)--\r\n")
                        clipUploadRequest.httpBody = clipBody
                        
                        clipUploadRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                     
                        let (clipUploadResponse, _) = try await URLSession.shared.data(for: clipUploadRequest)
                        
                        print(clipUploadResponse)
                    }
                    
                    DispatchQueue.main.async {
                        self!.isLoading = false
                        self!.resultMessage = "\(filenamesToUpload)"
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
