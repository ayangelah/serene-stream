//import SwiftUI
//
//struct HomeView: View {
//    @EnvironmentObject var authViewModel: AuthViewModel
//    @State private var selectedTab = 0
//
//    var body: some View {
//        NavigationView {
//            TabView(selection: $selectedTab) {
//                ClipsView(selectedTab: $selectedTab)
//                    .tabItem {
//                        Label("Clips", systemImage: "house.fill")
//                    }
//                    .tag(0)
//                    .environmentObject(authViewModel)
//
//                TracksView()
//                    .tabItem {
//                        Label("Tracks", systemImage: "gearshape.fill")
//                    }
//                    .tag(1)
//            }
//        }
//        .navigationBarBackButtonHidden(true)
//    }
//}


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
            }
        }
        .navigationBarBackButtonHidden(true) // Hide default back button
        .navigationBarTitleDisplayMode(.inline) // Make the title inline
    }
}
