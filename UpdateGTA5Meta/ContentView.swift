//
//  ContentView.swift
//  UpdateGTA5Meta
//
//  Created by Alexey Vorobyov on 15.04.2025.
//

import SwiftUI

struct ContentView: View {
    @State var viewModel = ContentViewModel()
    
    var body: some View {
        Button (
            action: {
                viewModel.doTheHarlrmShake()
            },
            label: {
                ZStack {
                    Circle()
                        .shadow(radius: 10)
                    Text("Пыщь")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                .frame(width: 150, height: 150)
            }
        )
    }
}

#Preview {
    ContentView()
}
