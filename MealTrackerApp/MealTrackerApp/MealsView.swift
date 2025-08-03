// MARK: - Refactored MealsView.swift
import SwiftUI
import CoreData

struct MealsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)],
        animation: .default
    ) private var meals: FetchedResults<Meal>

    @State private var showingAddMeal = false
    @State private var selectedMealForEdit: Meal? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                List {
                    ForEach(meals) { meal in
                        VStack(alignment: .leading, spacing: 6) {
                            if let imageData = meal.photo,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140)
                                    .clipped()
                                    .cornerRadius(8)
                            }

                            Text(meal.name ?? "Unnamed Meal")
                                .font(.headline)

                            Text(meal.mealType ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Calories: \(mealTotalCalories(meal), specifier: "%.1f") kcal")
                                .font(.subheadline)

                            if let ts = meal.timestamp {
                                Text(ts.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMealForEdit = meal
                            showingAddMeal = true
                        }
                    }
                    .onDelete(perform: deleteMeal)
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Meals")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }

                // Floating Add Button
                Button(action: {
                    selectedMealForEdit = nil
                    showingAddMeal = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal")
                    }
                    .padding(12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                NavigationStack {
                    AddMealView(editMeal: selectedMealForEdit)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }

    private func deleteMeal(at offsets: IndexSet) {
        for index in offsets {
            let meal = meals[index]
            viewContext.delete(meal)
        }
        try? viewContext.save()
    }

    private func mealTotalCalories(_ meal: Meal) -> Double {
        let mealIngredients = (meal.mealIngredients as? Set<MealIngredient>)?.sorted(by: { $0.quantity > $1.quantity }) ?? []

        return mealIngredients.reduce(0) { total, mi in
            guard let ing = mi.ingredient, ing.standardQuantity > 0 else { return total }
            return total + mi.quantity * (ing.calories / ing.standardQuantity)
        }
    }
}
