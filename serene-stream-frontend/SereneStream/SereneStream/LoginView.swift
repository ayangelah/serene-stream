import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToHome = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                Button(action: login) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(
                    destination: HomeView(),
                    isActive: $navigateToHome,
                    label: { EmptyView() }
                )
            }
            .padding()
            .navigationTitle("Login")
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
