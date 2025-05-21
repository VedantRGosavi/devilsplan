import SwiftUI

struct EquationHighLowLobbyView: View {
    @StateObject private var gameService = EquationHighLowGameService()
    @State private var isShowingGame = false
    @State private var isHost = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Equation High-Low")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    Button(action: {
                        isHost = true
                        gameService.startHosting()
                        isShowingGame = true
                    }) {
                        Text("Host Game")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isHost = false
                        gameService.joinGame()
                        isShowingGame = true
                    }) {
                        Text("Join Game")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.7))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .fullScreenCover(isPresented: $isShowingGame) {
            EquationHighLowView()
        }
    }
}

struct EquationHighLowLobbyView_Previews: PreviewProvider {
    static var previews: some View {
        EquationHighLowLobbyView()
    }
} 