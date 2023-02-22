//
//  ContentView.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 15/2/2023.
//

import SwiftUI
import StocksAPI
import UserNotifications

struct ContentView: View {
    @AppStorage("DATA") var data = ""
    
    let stocksAPI = KISStocksAPI()
    @State var quotes: [Quote] = []
    @StateObject var portfolio = StockPortfolio()
    
    var body: some View {
        ScrollView {
            ForEach(portfolio.shares, id: \.self.code) { share in
                HStack {
                    Text(share.code)
                        .font(.footnote)
                    Text("\(portfolio.getPLFromSymbol(share: share, quotes: quotes).changeDollar)")
                        .font(.footnote)
                }
            }
            Text("\(portfolio.getPortfolioPLTotals(quotes: quotes).totalChangeDollar)")
            Text("\(portfolio.getPortfolioPLTotals(quotes: quotes).totalChangePC)")
            Text("\(portfolio.getPortfolioPLTotals(quotes: quotes).totalProfitLossDollar)")
            Text("\(portfolio.getPortfolioPLTotals(quotes: quotes).totalProfitLossPercent)")
            
            Button("Refresh") {
                Task {
                    await refresh()
                }
            }
            Button("QUICKADD") {
                data = "AXE.AX/1500/1.5816|DEG.AX/6000/0.7671|ITM.AX/314/0.000|LKE.AX/2704/0.8548|NVX.AX/1000/3.8295|SCG.AX/10000/2.0282|VCX.AX/10000/1.3297"
                Task {
                    await refresh()
                }
            }
            Button("Notify") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("All set!")
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
            Button("Notify") {
                let content = UNMutableNotificationContent()
                content.title = "Feed the cat"
                content.subtitle = "It looks hungry"
                content.sound = UNNotificationSound.default
                // show this notification five seconds from now
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

                // choose a random identifier
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                // add our notification request
                UNUserNotificationCenter.current().add(request)
            }
        }
        .task {
            await refresh()
        }
    }

    
    fileprivate func refresh() async {
        if (data != "") {
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
