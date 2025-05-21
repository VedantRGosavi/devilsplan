import SwiftUI

struct GameDetailView: View {
    let game: Game
    @State private var isGameStarted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AsyncImage(url: URL(string: game.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(height: 200)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(game.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(game.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    StatView(title: "Levels", value: "\(game.levels)")
                    Spacer()
                    StatView(title: "Max Score", value: "\(game.maxScore)")
                }
                .padding(.top, 8)
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                isGameStarted = true
            }) {
                Text("Start Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isGameStarted) {
            NavigationView {
                GameContainerView(game: game)
            }
        }
    }
}

#Preview {
    GameDetailView(game: Game.preview)
} 