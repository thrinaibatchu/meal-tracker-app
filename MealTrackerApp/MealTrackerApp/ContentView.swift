//
//  ContentView.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 7/30/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var showingAddMeal = false
    @State private var showingOptions = false
    @State private var showingAddIngredient = false

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)],
        animation: .default)
    private var meals: FetchedResults<Meal>

    var body: some View {
        NavigationView {
            ZStack {
                if meals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No meals logged yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(meals, id: \.self) { meal in
                                MealCardView(meal: meal) {
                                    deleteMeal(meal)
                                }.padding(.horizontal)
                            }

                        }.padding(.top)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingOptions = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.accentColor)
                                .shadow(radius: 4)
                        }
                        .padding()
                        .confirmationDialog("Choose an action", isPresented: $showingOptions) {
                            Button("Add Meal") {
                                showingAddMeal = true
                            }
                            Button("Add Ingredient") {
                                showingAddIngredient = true
                            }
                            Button("Cancel", role: .cancel) { }
                        }

                        .padding()
                    }
                }
            }
            .navigationTitle("Meal Tracker")
            .sheet(isPresented: $showingAddMeal) {
                NavigationStack {
                    AddMealView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                NavigationStack {
                    Text("🔧 AddIngredientView Coming Soon!")
                        .font(.title2)
                        .padding()
                }
            }
        }
    }

    private func openAddMealForm() {
        showingAddMeal = true
    }
    
    private func deleteMeal(_ meal: Meal) {
        withAnimation {
            viewContext.delete(meal)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Failed to delete meal: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct MealCardView: View {
    let meal: Meal
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 🖼 Image
            if let imageData = meal.photo, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(10)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 180)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }

            // 📝 Meal Info
            Text(meal.name ?? "Untitled Meal")
                .font(.headline)

            if let type = meal.mealType {
                Text(type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(meal.notes ?? "")
                .font(.body)

            if let timestamp = meal.timestamp {
                Text(itemFormatter.string(from: timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Meal", systemImage: "trash")
            }
        }
    }
}





private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
