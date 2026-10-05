import SwiftUI

private enum Palette {
    static let paper = Color(red: 0.98, green: 0.965, blue: 0.935)
    static let ink = Color(red: 0.20, green: 0.23, blue: 0.20)
    static let muted = Color(red: 0.48, green: 0.48, blue: 0.43)
    static let red = Color(red: 0.85, green: 0.26, blue: 0.18)
    static let line = Color(red: 0.88, green: 0.86, blue: 0.81)
}

extension EnvironmentValues {
    /// True when the window is too short for the full-size layout, so the meal card
    /// would otherwise disappear behind the draw bar (iPhone Duo unfolded, landscape, …).
    @Entry var isShortCanvas = false
}

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("savedMealIDs") private var savedMealIDs = ""
    @State private var meal = Meal.catalog[0]
    @State private var isDrawing = false
    @State private var drawCount = 0
    @State private var activeSheet: Sheet?
    @State private var canvasHeight: CGFloat = 0

    private enum Sheet: String, Identifiable {
        case collection, about
        var id: String { rawValue }
    }

    private var favorites: Set<String> {
        Set(savedMealIDs.split(separator: ",").map(String.init))
    }

    /// Shorter than a standard iPhone portrait window, so the layout has to tighten up.
    private var isShortCanvas: Bool { canvasHeight > 0 && canvasHeight < 760 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isShortCanvas ? 16 : 25) {
                BrandHeader(savedCount: favorites.count,
                            showCollection: { activeSheet = .collection },
                            showAbout: { activeSheet = .about })
                Introduction()
                VStack(spacing: 14) {
                    HStack {
                        Label(drawCount == 0 ? "今日靈感" : "命運的美味提案", systemImage: "sparkle")
                            .foregroundStyle(Palette.red)
                        Spacer()
                        Text(drawCount == 0 ? "THE DAILY PICK" : "PICK No. \(drawCount.formatted(.number.precision(.integerLength(2))))")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(Palette.muted)
                    }
                    .font(.system(size: 12, weight: .semibold))

                    MealCard(meal: meal, isSaved: favorites.contains(meal.id.rawValue),
                             isDrawing: isDrawing, toggleFavorite: { toggleFavorite(meal.id) })
                        .rotationEffect(.degrees(isDrawing && !reduceMotion ? -2 : 0))
                        .scaleEffect(isDrawing && !reduceMotion ? 0.975 : 1)
                }
                MenuSelection(selectedID: meal.id, isDrawing: isDrawing) { selected in
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        meal = selected
                        drawCount = 0
                    }
                }
                HStack(spacing: 7) {
                    Image(systemName: "heart")
                    Text("好好吃飯，就是好好生活。")
                }
                .font(.system(size: 11))
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 3)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 15)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { canvasHeight = $0 }
        .background(Palette.paper)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DrawBar(isDrawing: isDrawing, hasDrawn: drawCount > 0) { isDrawing = true }
        }
        .task(id: isDrawing) {
            guard isDrawing else { return }
            do {
                if !reduceMotion {
                    for index in 0..<8 {
                        try await Task.sleep(for: .milliseconds(85 + index * 18))
                        meal = Meal.catalog[index % Meal.catalog.count]
                    }
                }
                try Task.checkCancellation()
                var generator = SystemRandomNumberGenerator()
                withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.7)) {
                    meal = Meal.random(using: &generator)
                    drawCount += 1
                    isDrawing = false
                }
            } catch {
                isDrawing = false
            }
        }
        .sensoryFeedback(.success, trigger: drawCount)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .collection:
                CollectionSheet(meals: Meal.catalog.filter { favorites.contains($0.id.rawValue) },
                                remove: toggleFavorite)
            case .about:
                AboutSheet()
            }
        }
        .environment(\.isShortCanvas, isShortCanvas)
        .foregroundStyle(Palette.ink)
        .preferredColorScheme(.light)
        #if os(macOS)
        .frame(minWidth: 390, minHeight: 760)
        #endif
    }

    private func toggleFavorite(_ id: Meal.ID) {
        var updated = favorites
        if updated.contains(id.rawValue) { updated.remove(id.rawValue) }
        else { updated.insert(id.rawValue) }
        savedMealIDs = updated.sorted().joined(separator: ",")
    }
}

