import SwiftUI
import CoreData

struct IngredientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default
    ) private var ingredients: FetchedResults<Ingredient>

    @State private var activeIngredient: Ingredient?
    @State private var showingAddNew = false

    var body: some View {
        NavigationView {
            List {
                ForEach(ingredients) { ingredient in
                    HStack {
                        if let imageData = ingredient.image,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Text(emojiForType(ingredient.foodType ?? "Other"))
                                .font(.system(size: 24))
                                .frame(width: 30, height: 30)
                        }

                        VStack(alignment: .leading) {
                            Text(ingredient.name ?? "Unnamed")
                                .font(.headline)
                            if let brand = ingredient.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(ingredient.foodType ?? "Unknown")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeIngredient = ingredient
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeIngredient) { ingredient in
                AddIngredientView(editIngredient: ingredient)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingAddNew) {
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

    func emojiForType(_ type: String) -> String {
        switch type {
        case "Protein": return "🍗"
        case "Carb": return "🍞"
        case "Fat": return "🥑"
        case "Vegetable": return "🥦"
        case "Fruit": return "🍎"
        case "Dairy": return "🧀"
        default: return "🍽️"
        }
    }
}
