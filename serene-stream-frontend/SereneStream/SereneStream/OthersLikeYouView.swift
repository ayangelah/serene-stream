import SwiftUI

struct OthersLikeYouView: View {
    var similarTrackFiles: [URL]?
    var similarTrackNames: [String]?
    var playAudio: (URL) -> Void
    
    var body: some View {
        VStack {
            Text("Others like you ❤️")
                .font(.largeTitle)
                .padding()
            
            if let urls = similarTrackFiles, !urls.isEmpty, let names = similarTrackNames, names.count == urls.count {
                List(urls.indices, id: \.self) { index in
                    Text("\(names[index]). \(urls[index].absoluteString)")
                        .font(.body)
                        .foregroundColor(.blue)
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

            Spacer()
        }
        .navigationTitle("Others Like You")
    }
}
