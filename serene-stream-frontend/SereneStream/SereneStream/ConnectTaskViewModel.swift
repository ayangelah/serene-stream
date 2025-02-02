import Foundation

class ConnectTaskViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var resultMessage: String?
    
    func findConnect(with token: String) {
        
    }
}