private struct BrandHeader: View {
    let savedCount: Int
    let showCollection: () -> Void
    let showAbout: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "fork.knife")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.paper)
                .frame(width: 35, height: 35)
                .background(Palette.red, in: RoundedRectangle(cornerRadius: 12))
                .rotationEffect(.degrees(-8))
            VStack(alignment: .leading, spacing: 1) {
                Text("今天吃什麼").font(.system(size: 15, weight: .bold))
                Text("A LITTLE FOOD FORTUNE")
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .tracking(1.2)
            }
            Spacer()
            Button(action: showAbout) {
                Image(systemName: "info.circle")
                    .font(.system(size: 19))
                    .frame(width: 36, height: 44)
            }
            .accessibilityLabel("關於今天吃什麼")
            Button(action: showCollection) {
                Image(systemName: savedCount > 0 ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.65), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
            }
            .accessibilityLabel("口袋清單，\(savedCount) 道收藏")
        }
        .buttonStyle(.plain)
    }
}

private struct Introduction: View {
    @Environment(\.isShortCanvas) private var isShortCanvas

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 9) {
                Text("選擇困難，交給我。")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Palette.muted)
                VStack(alignment: .leading, spacing: 0) {
                    Text("今天，")
                    Text("吃點開心的。")
                        .foregroundStyle(Palette.red)
                }
                .font(.system(size: isShortCanvas ? 30 : 37, weight: .heavy, design: .serif))
                .tracking(-1.5)
            }
            Spacer(minLength: 0)
            FortuneSeal()
                .rotationEffect(.degrees(12))
                .accessibilityHidden(true)
        }
    }
}

private struct FortuneSeal: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.96, green: 0.84, blue: 0.51))
            Circle().strokeBorder(Palette.ink.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                .padding(5)
            VStack(spacing: 2) {
                Text("GOOD FOOD").font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1)
                Image(systemName: "face.smiling").font(.system(size: 30, weight: .light))
                Text("GOOD MOOD").font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1)
            }
        }
        .frame(width: 83, height: 83)
    }
}

private struct MealCard: View {
    @Environment(\.isShortCanvas) private var isShortCanvas
    let meal: Meal
    let isSaved: Bool
    let isDrawing: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(meal.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: isShortCanvas ? 180 : 245)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Label(meal.cuisine.title, systemImage: "globe.asia.australia")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Palette.paper.opacity(0.95), in: Capsule())
                        .padding(16)
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: toggleFavorite) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isSaved ? Palette.red : Palette.ink)
                            .frame(width: 40, height: 40)
                            .background(Palette.paper.opacity(0.95), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isDrawing)
                    .accessibilityLabel(isSaved ? "取消收藏" : "收藏這道美食")
                    .padding(14)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(meal.mood)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 4))
                        .rotationEffect(.degrees(-3))
                        .padding(16)
                }
                .accessibilityLabel(meal.name)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(meal.englishName)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(1.7)
                            .foregroundStyle(Palette.muted)
                        Text(meal.name)
                            .font(.system(size: isShortCanvas ? 23 : 26, weight: .bold, design: .serif))
                    }
                    Spacer(minLength: 4)
                    Text(meal.number)
                        .font(.system(size: isShortCanvas ? 36 : 43, weight: .light, design: .serif))
                        .foregroundStyle(Palette.line)
                        .accessibilityHidden(true)
                }
                Rectangle().fill(Palette.line).frame(height: 1)
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Label(meal.budget, systemImage: "banknote")
                        Spacer(minLength: 10)
                        Label(meal.flavor, systemImage: "sparkles")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Label(meal.budget, systemImage: "banknote")
                        Label(meal.flavor, systemImage: "sparkles")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.muted)
            }
            .padding(isShortCanvas ? 16 : 20)
            .background(.white.opacity(0.8))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Palette.ink.opacity(0.07), lineWidth: 1))
        .shadow(color: Palette.ink.opacity(0.07), radius: 14, x: 0, y: 8)
        .overlay {
            if isDrawing {
                Text("美味配對中…")
                    .font(.system(size: 15, weight: .bold))
                    .padding(18)
                    .background(Palette.paper, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 12)
            }
        }
    }
}

