//
//  ApplicationDelegate.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 23/2/2023.
//

import Foundation
import WatchKit
import UserNotifications

class ApplicationDelegate: NSObject, WKApplicationDelegate {
    var portfolio = StockPortfolio.shared
    
    func applicationDidBecomeActive() {
        print("app is now active")
        portfolio.shares = portfolio.decode(data: UserDefaults.standard.string(forKey: "DATA") ?? "")
        Task {
            await portfolio.refreshQuotes()
            print("quotes refreshed")
        }
    }
    
    func applicationDidEnterBackground() {
        print("app is now inactive")
        scheduleNextNotificationTask()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
                
            case let bgRefreshTask as WKApplicationRefreshBackgroundTask:
                scheduleNextNotificationTask()
                formNotification()
                print("background refresh executed")

                bgRefreshTask.setTaskCompletedWithSnapshot(false)
                
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func scheduleNextNotificationTask() {
        if (UserDefaults.standard.bool(forKey: "NOTIF")) {
            let nextMarketCloseDate = getNextMarketCloseDate()
            if (nextMarketCloseDate != nil){
                WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: nextMarketCloseDate!, userInfo: nil) { (error: Error?) in
                    if let error = error {
                        print("error occured while scheduling background refresh: \(error.localizedDescription)")
                    } else {
                        print("background refresh scheduled at \(UserDefaults.standard.integer(forKey: "NOTIFhr")):\(UserDefaults.standard.integer(forKey: "NOTIFmin"))")
                    }
                }
            }
        }
    }
    
    func getNextMarketCloseDate() -> Date? {
        // TODO: Improve date selection (i.e. not weekends, timezones, etc.)
        let target = Calendar(identifier: .gregorian).nextDate(after: Date(), matching: DateComponents.init(hour: UserDefaults.standard.integer(forKey: "NOTIFhr"), minute: UserDefaults.standard.integer(forKey: "NOTIFmin")), matchingPolicy: .strict)

        return target
    }
    
    func formNotification() {
        if (UserDefaults.standard.bool(forKey: "NOTIF")) {
            let content = UNMutableNotificationContent()

            content.title = "Market Close Report"
            content.body = "Δ \(portfolio.getPortfolioPLTotals().totalChangePC.rounded())% | ± $\(portfolio.getPortfolioPLTotals().totalProfitLossPercent.rounded())"
            portfolio.shares.forEach { share in
                content.body += " \n\(share.code) | Δ \(portfolio.getPLFromSymbol(share: share).changePC.rounded())%"
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}
