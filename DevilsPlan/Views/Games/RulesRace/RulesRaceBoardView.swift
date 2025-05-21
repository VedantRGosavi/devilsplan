import SwiftUI

struct RulesRaceBoardView: View {
    @ObservedObject var viewModel: RulesRaceViewModel
    
    private let gridSize = 6
    private let cellSize: CGFloat = 50
    private let offices = [5, 12, 19, 26] // Office positions
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.8)
                
                // Game path
                Path { path in
                    let startX = geometry.size.width * 0.1
                    let startY = geometry.size.height * 0.9
                    let cellWidth = (geometry.size.width - startX * 2) / CGFloat(gridSize - 1)
                    let cellHeight = (geometry.size.height - startY * 0.2) / CGFloat(gridSize - 1)
                    
                    path.move(to: CGPoint(x: startX, y: startY))
                    
                    // Create snake-like path
                    for row in 0..<gridSize {
                        let isRightToLeft = row % 2 == 1
                        let y = startY - CGFloat(row) * cellHeight
                        
                        if isRightToLeft {
                            path.addLine(to: CGPoint(x: geometry.size.width - startX, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: startX, y: y))
                        }
                    }
                }
                .stroke(Color.purple, lineWidth: 3)
                
                // Offices
                ForEach(offices, id: \.self) { position in
                    OfficeView()
                        .position(self.positionForCell(position, in: geometry))
                }
                
                // Players
                ForEach(viewModel.players) { player in
                    PlayerTokenView(player: player)
                        .position(self.positionForCell(player.position, in: geometry))
                }
            }
        }
    }
    
    private func positionForCell(_ cell: Int, in geometry: GeometryProxy) -> CGPoint {
        let startX = geometry.size.width * 0.1
        let startY = geometry.size.height * 0.9
        let cellWidth = (geometry.size.width - startX * 2) / CGFloat(gridSize - 1)
        let cellHeight = (geometry.size.height - startY * 0.2) / CGFloat(gridSize - 1)
        
        let row = cell / gridSize
        let col = cell % gridSize
        
        let isRightToLeft = row % 2 == 1
        let x = isRightToLeft ? 
            geometry.size.width - startX - CGFloat(col) * cellWidth :
            startX + CGFloat(col) * cellWidth
        let y = startY - CGFloat(row) * cellHeight
        
        return CGPoint(x: x, y: y)
    }
}

struct OfficeView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 40, height: 40)
            
            Image(systemName: "building.2.fill")
                .foregroundColor(.white)
                .font(.system(size: 20))
        }
    }
}

struct PlayerTokenView: View {
    let player: Player
    
    var body: some View {
        ZStack {
            Circle()
                .fill(playerColor)
                .frame(width: 30, height: 30)
            
            Text(String(player.name.last!))
                .foregroundColor(.white)
                .font(.caption)
                .bold()
        }
        .overlay(
            Group {
                if player.isInPrison {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                        .offset(y: -20)
                }
            }
        )
    }
    
    private var playerColor: Color {
        switch player.name {
        case "Player 1": return .blue
        case "Player 2": return .green
        case "Player 3": return .orange
        case "Player 4": return .red
        default: return .gray
        }
    }
}

#Preview {
    RulesRaceBoardView(viewModel: RulesRaceViewModel())
        .frame(width: 400, height: 600)
        .background(Color.black)
} 