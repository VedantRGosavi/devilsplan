import SwiftUI

struct CustomRuleView: View {
    @ObservedObject var viewModel: RulesRaceViewModel
    @State private var newRule = ""
    @State private var selectedPlayerIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Custom Rules")
                    .font(.title)
                    .foregroundColor(.white)
                
                // Player selector
                Picker("Select Player", selection: $selectedPlayerIndex) {
                    ForEach(0..<viewModel.players.count, id: \.self) { index in
                        Text(viewModel.players[index].name)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Add new rule
                HStack {
                    TextField("Enter new rule", text: $newRule)
                        .textFieldStyle(RoundedBorderTextStyle())
                        .foregroundColor(.black)
                    
                    Button(action: addRule) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title2)
                    }
                }
                .padding()
                
                // List of current rules
                List {
                    ForEach(viewModel.players[selectedPlayerIndex].personalRules, id: \.self) { rule in
                        Text(rule)
                            .foregroundColor(.white)
                    }
                    .onDelete(perform: deleteRule)
                }
                .listStyle(.plain)
                
                // Done button
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    private func addRule() {
        guard !newRule.isEmpty else { return }
        var player = viewModel.players[selectedPlayerIndex]
        player.personalRules.append(newRule)
        viewModel.players[selectedPlayerIndex] = player
        newRule = ""
    }
    
    private func deleteRule(at offsets: IndexSet) {
        var player = viewModel.players[selectedPlayerIndex]
        player.personalRules.remove(atOffsets: offsets)
        viewModel.players[selectedPlayerIndex] = player
    }
}

#Preview {
    CustomRuleView(viewModel: RulesRaceViewModel())
} 