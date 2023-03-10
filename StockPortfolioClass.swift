//
//  StockPortfolioClass.swift
//  StonksWatch
//
//  Created by Steven Duzevich on 21/2/2023.
//

import Foundation
import StocksAPI

class StockPortfolio: ObservableObject {
    static let shared = StockPortfolio()
    
    @Published var shares: [(code: String, units: Int, averagePurchasePrice: Double)] = []
    @Published var quotes: [Quote] = []

    let stocksAPI: KISStocksAPI = KISStocksAPI()

    private init() {}
    
    func decode(data: String) -> [(code: String, units: Int, averagePurchasePrice: Double)] {
        if (data == "") {
            return []
        } else {
            let lines = data.components(separatedBy: "|")
            let decodedData = lines.map { line -> (String, Int, Double) in
                let components = line.components(separatedBy: "/")
                return (components[0], Int(components[1])!, Double(components[2])!)
            }
            return decodedData
        }
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
    
    
    func getQuoteFromSymbol(code: String) -> Quote? {
        for i in 0..<quotes.count {
            if (quotes[i].symbol == code) {
                return quotes[i]
            }
        }
        return nil
    }
    
    func refreshQuotes() async {
        do {
            if (shares.count > 0) {
                var quotesString = ""
                for i in 0..<shares.count - 1 {
                    quotesString += shares[i].code
                    quotesString += ","
                }
                quotesString += shares[shares.count - 1].code
                quotes = try await stocksAPI.fetchQuotes(symbols: quotesString)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getPLFromSymbol(share: (code: String, units: Int, averagePurchasePrice: Double)) -> (changeDollar: Double, changePC: Double, profitLossDollar: Double, profitLossPercent: Double) {
        let quote = getQuoteFromSymbol(code: share.code)
        if ((quote) != nil) {
            let totalPurchasePrice: Double = Double(share.units) * share.averagePurchasePrice
            let totalCurrentPrice: Double = Double(share.units) * quote!.regularMarketPrice!
            let totalProfit: Double = totalCurrentPrice - totalPurchasePrice
            let changeSinceYesterday: Double = quote!.regularMarketPrice! - quote!.regularMarketPreviousClose!
            
            return (changeDollar: Double(share.units) * changeSinceYesterday, changePC: changeSinceYesterday / quote!.regularMarketPreviousClose! * 100, profitLossDollar: totalProfit, profitLossPercent: totalProfit / totalPurchasePrice * 100)
        }
        // if this method could return nil, the program should execute regardless with this value as a default value. simpler to return default directly
        return (0.0,0.0,0.0,0.0)
    }
    
    func getPortfolioPLTotals() -> (totalChangeDollar: Double, totalChangePC: Double, totalProfitLossDollar: Double, totalProfitLossPercent: Double){
        var totalSpent: Double = 0.0
        var totalGained: Double = 0.0
        var totalChangeDollar: Double = 0.0
        shares.forEach { share in
            totalSpent += Double(share.units) * share.averagePurchasePrice
            totalGained += getPLFromSymbol(share: share).profitLossDollar
            totalChangeDollar += getPLFromSymbol(share: share).changeDollar
        }
        return (totalChangeDollar, totalChangeDollar / (totalSpent + totalGained - totalChangeDollar) * 100, totalGained, totalGained / totalSpent * 100)
    }
}
