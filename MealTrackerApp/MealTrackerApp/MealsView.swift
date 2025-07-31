import SwiftUI
import CoreData

struct MealsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)],
        animation: .default
    ) private var meals: FetchedResults<Meal>

    @State private var showingAddMeal = false

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
                    }
                    .onDelete(perform: deleteMeal)
                }
                .navigationTitle("Meals")
                .toolbar {
                    EditButton()
                }

                // 💡 Floating Add Button (bottom left)
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
        if let mealIngredients = meal.mealIngredients as? Set<MealIngredient> {
            return mealIngredients.reduce(0) { total, mi in
                guard let ing = mi.ingredient, ing.standardQuantity > 0 else { return total }
                let qty = mi.quantity
                return total + qty * (ing.calories / ing.standardQuantity)
            }
        }
        return 0
    }
}
