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
    @AppStorage("NOTIF") var notificationsOn: Bool = false
    
    @State var showAddModal: Bool = false
    @State var addCode: String = ""
    @State var addUnits: String = ""
    @State var addAveragePurchasePrice: String = ""
    @State var showEditModal: Bool = false
    
    var body: some View {
        VStack {
            NavigationStack {
                MainTotalsView()
                MainControlsView()
                List(portfolio.shares, id: \.self.code) { share in
                    ShareDetailsView(share)
                        .sheet(isPresented: $showEditModal) {
                            EditModalView()
                        }
                }
            }
            .sheet(isPresented: $showAddModal, content: {
                AddModalView()
            })
        }
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
                    // TODO: CHECK STOCK CODE AND WAY IMPROVE ERROR CHECKING IN GENERAL
                    if ((Int(addUnits) != nil) && (Double(addAveragePurchasePrice) != nil)) {
                        portfolio.add(code: addCode.uppercased(), units: Int(addUnits)!, averagePurchasePrice: Double(addAveragePurchasePrice)!)
                        saveAndRefresh()
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
    }
    
    fileprivate func EditModalView() -> some View {
        return VStack {
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
                        saveAndRefresh()
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
    
    fileprivate func saveAndRefresh() {
        data = portfolio.encode()
        Task {
            await portfolio.refreshQuotes()
        }
    }
    
    fileprivate func ShareDetailsView(_ share: (code: String, units: Int, averagePurchasePrice: Double)) -> NavigationLink<HStack<TupleView<(Text, Spacer, VStack<TupleView<(Text, Text)>>)>>, TupleView<(HStack<TupleView<(Button<Image>, Button<Image>)>>, Text, Text, Text, Text, Text, Text, Text)>> {
        return NavigationLink {
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
                    saveAndRefresh()
                    // TODO: Dismiss view
                } label: {
                    Image(systemName: "trash.circle")
                }
            }
            Text(share.code)
            Text("\(share.units) units")
            Text("Av. PP $\(share.averagePurchasePrice, specifier: "%.4f")")
            Text("Δ $\(portfolio.getPLFromSymbol(share: share).changeDollar, specifier: "%.2f")")
            Text("Δ \(portfolio.getPLFromSymbol(share: share).changePC, specifier: "%.2f")%")
            Text("± $\(portfolio.getPLFromSymbol(share: share).profitLossDollar, specifier: "%.2f")")
            Text("± \(portfolio.getPLFromSymbol(share: share).profitLossPercent, specifier: "%.2f")%")
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
    }
    
    fileprivate func MainTotalsView() -> HStack<TupleView<(VStack<TupleView<(Text, Text)>>, Spacer, VStack<TupleView<(Text, Text)>>)>> {
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
    
    fileprivate func MainControlsView() -> HStack<TupleView<(Button<Image>, Button<Image>, _ConditionalContent<Button<Image>, Button<Image>>)>> {
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
