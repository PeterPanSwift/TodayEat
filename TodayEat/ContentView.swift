import SwiftUI
import Playgrounds

struct ContentView: View {
    let foods = ["披薩", "漢堡", "壽司", "牛排", "炸雞"]
    let foodImageNames = ["pizza", "hamburger", "sushi", "steak", "friedChicken"]
    let foodDescriptions = [
        "香濃起司搭配豐富配料，是適合一起分享的美味選擇。",
        "多汁肉排夾入鬆軟麵包，搭配新鮮蔬菜，口感豐富又滿足。",
        "新鮮食材搭配醋飯，味道清爽細緻。",
        "香煎牛排肉質鮮嫩，濃郁肉香讓人回味。",
        "外皮酥脆、肉質多汁，是令人難以抗拒的經典美食。"
    ]
    @State private var selectedFoodIndex = 0
    
    var body: some View {
        VStack {
            Image(foodImageNames[selectedFoodIndex])
                .resizable()
                .scaledToFill()
                .containerRelativeFrame(.horizontal)
                .frame(height: 260)
                .clipped()
            Text(foods[selectedFoodIndex])
                .font(.largeTitle)
            Text(foodDescriptions[selectedFoodIndex])
            Button("今天吃什麼") {
                selectedFoodIndex = .random(in: foods.indices)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}


#Preview {
    ContentView()
}

#Playground {
    let numbers: [Int] = [2, 3, 7]
    let names: [String] = ["Peter", "Wendy"]
    numbers.indices
}
