//
//  ContentView.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 15/2/2023.
//

import SwiftUI
import StocksAPI

class StockPortfolio: ObservableObject {
    @Published var shares = [(code: String, units: Int, averagePurchasePrice: Double)]()

    init() {
        self.shares = []
    }
    
    // inputFormat: "AXE.AX/1500/1.5816|DEG.AX/6000/0.7671|ITM.AX/314/0.000|LKE.AX/2704/0.8548|NVX.AX/1000/3.8295|SCG.AX/10000/2.0282|VCX.AX/900/1.3297"
    func decode(data: String) -> [(code: String, units: Int, averagePurchasePrice: Double)] {
        let lines = data.components(separatedBy: "|")
        let decodedData = lines.map { line -> (String, Int, Double) in
            let components = line.components(separatedBy: "/")
            return (components[0], Int(components[1])!, Double(components[2])!)
        }
        return decodedData
    }
    
    func encode() -> String {
        let encodedData = self.shares.map { line -> String in
            return "\(line.0)/\(line.1)/\(line.2)"
        }
        return encodedData.joined(separator: "|")
    }
    
    func add(code: String, units: Int, averagePurchasePrice: Double) {
        self.shares.append((code, units, averagePurchasePrice))
    }
    
    func remove(code: String) {
        self.shares = self.shares.filter { $0.0 != code }
    }
    
    func update(code: String, units: Int, averagePurchasePrice: Double) {
        self.shares = self.shares.map { line -> (String, Int, Double) in
            if line.0 == code {
                return (code, units, averagePurchasePrice)
            } else {
                return line
            }
        }
    }
    
    func getCode(code: String) -> (String, Int, Double)? {
        return self.shares.first { $0.0 == code }
    }
}

struct ContentView: View {
    
    @AppStorage("DATA") var data = "AXE.AX/1500/1.5816|DEG.AX/6000/0.7671|ITM.AX/314/0.000|LKE.AX/2704/0.8548|NVX.AX/1000/3.8295|SCG.AX/10000/2.0282|VCX.AX/900/1.3297"
    
    let stocksAPI = KISStocksAPI()
    @State var quotes: [Quote] = []
    @StateObject var portfolio = StockPortfolio()

    
    func getQuoteFromSymbol(code: String, quotes: [Quote]) -> Quote? {
        for i in 0..<quotes.count {
            if (quotes[i].symbol == code) {
                return quotes[i]
            }
        }
        return nil
    }
    
    func getPLFromSymbol(share: (code: String, units: Int, averagePurchasePrice: Double), quotes: [Quote]) -> (changeDollar: Double, changePC: Double, profitLossDollar: Double, profitLossPercent: Double)? {
        let quote = getQuoteFromSymbol(code: share.code, quotes: quotes)
        if ((quote) != nil) {
            return nil
        }
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Code")
                    .font(.footnote)
                Spacer()
                Text("Now $")
                    .font(.footnote)
                Spacer()
                Text("Tot ±")
                    .font(.footnote)
            }
            ForEach(portfolio.shares, id: \.self.code) { share in
                HStack {
                    Text(share.code)
                        .font(.footnote)
                    Text("$\(getQuoteFromSymbol(code: share.code, quotes: quotes)?.regularMarketPrice ?? 0.0)")
                        .font(.footnote)
                    Text("$\(Double(share.units) * (getQuoteFromSymbol(code: share.code, quotes: quotes)?.regularMarketPrice ?? 0.0 - share.averagePurchasePrice), specifier: "%.2f")")
                        .font(.footnote)
                }
            }
            Button("Add") {
                portfolio.add(code: "VCX.AX", units: 900, averagePurchasePrice: 1.3297)
                data = portfolio.encode()
            }
            Button("Remove") {
                portfolio.remove(code: "VCX.AX")
                data = portfolio.encode()
            }
            Button("Refresh") {
                Task {
                    do {
                        portfolio.shares = portfolio.decode(data: data)
                        var quotesString = ""
                        for i in 0..<portfolio.shares.count - 1 {
                            quotesString += portfolio.shares[i].code
                            quotesString += ","
                        }
                        quotesString += portfolio.shares[portfolio.shares.count - 1].code
                        quotes = try await stocksAPI.fetchQuotes(symbols: quotesString)
                        print("got new quotes")
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        .task {
            do {
                portfolio.shares = portfolio.decode(data: data)
                var quotesString = ""
                for i in 0..<portfolio.shares.count - 1 {
                    quotesString += portfolio.shares[i].code
                    quotesString += ","
                }
                quotesString += portfolio.shares[portfolio.shares.count - 1].code
                quotes = try await stocksAPI.fetchQuotes(symbols: quotesString)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
