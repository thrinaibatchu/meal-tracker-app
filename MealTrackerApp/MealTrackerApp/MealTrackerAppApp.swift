//
//  MealTrackerAppApp.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 7/30/25.
//

import SwiftUI

@main
struct MealTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
