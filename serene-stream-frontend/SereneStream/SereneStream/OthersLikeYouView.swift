import SwiftUI

struct OthersLikeYouView: View {
    var similarTrackFiles: Set<URL>?
    var playAudio: (URL) -> Void?
    
    var body: some View {
        VStack {
            Text("Others like you ❤️")
                .font(.largeTitle)
                .padding()
            
            if let urls = similarTrackFiles, !urls.isEmpty {
                            List(urls.sorted(by: { $0.absoluteString < $1.absoluteString }), id: \.self) { url in
                                Text(url.absoluteString)
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .onTapGesture {
                                        playAudio(url)
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
