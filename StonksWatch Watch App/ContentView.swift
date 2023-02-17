//
//  ContentView.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 15/2/2023.
//

import SwiftUI
import StocksAPI

struct ContentView: View {
    let stocksAPI = KISStocksAPI()
    @State private var price = 0.0
    var body: some View {
        VStack {
            Text("\(price)")
            Button {
                Task {
                    let test = try await stocksAPI.fetchQuotes(symbols: "SCG.AX").first?.regularMarketPrice
                    price = test ?? 0.0
                }
            } label: {
                Text("Fetch Price")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
