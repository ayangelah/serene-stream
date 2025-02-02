import SwiftUI

struct GeneratePageView: View {
    @State private var title: String = ""
    @State private var prompt: String = ""
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: Int
    
    var startGenerateTask: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height:10)
            
            // Heading
            Text("Generate a Song")
                .font(.title)
                .bold()
                .foregroundColor(Color(hex: "#0c3b2e"))
            
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .foregroundColor(Color(hex: "#bb8a52"))
                    .font(.headline)
                
                TextField("My First Song", text: $title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(hex: "#f8faf9"))
                    .foregroundColor(Color(hex: "#9ba19f"))
                    .cornerRadius(20)
            }

            // Prompt Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Prompt")
                    .foregroundColor(Color(hex: "#bb8a52"))
                    .font(.headline)
                
                TextField("Jazz Chill", text: $prompt)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(hex: "#f8faf9"))
                    .foregroundColor(Color(hex: "#9ba19f"))
                    .cornerRadius(20)
            }

            Spacer().frame(height:25)

            // Generate Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
                startGenerateTask(title, prompt)
            }) {
                Text("Generate Track")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(hex: "#6d9773"))
                    .cornerRadius(25)
            }
        }
        .padding()
        .navigationBarHidden(true)
    }
}
