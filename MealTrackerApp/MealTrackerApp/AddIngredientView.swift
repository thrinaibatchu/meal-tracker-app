import SwiftUI
import CoreData
import PhotosUI

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var standardQuantity: String = ""
    @State private var standardUnit: String = "gram"
    @State private var foodType: String = "Carb"
    @State private var nutritionFacts: String = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?

    let foodTypes = ["Carb", "Protein", "Fat", "Vegetable", "Fruit", "Dairy", "Other"]
    let quantityUnits = ["gram", "oz", "ml", "tbsp", "tsp", "cup"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Info")) {
                    TextField("Name", text: $name)

                    HStack {
                        TextField("Calories", text: $calories)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)

                        Text("per")

                        TextField("Quantity", text: $standardQuantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)

                        Picker("", selection: $standardUnit) {
                            ForEach(quantityUnits, id: \.self) {
                                Text($0)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }

                    Picker("Food Type", selection: $foodType) {
                        ForEach(foodTypes, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("Nutrition Facts (optional)")) {
                    TextEditor(text: $nutritionFacts)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }

                Section(header: Text("Image (optional)")) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Select Image", systemImage: "photo.on.rectangle")
                    }

                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(10)
                    }
                }

                Button("Save Ingredient") {
                    saveIngredient()
                }
                .disabled(name.isEmpty || calories.isEmpty || standardQuantity.isEmpty)
            }
            .navigationTitle("Add Ingredient")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onChange(of: selectedImage) {
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                        self.imageData = data
                    }
                }
            }
        }
    }

    private func saveIngredient() {
        let ingredient = Ingredient(context: viewContext)
        ingredient.name = name
        ingredient.calories = Double(calories) ?? 0
        ingredient.standardQuantity = Double(standardQuantity) ?? 1
        ingredient.standardUnit = standardUnit
        ingredient.foodType = foodType
        ingredient.nutritionFacts = nutritionFacts
        ingredient.image = imageData

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save ingredient: \(error.localizedDescription)")
        }
    }
}
