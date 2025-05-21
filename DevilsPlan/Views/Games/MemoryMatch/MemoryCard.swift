import SwiftUI

struct MemoryCard: Identifiable, Equatable {
    let id: Int
    let content: String
    var isFaceUp = false
    var isMatched = false
    
    static func == (lhs: MemoryCard, rhs: MemoryCard) -> Bool {
        lhs.id == rhs.id
    }
}

struct MemoryCardView: View {
    let card: MemoryCard
    let color: Color
    let action: () -> Void
    
    @State private var animationAmount = 0.0
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                action()
            }
        }) {
            ZStack {
                let base = RoundedRectangle(cornerRadius: 12)
                Group {
                    base.fill(.white)
                    base.strokeBorder(color, lineWidth: 2)
                    Text(card.isFaceUp ? card.content : "")
                        .font(.system(size: 50))
                }
                .opacity(card.isFaceUp ? 1 : 0)
                
                Group {
                    base.fill(color)
                    Image(systemName: "questionmark")
                        .font(.title)
                        .foregroundColor(.white)
                }
                .opacity(card.isFaceUp ? 0 : 1)
            }
            .opacity(card.isMatched ? 0.5 : 1)
            .rotation3DEffect(
                .degrees(animationAmount),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
        }
        .onChange(of: card.isFaceUp) { _, newValue in
            animationAmount += newValue ? 180 : -180
        }
    }
} 