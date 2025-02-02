import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToHome = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer().frame(height:20)
                
                // Logo
                Image("Logo") // Make sure the image is in your assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                
                Text("**SereneStream**")
                    .foregroundColor(Color(hex: "#0c3b2e"))
                    .padding(.top, -30)// Dark green color
                
                Spacer().frame(height:10)
                
                // Username Field
                HStack {
                   Image(systemName: "person.fill")
                        .foregroundColor(Color(hex: "#9ba19f"))
                TextField("Username", text: $username)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .padding(.leading,8)
                                }
                                .padding()
                                .frame(height:50)
                                .background(Color(hex: "#f8faf9")) // Light white background
                                .cornerRadius(12)

                                // Password Field
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color(hex: "#9ba19f"))
                                    SecureField("Password", text: $password)
                                        .padding(.leading,8)
                                }
                                .padding()
                                .background(Color(hex: "#f8faf9")) // Light white background
                                .cornerRadius(12)


                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                Button(action: login) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#6d9773")) // Green color
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

                NavigationLink(
                    destination: HomeView(),
                    isActive: $navigateToHome,
                    label: { EmptyView() }
                )
                
                Spacer()
            }
            .padding(.horizontal,32)
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("Login")
            .navigationBarHidden(true)
            .background(Color(hex: "#ffffff"))
        }
    }

    func login() {
        // Clear any previous error messages
        errorMessage = nil

        // Prepare the URL for the API endpoint
        guard let url = URL(string: "https://serene-stream-api.vercel.app/login") else {
            errorMessage = "Invalid URL"
            return
        }

        // Create the request body as JSON
        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to encode request"
            return
        }

        // Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Handle networking error
                    errorMessage = "Request failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    // Handle invalid response
                    errorMessage = "Invalid username or password"
                    return
                }

                guard let data = data else {
                    // Handle missing data
                    errorMessage = "No data received"
                    return
                }

                // Decode the response JSON (assuming a success message or token)
                if let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = responseJSON["token"] as? String, !token.isEmpty {
                    // Navigate to the home page if login succeeds
                    navigateToHome = true
                } else {
                    // Handle incorrect login details
                    errorMessage = "Invalid username or password"
                }
            }
        }.resume() // Start the task
    }

}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255.0
        g = Double((int >> 8) & 0xFF) / 255.0
        b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
