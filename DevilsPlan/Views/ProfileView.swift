import SwiftUI
import Clerk

struct ProfileView: View {
    @Environment(Clerk.self) private var clerk
    @State private var totalScore = 0
    @State private var gamesPlayed = 0
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        if let imageUrl = clerk.user?.imageUrl {
                            AsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        Text(clerk.user?.firstName ?? "Player")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(clerk.user?.emailAddresses.first?.emailAddress ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Stats Cards
                    HStack(spacing: 20) {
                        StatCard(title: "Total Score", value: "\(totalScore)", icon: "star.fill")
                        StatCard(title: "Games Played", value: "\(gamesPlayed)", icon: "gamecontroller.fill")
                    }
                    .padding(.horizontal)
                    
                    // Sign Out Button
                    Button(action: {
                        Task {
                            try? await clerk.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                // TODO: Fetch user stats from Convex
                // For now, using sample data
                totalScore = 1500
                gamesPlayed = 3
                isLoading = false
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ProfileView()
        .environment(Clerk.shared)
} 