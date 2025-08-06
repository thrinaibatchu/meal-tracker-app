import Foundation

struct NutritionSuggestion: Identifiable, Hashable {
    let id: String
    let name: String
}

struct NutritionInfo {
    let name: String
    let calories: Double
    let quantity: Double
    let unit: String
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double
    let servingSize: String?
    let brand: String?
    let upc: String?
}

final class NutritionService {
    // Replace with your Nutritionix credentials
    private let appId = "YOUR_APP_ID"
    private let apiKey = "YOUR_API_KEY"

    func searchIngredients(query: String) async throws -> [NutritionSuggestion] {
        guard !query.isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://trackapi.nutritionix.com/v2/search/instant?query=\(encoded)") else {
            return []
        }

        var request = URLRequest(url: url)
        request.addValue(appId, forHTTPHeaderField: "x-app-id")
        request.addValue(apiKey, forHTTPHeaderField: "x-app-key")
        request.addValue("en_US", forHTTPHeaderField: "x-remote-user-id")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(InstantResponse.self, from: data)
        return response.common.map { NutritionSuggestion(id: $0.tag_id ?? UUID().uuidString, name: $0.food_name) }
    }

    func fetchNutrition(for suggestion: NutritionSuggestion) async throws -> NutritionInfo {
        guard let url = URL(string: "https://trackapi.nutritionix.com/v2/natural/nutrients") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(appId, forHTTPHeaderField: "x-app-id")
        request.addValue(apiKey, forHTTPHeaderField: "x-app-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["query": suggestion.name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NutrientsResponse.self, from: data)
        guard let food = response.foods.first else {
            throw URLError(.badServerResponse)
        }
        return NutritionInfo(
            name: food.food_name,
            calories: food.nf_calories,
            quantity: food.serving_qty,
            unit: food.serving_unit,
            protein: food.nf_protein,
            fat: food.nf_total_fat,
            carbs: food.nf_total_carbohydrate,
            fiber: food.nf_dietary_fiber ?? 0,
            servingSize: food.serving_weight_grams.map { "\($0) g" },
            brand: food.brand_name,
            upc: food.upc
        )
    }
}

private struct InstantResponse: Codable {
    struct Food: Codable {
        let food_name: String
        let tag_id: String?
    }
    let common: [Food]
}

private struct NutrientsResponse: Codable {
    struct Food: Codable {
        let food_name: String
        let nf_calories: Double
        let nf_protein: Double
        let nf_total_fat: Double
        let nf_total_carbohydrate: Double
        let nf_dietary_fiber: Double?
        let serving_qty: Double
        let serving_unit: String
        let serving_weight_grams: Double?
        let brand_name: String?
        let upc: String?
    }
    let foods: [Food]
}
