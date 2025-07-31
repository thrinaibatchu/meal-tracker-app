//
//  LogView.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 7/31/25.
//

import SwiftUI

struct LogView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧾 Daily Log")
            Text("Breakfast: items + calories")
            Text("Lunch: items + calories")
            Text("Dinner: items + calories")
            Text("Snack: items + calories")
        }
        .padding()
        .navigationTitle("Log")
    }
}
