import SwiftUI
import CoreData

struct AddMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // MARK: - Optional meal for edit
    var existingMeal: Meal?

    // MARK: - Form Fields
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var mealType: String = "Lunch"
    @State private var selectedIngredients: Set<Ingredient> = []
    @State private var ingredientQuantities: [Ingredient: String] = [:]
    @State private var totalCalories: Double = 0

    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default
    ) private var ingredients: FetchedResults<Ingredient>

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Info")) {
                    TextField("Meal name", text: $name)

                    Picker("Meal type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type)
                        }
                    }

                    TextEditor(text: $notes)
                        .frame(height: 80)
                }

                Section(header: Text("Ingredients")) {
                    ForEach(ingredients, id: \.objectID) { ingredient in
                        VStack(alignment: .leading) {
                            HStack {
                                Button(action: {
                                    toggleSelection(for: ingredient)
                                }) {
                                    HStack {
                                        Image(systemName: selectedIngredients.contains(ingredient) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.blue)
                                        Text(ingredient.name ?? "Unnamed Ingredient")
                                    }
                                }
                            }

                            if selectedIngredients.contains(ingredient) {
                                HStack {
                                    Text("Qty:")
                                    TextField("e.g. 150", text: Binding(
                                        get: { ingredientQuantities[ingredient] ?? "" },
                                        set: { ingredientQuantities[ingredient] = $0 }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: ingredientQuantities[ingredient] ?? "") {
                                        recalculateCalories()
                                    }

                                    Text(ingredient.standardUnit ?? "")
                                        .foregroundColor(.gray)
                                }
                                .padding(.leading, 30)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Total Calories")) {
                    Text("\(totalCalories, specifier: "%.1f") kcal")
                        .font(.headline)
                }

                Button(existingMeal == nil ? "Save Meal" : "Update Meal") {
                    if let meal = existingMeal {
                        updateMeal(meal)
                    } else {
                        saveMeal()
                    }
                }
                .disabled(name.isEmpty || selectedIngredients.isEmpty)
            }
            .navigationTitle(existingMeal == nil ? "Add Meal" : "Edit Meal")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                if let meal = existingMeal {
                    preloadMeal(meal)
                }
            }
        }
    }

    // MARK: - Toggle Ingredient
    private func toggleSelection(for ingredient: Ingredient) {
        if selectedIngredients.contains(ingredient) {
            selectedIngredients.remove(ingredient)
            ingredientQuantities.removeValue(forKey: ingredient)
        } else {
            selectedIngredients.insert(ingredient)
            ingredientQuantities[ingredient] = "1.0"
        }
        recalculateCalories()
    }

    // MARK: - Recalculate Calories
    private func recalculateCalories() {
        totalCalories = selectedIngredients.reduce(0) { total, ingredient in
            let qty = Double(ingredientQuantities[ingredient] ?? "") ?? 0
            let perUnit = ingredient.calories
            let standardQty = ingredient.standardQuantity

            guard standardQty > 0 else { return total }
            return total + qty * (perUnit / standardQty)
        }
    }

    // MARK: - Save New Meal
    private func saveMeal() {
        let meal = existingMeal ?? Meal(context: viewContext)
        meal.name = name
        meal.notes = notes
        meal.timestamp = existingMeal?.timestamp ?? Date()
        meal.mealType = mealType

        // Remove old MealIngredients if editing
        if let existingMealIngredients = meal.mealIngredients as? Set<MealIngredient> {
            for mi in existingMealIngredients {
                viewContext.delete(mi)
            }
        }

        // Add updated MealIngredients
        for ingredient in selectedIngredients {
            let mealIngredient = MealIngredient(context: viewContext)
            mealIngredient.meal = meal
            mealIngredient.ingredient = ingredient
            mealIngredient.quantity = Double(ingredientQuantities[ingredient] ?? "") ?? 0
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ Failed to save meal: \(error.localizedDescription)")
        }
    }


    // MARK: - Update Existing Meal
    private func updateMeal(_ meal: Meal) {
        // Clear existing meal ingredients
        if let currentSet = meal.mealIngredients as? Set<MealIngredient> {
            for mi in currentSet {
                viewContext.delete(mi)
            }
        }
        applyChanges(to: meal)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to update meal: \(error.localizedDescription)")
        }
    }

    // MARK: - Apply Form Values to Meal
    private func applyChanges(to meal: Meal) {
        meal.name = name
        meal.notes = notes
        meal.mealType = mealType

        for ingredient in selectedIngredients {
            let mealIngredient = MealIngredient(context: viewContext)
            mealIngredient.meal = meal
            mealIngredient.ingredient = ingredient
            mealIngredient.quantity = Double(ingredientQuantities[ingredient] ?? "") ?? 0
        }
    }

    // MARK: - Preload Form in Edit Mode
    private func preloadMeal(_ meal: Meal) {
        name = meal.name ?? ""
        notes = meal.notes ?? ""
        mealType = meal.mealType ?? "Lunch"

        let mealIngredients = (meal.mealIngredients as? Set<MealIngredient>)?.sorted(by: { $0.quantity > $1.quantity }) ?? []
        for mi in mealIngredients {
            if let ingredient = mi.ingredient {
                selectedIngredients.insert(ingredient)
                ingredientQuantities[ingredient] = String(format: "%.1f", mi.quantity)
            }
        }
        recalculateCalories()
    }
}
