import SwiftUI

struct OthersLikeYouView: View {
    var similarTrackFiles: [URL]?
    var similarTrackNames: [String]?
    var playAudio: (URL) -> Void
    
    enum Location: String, CaseIterable {
        case Hawaii
        case NewZealand = "New Zealand"
        case California
        case Japan
        case Australia
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height:10)
            
            //Heading
            Text("Others like you 🎵")
                .font(.title)
                .bold()
                .foregroundColor(Color(hex: "#0c3b2e"))
            
            if let urls = similarTrackFiles, !urls.isEmpty, let names = similarTrackNames, names.count == urls.count {
                List(urls.indices, id: \.self) { index in
                    Text("\(names[index]).mp3     ❤️ from \(Location.allCases.randomElement()!.rawValue)")

                        .font(.body).bold()
                        .foregroundColor(Color(hex: "bb8a52"))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .onTapGesture {
                            playAudio(urls[index])
                        }
                }
            } else {
                Text("No similar tracks found.")
                    .foregroundColor(.gray)
                    .padding()
            }

            Spacer().frame(height:25)
        }
        .padding()
        .navigationTitle("Others Like You")
    }
}
