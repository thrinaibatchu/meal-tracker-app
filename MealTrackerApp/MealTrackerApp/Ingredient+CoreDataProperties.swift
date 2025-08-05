//
//  Ingredient+CoreDataProperties.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 8/5/25.
//
//

import Foundation
import CoreData


extension Ingredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ingredient> {
        return NSFetchRequest<Ingredient>(entityName: "Ingredient")
    }

    @NSManaged public var calories: Double
    @NSManaged public var caloriesPerUnit: Double
    @NSManaged public var foodType: String?
    @NSManaged public var image: Data?
    @NSManaged public var name: String?
    @NSManaged public var nutritionFacts: String?
    @NSManaged public var quantityType: String?
    @NSManaged public var standardQuantity: Double
    @NSManaged public var standardUnit: String?
    @NSManaged public var unit: String?
    @NSManaged public var protein: Double
    @NSManaged public var fat: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fiber: Double
    @NSManaged public var servingSize: String?
    @NSManaged public var brand: String?
    @NSManaged public var upc: String?
    @NSManaged public var mealIngredients: NSSet?

}

// MARK: Generated accessors for mealIngredients
extension Ingredient {

    @objc(addMealIngredientsObject:)
    @NSManaged public func addToMealIngredients(_ value: MealIngredient)

    @objc(removeMealIngredientsObject:)
    @NSManaged public func removeFromMealIngredients(_ value: MealIngredient)

    @objc(addMealIngredients:)
    @NSManaged public func addToMealIngredients(_ values: NSSet)

    @objc(removeMealIngredients:)
    @NSManaged public func removeFromMealIngredients(_ values: NSSet)

}

extension Ingredient : Identifiable {

}
