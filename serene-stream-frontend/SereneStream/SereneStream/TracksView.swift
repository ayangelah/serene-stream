import SwiftUI
import UniformTypeIdentifiers

struct TracksView: View {
    @State private var tracks: [Track] = []
    @State private var showOthersLikeYou = false
    @State private var showFilePicker = false
    
    var body: some View {
        VStack {
            List {
                ForEach(tracks) { track in
                    HStack {
                        Text(track.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        // Delete Action
                        Button(role: .destructive) {
                            deleteTrack(track)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        // Connect Action
                        Button {
                            showOthersLikeYou = true
                        } label: {
                            Label("Connect", systemImage: "person.2.circle")
                        }
                        .tint(.blue)
                    }
                }
            }

            Spacer()

            // Add MP3 Track Button
            Button(action: {
                showFilePicker.toggle()
            }) {
                Text("Add MP3 Track")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .sheet(isPresented: $showOthersLikeYou) {
            OthersLikeYouView()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.mp3],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .navigationTitle("Tracks")
    }

    // MARK: - Track Management
    private func deleteTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                let track = Track(id: UUID(), name: url.lastPathComponent, fileURL: url)
                tracks.append(track)
            }
        case .failure(let error):
            print("Error importing file: \(error.localizedDescription)")
        }
    }
}

struct Track: Identifiable {
    let id: UUID
    let name: String
    let fileURL: URL
}
