import Foundation
import SwiftUI

class GenerateTaskViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var resultMessage: String?

    func generateSong(with token: String, title: String,
                      prompt: String, filenames: Set<String>) {
        isLoading = true
        resultMessage = nil

        // Simulate long-running task
        DispatchQueue.global().async {
            // Mimic network task delay (replace with real API call)
            sleep(5)

            DispatchQueue.main.async {
                self.isLoading = false
                self.resultMessage = "Task completed"
            }
        }
    }
}
