//
//  ContentView.swift
//  
//
//  Created by Thrinai Batchu on 7/30/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var mealName: String = ""
    @State private var ingredients: String = ""
    @State private var steps: String = ""
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var mealImage: Image? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Image Picker
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack {
                            if let image = mealImage {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                    .overlay(Text("Tap to select a photo"))
                            }
                        }
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                mealImage = Image(uiImage: uiImage)
                            }
                        }
                    }

                    // Meal Name
                    TextField("Meal Name", text: $mealName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Ingredients
                    Text("Ingredients")
                        .font(.headline)
                    TextEditor(text: $ingredients)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))

                    // Steps
                    Text("Preparation Steps")
                        .font(.headline)
                    TextEditor(text: $steps)
                        .frame(height: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))

                    // Preview Section
                    if !mealName.isEmpty || mealImage != nil {
                        Divider()
                        Text("📋 Preview").font(.title3.bold())
                        if let image = mealImage {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                        }
                        Text("🍽 \(mealName)").font(.headline)
                        if !ingredients.isEmpty {
                            Text("🧂 Ingredients:\n\(ingredients)").padding(.top, 4)
                        }
                        if !steps.isEmpty {
                            Text("🧑‍🍳 Steps:\n\(steps)").padding(.top, 4)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add a Meal")
        }
    }
}
