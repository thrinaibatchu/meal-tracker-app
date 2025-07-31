//
//  AddMealView.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 7/30/25.
//

import SwiftUI
import PhotosUI

struct AddMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var mealName = ""
    @State private var ingredients = ""
    @State private var notes = ""
    @State private var mealType = "Lunch"
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil

    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var body: some View {
        Form {
            Section(header: Text("Meal Info")) {
                TextField("Meal Name", text: $mealName)
                Picker("Meal Type", selection: $mealType) {
                    ForEach(mealTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                TextEditor(text: $ingredients)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    .padding(.vertical, 5)
            }

            Section(header: Text("Photo")) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose a Photo", systemImage: "photo")
                }
                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }
            }

            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            }

            Button(action: saveMeal) {
                Label("Save Meal", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Add Meal")
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    self.imageData = data
                }
            }
        }
    }

    private func saveMeal() {
        withAnimation {
            let newMeal = Meal(context: viewContext)
            newMeal.name = mealName
            newMeal.ingredients = ingredients
            newMeal.notes = notes
            newMeal.mealType = mealType
            newMeal.timestamp = Date()
            newMeal.photo = imageData

            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Failed to save: \(error.localizedDescription)")
            }
        }
    }
}
