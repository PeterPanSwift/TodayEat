import Foundation

/// A stable, typed catalog entry. Prices are illustrative meal budgets, not live quotes.
struct Meal: Identifiable {
    enum ID: String, CaseIterable, Codable {
        case ramen, burger, bibimbap
    }

    enum Cuisine {
        case japanese, american, korean

        var title: LocalizedStringResource {
            switch self {
            case .japanese: "日式料理"
            case .american: "美式料理"
            case .korean: "韓式料理"
            }
        }
    }

    let id: ID
    let name: LocalizedStringResource
    let englishName: String
    let imageName: String
    let cuisine: Cuisine
    let priceRange: ClosedRange<Int>
    let flavor: LocalizedStringResource
    let mood: LocalizedStringResource
    let story: LocalizedStringResource
    let number: String

    var budget: String { "NT$ \(priceRange.lowerBound)–\(priceRange.upperBound)" }

    static let catalog: [Meal] = [
        Meal(id: .ramen, name: "濃厚豚骨拉麵", englishName: "TONKOTSU RAMEN",
             imageName: "FoodRamen", cuisine: .japanese, priceRange: 220...320,
             flavor: "濃郁・暖心", mood: "一碗暖心的小確幸",
             story: "讓濃厚湯頭接住今天的疲憊。叉燒、溏心蛋，再加一口麵，幸福其實很簡單。", number: "01"),
        Meal(id: .burger, name: "經典起司漢堡", englishName: "CLASSIC CHEESEBURGER",
             imageName: "FoodBurger", cuisine: .american, priceRange: 180...280,
             flavor: "香濃・多汁", mood: "今天，快樂大口吃",
             story: "融化的起司遇上多汁肉排，配上酥脆薯條。偶爾不想太多，大口享受就對了。", number: "02"),
        Meal(id: .bibimbap, name: "韓式繽紛拌飯", englishName: "COLORFUL BIBIMBAP",
             imageName: "FoodBibimbap", cuisine: .korean, priceRange: 180...260,
             flavor: "微辣・豐富", mood: "把日子拌得有聲有色",
             story: "把鮮蔬、牛肉與蛋黃拌在一起，讓微辣醬香喚醒味蕾。今天就來點繽紛的吧。", number: "03")
    ]

    /// Every draw independently gives all three meals the same chance.
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Meal {
        catalog[Int.random(in: catalog.indices, using: &generator)]
    }
}
