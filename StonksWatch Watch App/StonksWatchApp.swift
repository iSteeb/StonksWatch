//
//  StonksWatchApp.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 15/2/2023.
//

import SwiftUI

@main
struct StonksWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor var ApplicationDelegate: ApplicationDelegate
    var portfolio: StockPortfolio = StockPortfolio()
    var body: some Scene {
        WindowGroup {
            ContentView(portfolio: StockPortfolio())
        }
    }
}
