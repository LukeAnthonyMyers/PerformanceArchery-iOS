//
//  GoldGameView.swift
//  Performance Archery
//
//  Created by Luke Myers on 08/01/2025.
//

import SwiftUI

struct GoldGameView: View {
    var body: some View {
        ZStack {
            Color.yellow
            
            Label("Work in progress", systemImage: "smallcircle.circle")
                    .foregroundColor(Color.black)
                    .font(.system(size: 20))
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
    GoldGameView()
}
