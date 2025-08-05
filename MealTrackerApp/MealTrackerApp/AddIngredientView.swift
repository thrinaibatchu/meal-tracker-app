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

    @State private var protein: String = ""
    @State private var fat: String = ""
    @State private var carbs: String = ""
    @State private var fiber: String = ""
    @State private var servingSize: String = ""
    @State private var brand: String = ""
    @State private var upc: String = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

    let foodTypes = ["Carb", "Protein", "Fat", "Vegetable", "Fruit", "Dairy", "Other"]
    let quantityUnits = ["gram", "oz", "ml", "tbsp", "tsp", "cup"]

    var editIngredient: Ingredient?

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

                Section(header: Text("Macros (optional)")) {
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fiber (g)", text: $fiber)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Additional Info (optional)")) {
                    TextField("Serving Size", text: $servingSize)
                    TextField("Brand", text: $brand)
                    TextField("UPC", text: $upc)
                }

                Section(header: Text("Image (optional)")) {
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(imageData == nil ? "Select Image" : "Change Image", systemImage: "photo.on.rectangle")
                    }

                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(10)
                            .padding(.vertical, 4)

                        Button(role: .destructive) {
                            imageData = nil
                            selectedImage = nil
                        } label: {
                            Label("Remove Image", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }

                Button(editIngredient == nil ? "Save Ingredient" : "Update Ingredient") {
                    validateAndSave()
                }
                .disabled(name.isEmpty || calories.isEmpty || standardQuantity.isEmpty)
            }
            .navigationTitle(editIngredient == nil ? "Add Ingredient" : "Edit Ingredient")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Invalid Input", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: selectedImage) {
                Task {
                    if let item = selectedImage,
                       let data = try? await item.loadTransferable(type: Data.self) {
                        self.imageData = data
                    }
                }
            }
            .onAppear {
                if let ing = editIngredient {
                    name = ing.name ?? ""
                    calories = String(format: "%.0f", ing.calories)
                    standardQuantity = String(format: "%.1f", ing.standardQuantity)
                    standardUnit = ing.standardUnit ?? "gram"
                    foodType = ing.foodType ?? "Other"
                    nutritionFacts = ing.nutritionFacts ?? ""
                    imageData = ing.image
                    protein = ing.protein == 0 ? "" : String(format: "%.1f", ing.protein)
                    fat = ing.fat == 0 ? "" : String(format: "%.1f", ing.fat)
                    carbs = ing.carbs == 0 ? "" : String(format: "%.1f", ing.carbs)
                    fiber = ing.fiber == 0 ? "" : String(format: "%.1f", ing.fiber)
                    servingSize = ing.servingSize ?? ""
                    brand = ing.brand ?? ""
                    upc = ing.upc ?? ""
                }
            }
        }
    }

    private func validateAndSave() {
        guard let caloriesDouble = Double(calories), caloriesDouble >= 0 else {
            alertMessage = "Please enter a valid number for calories."
            showAlert = true
            return
        }

        guard let quantityDouble = Double(standardQuantity), quantityDouble > 0 else {
            alertMessage = "Please enter a valid standard quantity greater than zero."
            showAlert = true
            return
        }

        saveIngredient(calories: caloriesDouble, quantity: quantityDouble)
    }

    private func saveIngredient(calories: Double, quantity: Double) {
        let ingredient = editIngredient ?? Ingredient(context: viewContext)
        ingredient.name = name
        ingredient.calories = calories
        ingredient.standardQuantity = quantity
        ingredient.standardUnit = standardUnit
        ingredient.foodType = foodType
        ingredient.nutritionFacts = nutritionFacts
        ingredient.protein = Double(protein) ?? 0
        ingredient.fat = Double(fat) ?? 0
        ingredient.carbs = Double(carbs) ?? 0
        ingredient.fiber = Double(fiber) ?? 0
        ingredient.servingSize = servingSize.isEmpty ? nil : servingSize
        ingredient.brand = brand.isEmpty ? nil : brand
        ingredient.upc = upc.isEmpty ? nil : upc
        if let data = imageData, let image = UIImage(data: data) {
            ingredient.image = image.resized(to: CGSize(width: 300, height: 300), compressionQuality: 0.7)
        } else {
            ingredient.image = nil
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save ingredient: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