private struct MenuSelection: View {
    let selectedID: Meal.ID
    let isDrawing: Bool
    let select: (Meal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("今天的美味候選").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("3 道料理・各 ⅓ 好運")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
            }
            HStack(spacing: 10) {
                ForEach(Meal.catalog) { meal in
                    Button { select(meal) } label: {
                        HStack(spacing: 6) {
                            Image(meal.imageName)
                                .resizable().scaledToFill()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            Text(meal.cuisine.title)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 5)
                        .background(selectedID == meal.id ? Color.white : .clear, in: Capsule())
                        .overlay(Capsule().strokeBorder(selectedID == meal.id ? Palette.red.opacity(0.6) : Palette.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(meal.name)
                    .accessibilityAddTraits(selectedID == meal.id ? [.isSelected] : [])
                }
            }
            .disabled(isDrawing)
        }
    }
}

private struct DrawBar: View {
    let isDrawing: Bool
    let hasDrawn: Bool
    let draw: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Button(action: draw) {
                HStack(spacing: 12) {
                    Image(systemName: "dice.fill").font(.system(size: 22))
                        .symbolEffect(.wiggle, options: .repeating, isActive: isDrawing)
                    Text(isDrawing ? "讓好運決定中…" : hasDrawn ? "再抽一次，換個驚喜" : "今天吃什麼？幫我選！")
                        .font(.system(size: 16, weight: .bold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right").font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(minHeight: 59)
                .background(Palette.red, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(PressStyle())
            .disabled(isDrawing)
            .accessibilityIdentifier("drawMealButton")
            Text("少一點猶豫，多一點美味。")
                .font(.system(size: 10))
                .tracking(1)
                .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 13)
        .padding(.bottom, 9)
        .frame(maxWidth: 540)
        .frame(maxWidth: .infinity)
        .background(Palette.paper.opacity(0.98))
        .overlay(alignment: .top) { Rectangle().fill(Palette.line.opacity(0.7)).frame(height: 0.5) }
    }
}

private struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct CollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let meals: [Meal]
    let remove: (Meal.ID) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if meals.isEmpty {
                        ContentUnavailableView("把心動的美味留下來", systemImage: "heart",
                                               description: Text("點一下美食照片上的愛心，\n下次想吃時，就來口袋清單找它。"))
                            .padding(.top, 55)
                    } else {
                        ForEach(meals) { meal in
                            VStack(alignment: .leading, spacing: 12) {
                                MealCard(meal: meal, isSaved: true, isDrawing: false) { remove(meal.id) }
                                Text(meal.story)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.muted)
                                    .lineSpacing(5)
                                    .padding(.horizontal, 6)
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.paper)
            .navigationTitle("口袋清單")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.tint(Palette.red)
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .presentationDragIndicator(.visible)
        .frame(minWidth: 340, minHeight: 450)
    }
}

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    FortuneSeal().frame(maxWidth: .infinity).padding(.top, 25)
                    Text("把選擇，交給一點好運。")
                        .font(.system(size: 27, weight: .bold, design: .serif))
                    Text("從日式拉麵、美式漢堡、韓式拌飯中，隨機抽出今天的美味提案。每次抽選，三道料理的機會都一樣，也可能再次遇見同一道心頭好。")
                        .lineSpacing(6)
                    Text("點照片上的愛心收藏喜歡的料理，或點候選料理先看看。收藏會保存在這台裝置上。")
                        .lineSpacing(6)
                    Divider()
                    Text("圖片為 AI 生成的料理示意圖。價格為新臺幣參考預算，實際售價與餐點內容依店家為準。")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
                .padding(28)
                .frame(maxWidth: 500)
            }
            .background(Palette.paper)
            .navigationTitle("關於這份美味")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.tint(Palette.red)
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .presentationDragIndicator(.visible)
        .frame(minWidth: 340, minHeight: 450)
    }
}

#Preview {
    ContentView()
}
