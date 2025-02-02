import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Logo at the top center
                    Image("Logo") // Replace with the name of your logo image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust the size of the logo
                        .padding(.top)
                    
                    
                    // TabView below the logo
                    TabView(selection: $selectedTab) {
                        ClipsView(selectedTab: $selectedTab)
                            .tabItem {
                                Label("Clips", systemImage: "mic.fill")
                            }
                            .tag(0)
                            .environmentObject(authViewModel)
                        
                        TracksView()
                            .tabItem {
                                Label("Tracks", systemImage: "music.note.list")
                            }
                            .tag(1)
                            .environmentObject(authViewModel)
                    }
                    .onAppear {
                        // Set the background color of the tab bar
                        UITabBar.appearance().backgroundColor = UIColor(red: 0.05, green: 0.23, blue: 0.18, alpha: 1.00) // #0c3b2e
                        UITabBar.appearance().unselectedItemTintColor = UIColor.white
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Hide default back button
        .navigationBarTitleDisplayMode(.inline) // Make the title inline
    }
}
