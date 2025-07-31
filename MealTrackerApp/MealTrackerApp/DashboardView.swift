//
//  DashboardView.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 7/31/25.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("“Quote to inspire, like a friend.”")
                .italic()
                .padding()
            
            Text("Total Calories")
            Text("Day & Week Chart")
            Text("Nutrition Facts")
        }
        .navigationTitle("Dashboard")
    }
}
