//
//  GoldGameView.swift
//  Performance Archery
//
//  Created by Luke Myers on 08/01/2025.
//

import SwiftUI

struct GoldGameView: View {
    @State var original: Bool
    
    @State private var score: Int = 0
    @State private var arrows: UInt = 0
    @State private var value: Int = 0
    @State private var bgColor: Color = Color.gray.opacity(0.3)
    
    let buttons = [
        ["X", "10", "9"],
        ["8", "7", "6"],
        ["5", "4", "3"],
        ["2", "1", "M"],
    ]
    
    var body: some View {
        VStack {
            Text("Arrows shot: \(arrows)")
                .font(.title3)
            Spacer()
            Text("\(score)")
                .font(.system(size: 150))
            Spacer()
            
            Grid(horizontalSpacing: 40, verticalSpacing: 25) {
                ForEach(0..<buttons.count, id: \.self) { row in
                    GridRow {
                        ForEach(buttons[row], id: \.self) { number in
                            KeypadButton(text: number, action: {
                                if (number == "X") || (Int(number) ?? 0 > 8) {
                                    value = 1
                                } else if (Int(number) == 8) && original {
                                    value = 0
                                } else {
                                    value = -1
                                }
                                score += value
                                arrows += 1
                            }, background: (row==0) ? Color.yellow : Color.gray.opacity(0.5))
                        }
                    }
                }
            }
            
            Spacer()
        }
        .toolbar {
            Button(action: {
                
            }) {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct KeypadButton: View {
    let text: String
    let action: () -> Void
    let background: Color
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.largeTitle)
                .frame(width:80, height: 80)
                .background(background, in: Circle())
        }
        .tint(.primary)
    }
}

#Preview {
    GoldGameView(original: true)
}
