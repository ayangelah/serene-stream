import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            TabView {
                ClipsView()
                    .tabItem {
                        Label("Clips", systemImage: "house.fill")
                    }
                
                TracksView()
                    .tabItem {
                        Label("Tracks", systemImage: "gearshape.fill")
                    }
            }
        }
        .navigationTitle("SereneStream")
        .navigationBarBackButtonHidden(true)
    }
}
