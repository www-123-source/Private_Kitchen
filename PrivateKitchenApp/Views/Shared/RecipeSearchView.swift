import SwiftUI
import SwiftData

struct RecipeSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: RecipeCategory? = nil
    @State private var recipes: [Recipe] = []
    @State private var showResults = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("搜索菜谱、商家或菜名...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        performSearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)

                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // "全部"选项
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("全部")
                                .foregroundColor(selectedCategory == nil ? .orange : .gray)
                                .fontWeight(selectedCategory == nil ? .bold : .regular)
                        }

                        // 分类选项
                        ForEach(RecipeCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category.displayName)
                                    .foregroundColor(selectedCategory == category ? .orange : .gray)
                                    .fontWeight(selectedCategory == category ? .bold : .regular)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)

                // 搜索结果
                if showResults {
                    if recipes.isEmpty {
                        EmptySearchView()
                    } else {
                        RecipeListView()
                            .environmentObject(self)
                    }
                }
            }
            .navigationTitle("搜索菜谱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("取消") {
                    dismiss()
                }
            }
        }
    }

    private func performSearch() {
        // 模拟搜索结果
        recipes = [
            Recipe(remoteId: "recipe1", merchantName: "美味餐厅", merchantLocation: "北京市朝阳区", name: "番茄炒蛋", description: "经典家常菜", rating: 4.5, commentCount: 23),
            Recipe(remoteId: "recipe2", merchantName: "家常菜馆", merchantLocation: "上海市浦东新区", name: "红烧肉", description: "经典红烧肉", rating: 4.8, commentCount: 45)
        ]
        showResults = true
    }
}

struct RecipeSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeSearchView()
            .modelContainer(for: [Recipe.self, RecipeComment.self])
    }
}

// 空搜索结果视图
struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)

            Text("没有找到相关菜谱")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("尝试其他关键词")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// 菜谱分类枚举
enum RecipeCategory: String, CaseIterable {
    case chinese = "中餐"
    case western = "西餐"
    case dessert = "甜品"
    case drink = "饮品"
    case snack = "小吃"

    var displayName: String {
        switch self {
        case .chinese: return "中餐"
        case .western: return "西餐"
        case .dessert: return "甜品"
        case .drink: return "饮品"
        case .snack: return "小吃"
        }
    }
}