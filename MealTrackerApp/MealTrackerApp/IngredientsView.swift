import SwiftUI
import CoreData

struct IngredientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default
    ) private var ingredients: FetchedResults<Ingredient>

    @State private var showingAddIngredient = false

    var body: some View {
        NavigationView {
            List {
                ForEach(ingredients) { ingredient in
                    HStack {
                        Text(ingredient.name ?? "Unnamed")
                        Spacer()
                        Text("\(ingredient.calories, specifier: "%.0f") cal")
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddIngredient = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(ingredients[index])
        }
        try? viewContext.save()
    }
}
