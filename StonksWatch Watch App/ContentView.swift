//
//  ContentView.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 15/2/2023.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject var portfolio = StockPortfolio.shared
    
    @AppStorage("DATA") var data = ""
    
    @State var showNotifModal: Bool = false
    @AppStorage("NOTIF") var notificationsOn: Bool = false
    @AppStorage("NOTIFhr") var notifHR: Int = 0
    @AppStorage("NOTIFmin") var notifMIN: Int = 0
    
    @State var showAddModal: Bool = false
    @State var addCode: String = ""
    @State var addUnits: String = ""
    @State var addAveragePurchasePrice: String = ""
    
    fileprivate func notifTimeModalView() -> some View {
        return VStack {
            HStack {
                Picker("Hour", selection: $notifHR) {
                    ForEach(0..<24) { i in
                        Text("\((i))")
                    }
                }
                Picker("Minute", selection: $notifMIN) {
                    ForEach(0..<60) { i in
                        Text("\((i))")
                    }
                }
            }
            HStack {
                Button {
                    showNotifModal.toggle()
                    notificationsOn.toggle()
                } label: {
                    Image(systemName: "x.circle")
                }
                Button {
                    showNotifModal.toggle()
                } label: {
                    Image(systemName: "checkmark.circle")
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    var body: some View {
        NavigationStack {
            MainTotalsView()
            MainControlsView()
                .sheet(isPresented: $showNotifModal) {
                    notifTimeModalView()
                }
            List(portfolio.shares, id: \.self.code) { share in
                NavigationLink {
                    ShareDetailsView(share: share)
                } label: {
                    HStack {
                        Text(share.code)
                        Spacer()
                        VStack {
                            Text("Δ $\(portfolio.getPLFromSymbol(share: share).changeDollar, specifier: "%.2f")")
                                .font(.footnote)
                            Text("± \(portfolio.getPLFromSymbol(share: share).profitLossPercent, specifier: "%.2f")%")
                                .font(.footnote)
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showAddModal, content: {
            AddModalView()
        })
    }
    
    fileprivate func AddModalView() -> some View {
        return VStack {
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
                    // TODO: Input sanitisation
                    // TODO: Error notification if failed
                    if ((Int(addUnits) != nil) && (Double(addAveragePurchasePrice) != nil)) {
                        portfolio.add(code: addCode.uppercased(), units: Int(addUnits)!, averagePurchasePrice: Double(addAveragePurchasePrice)!)
                        saveAndRefresh()
                        showAddModal.toggle()
                        addCode = ""
                        addUnits = ""
                        addAveragePurchasePrice = ""
                    }
                } label: {
                    Image(systemName: "checkmark.circle")
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    
    fileprivate func saveAndRefresh() {
        data = portfolio.encode()
        Task {
            await portfolio.refreshQuotes()
        }
    }
    
    fileprivate func MainTotalsView() -> some View {
        return HStack {
            VStack {
                Text("Δ $\(portfolio.getPortfolioPLTotals().totalChangeDollar, specifier: "%.2f")")
                    .font(.footnote)
                Text("Δ \(portfolio.getPortfolioPLTotals().totalChangePC, specifier: "%.2f")%")
                    .font(.footnote)
            }
            Spacer()
            VStack {
                Text("± $\(portfolio.getPortfolioPLTotals().totalProfitLossDollar, specifier: "%.2f")")
                    .font(.footnote)
                Text("± \(portfolio.getPortfolioPLTotals().totalProfitLossPercent, specifier: "%.2f")%")
                    .font(.footnote)
            }
        }
    }
    
    fileprivate func MainControlsView() -> some View {
        return HStack {
            Button {
                saveAndRefresh()
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
                    notificationsOn.toggle()
                    showNotifModal.toggle()
                } label: {
                    Image(systemName: "bell.slash.circle")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
