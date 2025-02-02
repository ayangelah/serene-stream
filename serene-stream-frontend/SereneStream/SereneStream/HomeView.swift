import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                ClipsView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Clips", systemImage: "house.fill")
                    }
                    .tag(0)
                    .environmentObject(authViewModel)
                
                TracksView()
                    .tabItem {
                        Label("Tracks", systemImage: "gearshape.fill")
                    }
                    .tag(1)
            }
        }
        .navigationTitle("SereneStream")
        .navigationBarBackButtonHidden(true)
    }
}
