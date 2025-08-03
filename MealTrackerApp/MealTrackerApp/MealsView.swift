import SwiftUI
import CoreData

struct MealsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)],
        animation: .default
    ) private var meals: FetchedResults<Meal>

    @State private var showingAddMeal = false
    @State private var mealToEdit: Meal? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                List {
                    ForEach(meals) { meal in
                        VStack(alignment: .leading, spacing: 4) {
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
                        .contentShape(Rectangle()) // Makes entire row tappable
                        .onTapGesture {
                            mealToEdit = meal
                        }
                    }
                    .onDelete(perform: deleteMeal)
                }
                .navigationTitle("Meals")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }

                // Floating Add Button
                Button(action: {
                    showingAddMeal = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal")
                    }
                    .padding(12)
                    .background(Color.accentColor.opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                }
                .sheet(isPresented: $showingAddMeal) {
                    AddMealView()
                        .environment(\.managedObjectContext, viewContext)
                }

                // Editing Existing Meal
                .sheet(item: $mealToEdit) { meal in
                    AddMealView(existingMeal: meal)
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
