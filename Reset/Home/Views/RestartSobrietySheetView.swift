//
//  RestartSobrietySheetView.swift
//  Reset
//
//  Created by Prasanjit Panda on 13/02/25.
//


import SwiftUI

struct RestartSobrietySheetView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.brown)
            
            Text("It's Okay to Restart")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Every journey has its ups and downs. The important thing is that you're trying. Take it one day at a time!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            }) {
                Text("Got it")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brown)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}
