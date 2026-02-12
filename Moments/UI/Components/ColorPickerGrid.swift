import SwiftUI

struct ColorPickerGrid: View {
    @Binding var selectedColorHex: String
    
    let presetColors = [
        ColorOption(name: "Blue", hex: "#007AFF"),
        ColorOption(name: "Purple", hex: "#8E4FE1"),
        ColorOption(name: "Pink", hex: "#FF2D55"),
        ColorOption(name: "Red", hex: "#FF3B30"),
        ColorOption(name: "Orange", hex: "#FF9500"),
        ColorOption(name: "Yellow", hex: "#FFCC00"),
        ColorOption(name: "Green", hex: "#34C759"),
        ColorOption(name: "Teal", hex: "#5AC8FA"),
        ColorOption(name: "Indigo", hex: "#5856D6"),
        ColorOption(name: "Cyan", hex: "#32ADE6"),
        ColorOption(name: "Mint", hex: "#00C7BE"),
        ColorOption(name: "Brown", hex: "#A2845E")
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(presetColors) { colorOption in
                    Button {
                        selectedColorHex = colorOption.hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: colorOption.hex) ?? .blue)
                                .frame(width: 50, height: 50)
                            
                            if selectedColorHex == colorOption.hex {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ColorOption: Identifiable {
    let id = UUID()
    let name: String
    let hex: String
}


struct InlineColorPickerGrid: View {
    @Binding var selectedColorHex: String
    
    let presetColors = [
        ColorOption(name: "Blue", hex: "#007AFF"),
        ColorOption(name: "Purple", hex: "#8E4FE1"),
        ColorOption(name: "Pink", hex: "#FF2D55"),
        ColorOption(name: "Red", hex: "#FF3B30"),
        ColorOption(name: "Orange", hex: "#FF9500"),
        ColorOption(name: "Yellow", hex: "#FFCC00"),
        ColorOption(name: "Green", hex: "#34C759"),
        ColorOption(name: "Teal", hex: "#5AC8FA"),
        ColorOption(name: "Indigo", hex: "#5856D6"),
        ColorOption(name: "Cyan", hex: "#32ADE6"),
        ColorOption(name: "Mint", hex: "#00C7BE"),
        ColorOption(name: "Brown", hex: "#A2845E")
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(presetColors) { colorOption in
                Button {
                    selectedColorHex = colorOption.hex
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: colorOption.hex) ?? .blue)
                            .frame(width: 44, height: 44)
                        
                        if selectedColorHex == colorOption.hex {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

