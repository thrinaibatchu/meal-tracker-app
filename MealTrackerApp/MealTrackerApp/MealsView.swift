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
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var previewImage: UIImage? = nil
    @State private var showImagePreview = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                List {
                    ForEach(meals) { meal in
                        VStack(alignment: .leading, spacing: 6) {
                            if let imageData = meal.photo,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onLongPressGesture {
                                        previewImage = uiImage
                                        showImagePreview = true
                                    }
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
              .sheet(item: $selectedMealForEdit) { meal in
                  NavigationView {
                      AddMealView(editMeal: meal)
                          .environment(\.managedObjectContext, viewContext)
                  }
              }
              .sheet(isPresented: $showingAddMeal) {
                  NavigationView {
                      AddMealView(editMeal: nil)
                          .environment(\.managedObjectContext, viewContext)
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
                      }
                      Button {
                          showImagePreview = false
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
        let mealIngredients = (meal.mealIngredients as? Set<MealIngredient>)?.sorted(by: { $0.quantity > $1.quantity }) ?? []

        return mealIngredients.reduce(0) { total, mi in
            guard let ing = mi.ingredient, ing.standardQuantity > 0 else { return total }
            return total + mi.quantity * (ing.calories / ing.standardQuantity)
        }
    }
}
