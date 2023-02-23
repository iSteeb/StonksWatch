//
//  ShareDetailsView.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 23/2/2023.
//

import SwiftUI

struct ShareDetailsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @StateObject var portfolio = StockPortfolio.shared
    
    @AppStorage("DATA") var data = ""
    
    @State var showEditModal: Bool = false
    @State var addUnits: String = ""
    @State var addAveragePurchasePrice: String = ""
    
    var share: (code: String, units: Int, averagePurchasePrice: Double)
    var body: some View {
        VStack {
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "x.circle")
                }
                Button {
                    showEditModal.toggle()
                    addUnits = String(share.units)
                    addAveragePurchasePrice = String(share.averagePurchasePrice)
                } label: {
                    Image(systemName: "pencil.circle")
                }
                Button {
                    portfolio.remove(code: share.code)
                    saveAndRefresh()
                    presentationMode.wrappedValue.dismiss()
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
        }
        .sheet(isPresented: $showEditModal) {
            EditModalView()
        }
    }
    
    fileprivate func saveAndRefresh() {
        data = portfolio.encode()
        Task {
            await portfolio.refreshQuotes()
        }
    }
    
    fileprivate func EditModalView() -> some View {
        return VStack {
            Text(share.code)
            TextField("\(addUnits) QUANTITY", text: $addUnits)
                .autocorrectionDisabled()
            TextField("\(addAveragePurchasePrice) AVERAGE PURCHASE PRICE", text: $addAveragePurchasePrice)
                .autocorrectionDisabled()
            HStack {
                Button {
                    showEditModal.toggle()
                    addUnits = ""
                    addAveragePurchasePrice = ""
                } label: {
                    Image(systemName: "x.circle")
                }
                Button {
                    // TODO: Input sanitisation
                    // TODO: Error notification if failed
                    if ((Int(addUnits) != nil) && (Double(addAveragePurchasePrice) != nil)) {
                        portfolio.update(code: share.code, units: Int(addUnits)!, averagePurchasePrice: Double(addAveragePurchasePrice)!)
                        saveAndRefresh()
                        showEditModal.toggle()
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
}

struct ShareDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ShareDetailsView(share: (code: "VCX.AX", units: 10000, averagePurchasePrice: 1.3728))
    }
}
