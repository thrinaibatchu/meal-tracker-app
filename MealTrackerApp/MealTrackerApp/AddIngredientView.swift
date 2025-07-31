import SwiftUI

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var caloriesPerUnit: String = ""

    var body: some View {
        Form {
            Section(header: Text("Ingredient Info")) {
                TextField("Name", text: $name)
                TextField("Calories per 100g", text: $caloriesPerUnit)
                    .keyboardType(.decimalPad)
            }

            Button(action: saveIngredient) {
                Label("Save Ingredient", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(name.isEmpty || Double(caloriesPerUnit) == nil)
        }
        .navigationTitle("Add Ingredient")
    }

    private func saveIngredient() {
        withAnimation {
            let ingredient = Ingredient(context: viewContext)
            ingredient.name = name
            ingredient.caloriesPerUnit = Double(caloriesPerUnit) ?? 0.0

            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Error saving ingredient: \(error.localizedDescription)")
            }
        }
    }
}
