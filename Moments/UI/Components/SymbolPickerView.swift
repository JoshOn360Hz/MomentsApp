import SwiftUI

struct SymbolPickerView: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss
    
    let symbols = [
        // Common
        "star.fill", "heart.fill", "flag.fill", "bell.fill",
        "calendar", "clock.fill", "gift.fill", "party.popper.fill",
        
        // Events
        "graduationcap.fill", "birthday.cake.fill", "balloon.fill", 
        "trophy.fill", "ticket.fill", "airplane", "suitcase.fill",
        
        // Work & Study
        "briefcase.fill", "pencil.and.list.clipboard", "book.fill",
        "laptopcomputer", "desktopcomputer", "chart.line.uptrend.xyaxis",
        
        // Health & Fitness
        "figure.run", "dumbbell.fill", "heart.text.square.fill",
        "pills.fill", "cross.case.fill",
        
        // Nature & Weather
        "sun.max.fill", "moon.stars.fill", "cloud.sun.fill",
        "snowflake", "leaf.fill", "tree.fill",
        
        // Music & Entertainment
        "music.note", "music.note.list", "tv.fill", "gamecontroller.fill",
        "theatermasks.fill", "film.fill",
        
        // Food & Drink
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill",
        "birthday.cake.fill", "carrot.fill",
        
        // Sports
        "basketball.fill", "football.fill", "baseball.fill",
        "tennis.racket", "figure.skiing.downhill",
        
        // Love & Relationships
        "heart.fill", "heart.circle.fill", "sparkles", "hands.sparkles.fill",
        
        // Home
        "house.fill", "key.fill", "bed.double.fill", "sofa.fill"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(symbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            dismiss()
                        } label: {
                            VStack {
                                Image(systemName: symbol)
                                    .font(.system(size: 28))
                                    .foregroundStyle(selectedSymbol == symbol ? .blue : .primary)
                                    .frame(width: 60, height: 60)
                                    .background {
                                        if selectedSymbol == symbol {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.blue.opacity(0.15))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.regularMaterial)
                                        }
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
