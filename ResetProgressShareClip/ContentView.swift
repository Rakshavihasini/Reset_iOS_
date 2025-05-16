//
//  ContentView.swift
//  ResetProgressShareClip
//
//  Created by Prasanjit Panda on 05/02/25.
//


import SwiftUI

struct ContentView: View {
    @State private var itemDetails: String = "Loading..."

    var body: some View {
        VStack {
            Text("App Clip Data")
                .font(.title)
                .padding()
            
            Text(itemDetails)
                .padding()
        }
        .onAppear {
            fetchData()
        }
    }

    func fetchData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["title"] as? String {
                DispatchQueue.main.async {
                    self.itemDetails = title
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


#Preview {
    ContentView()
}
