import SwiftUI
import CoreData
import PhotosUI

struct AddMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // MARK: - Optional meal for edit
    var editMeal: Meal?

    // MARK: - Form Fields
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var mealType: String = "Lunch"
    @State private var selectedIngredients: Set<Ingredient> = []
    @State private var ingredientQuantities: [Ingredient: String] = [:]
    @State private var totalCalories: Double = 0
    @State private var mealPhoto: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

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

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo")
                            Text(mealPhoto == nil ? "Select Photo" : "Change Photo")
                        }
                    }
                    if let photo = mealPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(8)
                    }
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

                Button(editMeal == nil ? "Save Meal" : "Update Meal") {
                    if let meal = editMeal {
                        updateMeal(meal)
                    } else {
                        saveMeal()
                    }
                }
                .disabled(name.isEmpty || selectedIngredients.isEmpty)
            }
            .navigationTitle(editMeal == nil ? "Add Meal" : "Edit Meal")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                if let meal = editMeal {
                    preloadMeal(meal)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                if let item = newItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            mealPhoto = image
                        }
                    }
                }
            }
        }
    }

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

    private func recalculateCalories() {
        totalCalories = selectedIngredients.reduce(0) { total, ingredient in
            let qty = Double(ingredientQuantities[ingredient] ?? "") ?? 0
            let perUnit = ingredient.calories
            let standardQty = ingredient.standardQuantity

            guard standardQty > 0 else { return total }
            return total + qty * (perUnit / standardQty)
        }
    }

    private func saveMeal() {
        let meal = Meal(context: viewContext)
        applyChanges(to: meal)
        meal.timestamp = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ Failed to save meal: \(error.localizedDescription)")
        }
    }

    private func updateMeal(_ meal: Meal) {
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

    private func applyChanges(to meal: Meal) {
        meal.name = name
        meal.notes = notes
        meal.mealType = mealType

        if let photo = mealPhoto {
            meal.photo = photo.jpegData(compressionQuality: 0.8)
        }

        for ingredient in selectedIngredients {
            let mealIngredient = MealIngredient(context: viewContext)
            mealIngredient.meal = meal
            mealIngredient.ingredient = ingredient
            mealIngredient.quantity = Double(ingredientQuantities[ingredient] ?? "") ?? 0
        }
    }

    private func preloadMeal(_ meal: Meal) {
        name = meal.name ?? ""
        notes = meal.notes ?? ""
        mealType = meal.mealType ?? "Lunch"

        if let data = meal.photo, let image = UIImage(data: data) {
            mealPhoto = image
        }

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
