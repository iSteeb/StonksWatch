//
//  ApplicationDelegate.swift
//  StonksWatch Watch App
//
//  Created by Steven Duzevich on 23/2/2023.
//

import Foundation
import WatchKit
import UserNotifications

// TODO: Have to handle the task if app is still in foreground ugh

class ApplicationDelegate: NSObject, WKApplicationDelegate {
    var portfolio = StockPortfolio.shared
    
    func applicationDidBecomeActive() {
        print("active") // TODO: figure out how to get refresh function in here, and then replace onchange and onappear with this
        Task {
            await portfolio.refreshQuotes()
            print("refreshed")
        }
    }
    
    func applicationDidEnterBackground() {
        print("inactive") // TODO: check if notifications are on and, if so, schedule a background task as below
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            print("handling")
            
            scheduleNextNotificationTask()
            formNotification()
            
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    func scheduleNextNotificationTask() {
        let calendar = Calendar.current
        let today = Date()
        let midnight = calendar.startOfDay(for: today)
        var target = calendar.date(byAdding: .hour, value: 9, to: midnight)!
        target = calendar.date(byAdding: .minute, value: 7, to: target)!
        // TODO: GET THE DATE THING HAPPENING
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 5), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occured while scheduling background refresh: \(error.localizedDescription)")
            } else {
                print("scheduled")
            }
        }
    }
    
    func formNotification() {
        let content = UNMutableNotificationContent()
        content.title = "\(portfolio.shares)"
        content.body = "\(portfolio.quotes)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
