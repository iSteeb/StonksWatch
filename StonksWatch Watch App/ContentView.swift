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
    @AppStorage("NOTIF") var notificationsOn: Bool = false

    let stocksAPI: KISStocksAPI = KISStocksAPI()
    @State var quotes: [Quote] = []
    @StateObject var portfolio: StockPortfolio = StockPortfolio()
    @State var showAddModal: Bool = false
    @State var addCode: String = ""
    @State var addUnits: String = ""
    @State var addAveragePurchasePrice: String = ""
    @State var showEditModal: Bool = false
    
    var body: some View {
        VStack {
            NavigationStack {
                HStack {
                    VStack {
                        Text("Δ $\(portfolio.getPortfolioPLTotals(quotes: quotes).totalChangeDollar, specifier: "%.2f")")
                            .font(.footnote)
                        Text("Δ \(portfolio.getPortfolioPLTotals(quotes: quotes).totalChangePC, specifier: "%.2f")%")
                            .font(.footnote)
                    }
                    Spacer()
                    VStack {
                        Text("± $\(portfolio.getPortfolioPLTotals(quotes: quotes).totalProfitLossDollar, specifier: "%.2f")")
                            .font(.footnote)
                        Text("± \(portfolio.getPortfolioPLTotals(quotes: quotes).totalProfitLossPercent, specifier: "%.2f")%")
                            .font(.footnote)
                    }
                }
                HStack {
                    Button {
                        Task {
                            await refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                    Button {
                        showAddModal.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    if (notificationsOn) {
                        Button {
                            notificationsOn.toggle()
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        } label: {
                            Image(systemName: "bell.circle")
                        }
                    } else {
                        Button {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { success, error in
                                if success {
                                    notificationsOn.toggle()
                                    let content = UNMutableNotificationContent()
                                    content.title = "Feed the cat"
                                    content.body = "It looks hungry"
                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                                    UNUserNotificationCenter.current().add(request)
                                } else if let error = error {
                                    print(error.localizedDescription)
                                }
                            }
                        } label: {
                            Image(systemName: "bell.slash.circle")
                        }
                    }
                    
                }
                List(portfolio.shares, id: \.self.code) { share in
                    NavigationLink {
                        HStack {
                            Button {
                                showEditModal.toggle()
                                addCode = share.code
                                addUnits = String(share.units)
                                addAveragePurchasePrice = String(share.averagePurchasePrice)
                            } label: {
                                Image(systemName: "pencil.circle")
                            }
                            Button {
                                portfolio.remove(code: share.code)
                                data = portfolio.encode()
                                Task {
                                    await refresh()
                                } // TODO: Dismiss view
                            } label: {
                                Image(systemName: "trash.circle")
                            }
                        }
                        Text(share.code)
                        Text("\(share.units) units")
                        Text("Av. PP $\(share.averagePurchasePrice, specifier: "%.4f")")
                        Text("Δ $\(portfolio.getPLFromSymbol(share: share, quotes: quotes).changeDollar, specifier: "%.2f")")
                        Text("Δ \(portfolio.getPLFromSymbol(share: share, quotes: quotes).changePC, specifier: "%.2f")%")
                        Text("± $\(portfolio.getPLFromSymbol(share: share, quotes: quotes).profitLossDollar, specifier: "%.2f")")
                        Text("± \(portfolio.getPLFromSymbol(share: share, quotes: quotes).profitLossPercent, specifier: "%.2f")%")
                    } label: {
                        HStack {
                            Text(share.code)
                            Spacer()
                            VStack {
                                Text("Δ $\(portfolio.getPLFromSymbol(share: share, quotes: quotes).changeDollar, specifier: "%.2f")")
                                    .font(.footnote)
                                Text("± \(portfolio.getPLFromSymbol(share: share, quotes: quotes).profitLossPercent, specifier: "%.2f")%")
                                    .font(.footnote)
                            }
                        }
                    }
                    .sheet(isPresented: $showEditModal) {
                        VStack {
                            Text(addCode)
                            TextField("\(addUnits) QUANTITY", text: $addUnits)
                                .autocorrectionDisabled()
                            TextField("\(addAveragePurchasePrice) AVERAGE PURCHASE PRICE", text: $addAveragePurchasePrice)
                                .autocorrectionDisabled()
                            HStack {
                                Button {
                                    showEditModal.toggle()
                                    addCode = ""
                                    addUnits = ""
                                    addAveragePurchasePrice = ""
                                } label: {
                                    Image(systemName: "x.circle")
                                }
                                Button {
                                    // TODO: IMPROVE ERROR CHECKING IN GENERAL
                                    if ((Int(addUnits) != nil) && (Double(addAveragePurchasePrice) != nil)) {
                                        portfolio.update(code: addCode, units: Int(addUnits)!, averagePurchasePrice: Double(addAveragePurchasePrice)!)
                                        data = portfolio.encode()
                                        Task {
                                            await refresh()
                                        }
                                        showEditModal.toggle()
                                        addCode = ""
                                        addUnits = ""
                                        addAveragePurchasePrice = ""
                                    }
                                } label: {
                                    Image(systemName: "paperplane.circle")
                                }
                            }
                        }
                        .navigationBarHidden(true)
                    }
                    
                }
            }
            .sheet(isPresented: $showAddModal, content: {
                VStack {
                    TextField("CODE", text: $addCode)
                        .autocorrectionDisabled()
                    TextField("QUANTITY", text: $addUnits)
                        .autocorrectionDisabled()
                    TextField("AVERAGE PURCHASE PRICE", text: $addAveragePurchasePrice)
                        .autocorrectionDisabled()
                    HStack {
                        Button {
                            showAddModal.toggle()
                            addCode = ""
                            addUnits = ""
                            addAveragePurchasePrice = ""
                        } label: {
                            Image(systemName: "x.circle")
                        }
                        Button {
                            // TODO: CHECK STOCK CODE AND WAY IMPROVE ERROR CHECKING IN GENERAL
                            if ((Int(addUnits) != nil) && (Double(addAveragePurchasePrice) != nil)) {
                                portfolio.add(code: addCode.uppercased(), units: Int(addUnits)!, averagePurchasePrice: Double(addAveragePurchasePrice)!)
                                data = portfolio.encode()
                                Task {
                                    await refresh()
                                }
                                showAddModal.toggle()
                                addCode = ""
                                addUnits = ""
                                addAveragePurchasePrice = ""
                            }
                        } label: {
                            Image(systemName: "paperplane.circle")
                        }
                    }
                }
                .navigationBarHidden(true)
            })
            .task {
                await refresh()
            }
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
