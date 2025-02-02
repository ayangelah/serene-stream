import SwiftUI

struct GeneratePageView: View {
    @State private var title: String = ""
    @State private var prompt: String = ""
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: Int // Track the current tab
    
    var startGenerateTask: (String, String) -> Void

    var body: some View {
        VStack {
            // Title Field
            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Prompt Field
            TextField("Prompt", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Spacer()

            // Enter Button
            Button(action: {
                // Navigate to Page B in TabView
                presentationMode.wrappedValue.dismiss()
                //selectedTab = 1
                startGenerateTask(title, prompt)
            }) {
                Text("Enter")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
        .navigationTitle("Generate Prompt")
    }
}
