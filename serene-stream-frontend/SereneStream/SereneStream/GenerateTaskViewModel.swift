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

                    var generateReq = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/generate")!)
                    generateReq.httpMethod = "POST"
                    generateReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    generateReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    let generateReqData = try JSONSerialization.data(withJSONObject: [
                        "filenames": Array(filenames),
                        "prompt": prompt,
                        "title": title
                        ], options: [])

                    generateReq.httpBody = generateReqData

                    var generationKey: String = ""
                    let (generateReqResponse, _) = try await URLSession.shared.data(for: generateReq)
                    if let generateReqResponseJson = try? JSONSerialization.jsonObject(with: generateReqResponse) {
                        generationKey = (generateReqResponseJson as! Dictionary<String, Any>)["generation_key"] as! String
                    }

                    if generationKey.isEmpty {
                        DispatchQueue.main.async {
                            self!.isLoading = false
                            self!.resultMessage = "Error: No generation key obtained!"
                        }
                        return
                    }

                    var generationComplete: Bool = false
                    while !generationComplete {
                        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)

                        var generationStatusReq = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/generateStatus/\(generationKey)")!)
                        generationStatusReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                        let (generationStatusData, _) = try await URLSession.shared.data(for: generationStatusReq)
                        if let generationStatusJson = try? JSONSerialization.jsonObject(with: generationStatusData) {
                            generationComplete = (generationStatusJson as! Dictionary<String, Any>)["ready"] as! Bool
                        }
                    }

                    var generationResultReq = URLRequest(url: URL(string: "https://serene-stream-api.vercel.app/generateResult/\(generationKey)")!)
                    generationResultReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    let (generationResultData, generationResultResponse) = try await URLSession.shared.data(for: generationResultReq)

                    var fileURL: URL = documentsDirectory
                    if let httpResponse = generationResultResponse as? HTTPURLResponse,
                       let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String,
                       let filename = contentDisposition.components(separatedBy: "filename=").last?.trimmingCharacters(in: .whitespacesAndNewlines) {

                        // Create the destination URL
                        fileURL = documentsDirectory.appendingPathComponent(filename)

                        // Write the file
                        try generationResultData.write(to: fileURL)
                     }


                    DispatchQueue.main.async {
                        self!.isLoading = false
                        self!.resultMessage = "\(fileURL)"
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
