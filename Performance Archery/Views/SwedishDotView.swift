//
//  SwedishDotView.swift
//  Performance Archery
//
//  Created by Luke Myers on 18/01/2025.
//

import SwiftUI

struct SwedishDotView: View {
    @State var spots: UInt
    
    @State private var score: Int = 0
    @State private var spot: UInt = 1
    
    var body: some View {
        Text("\(score)")
            .font(.system(size: 150))
        
        Spacer()
        
        VStack {
            Text("Spot \(spot)")
                .font(.system(size: 50))
            
            HStack {
                Button(action: {
                    score += 1
                    if spot == spots {
                        spot = 1
                    } else {
                        spot += 1
                    }
                }) {
                    Label("Closer", systemImage: "plus")
                }
            }
            
            HStack {
                Button(action: {
                    if spot == spots {
                        spot = 1
                    } else {
                        spot += 1
                    }
                }) {
                    Label("Too close to call", systemImage: "questionmark")
                }
            }
            
            HStack {
                Button(action: {
                    score -= 1
                    if spot == spots {
                        spot = 1
                    } else {
                        spot += 1
                    }
                }) {
                    Label("Further", systemImage: "minus")
                }
            }
        }
        
        Spacer()
    }
}

#Preview {
    SwedishDotView(spots: 3)
}
