import SwiftUI
import CoreData

struct MealsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)],
        animation: .default
    ) private var meals: FetchedResults<Meal>

    @State private var activeSheet: ActiveSheet?
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var previewImage: UIImage? = nil
    @State private var showImagePreview = false

    enum ActiveSheet: Identifiable {
        case add, edit(Meal)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let meal): return meal.objectID.uriRepresentation().absoluteString
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                List {
                    ForEach(meals) { meal in
                        HStack(alignment: .top, spacing: 12) {
                            if let imageData = meal.photo,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

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
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            LongPressGesture().onEnded { _ in
                                if let imageData = meal.photo,
                                   let uiImage = UIImage(data: imageData) {
                                    previewImage = uiImage
                                    showImagePreview = true
                                } else {
                                    print("⚠️ Could not decode image for preview.")
                                }
                            }
                        )
                        .onTapGesture {
                            activeSheet = .edit(meal)
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
                    activeSheet = .add
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
            .sheet(item: $activeSheet) { sheet in
                NavigationView {
                    switch sheet {
                    case .add:
                        AddMealView(editMeal: nil)
                            .environment(\.managedObjectContext, viewContext)
                    case .edit(let meal):
                        AddMealView(editMeal: meal)
                            .environment(\.managedObjectContext, viewContext)
                    }
                }
            }
            .alert("Error", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
            .fullScreenCover(isPresented: $showImagePreview) {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    } else {
                        ProgressView("Loading image...")
                            .foregroundColor(.white)
                    }

                    Button {
                        showImagePreview = false
                        previewImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .padding()
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private func deleteMeal(at offsets: IndexSet) {
        for index in offsets {
            let meal = meals[index]
            viewContext.delete(meal)
        }
        do {
            try viewContext.save()
        } catch {
            deleteErrorMessage = "Failed to delete meal: \(error.localizedDescription)"
            showDeleteError = true
            print(deleteErrorMessage)
        }
    }

    private func mealTotalCalories(_ meal: Meal) -> Double {
        let mealIngredients = (meal.mealIngredients as? Set<MealIngredient>) ?? []
        return mealIngredients.reduce(0) { total, mi in
            guard let ing = mi.ingredient, ing.standardQuantity > 0 else { return total }
            return total + mi.quantity * (ing.calories / ing.standardQuantity)
        }
    }
}
