import SwiftUI
import CoreData

struct IngredientsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>

    var body: some View {
        NavigationView {
            List {
                ForEach(ingredients) { ingredient in
                    VStack(alignment: .leading) {
                        Text(ingredient.name ?? "Unnamed Ingredient")
                            .font(.headline)
                        Text("\(ingredient.name ?? "Unnamed") • \(ingredient.calories, specifier: "%.0f") cal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Ingredients")
        }
    }
}
