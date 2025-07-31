//
//  MainTabView.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 7/31/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView() // Meals
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }

            IngredientsView() // <- Show ingredients
                .tabItem {
                    Label("Ingredients", systemImage: "leaf")
                }

            DashboardView() // optional
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            LogView() // optional
                .tabItem {
                    Label("Log", systemImage: "clock")
                }
        }
    }
}
