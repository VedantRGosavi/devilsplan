import SwiftUI
import Clerk

struct HomeView: View {
    @State private var selectedTab = 0
    @Environment(Clerk.self) private var clerk
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GamesListView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(1)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
        .environment(Clerk.shared)
}
