import SwiftUI
import SwiftData

struct DishBrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dishes: [Dish]
    @State private var searchText = ""
    @State private var selectedCategory: DishCategory? = nil
    @State private var showCart = false

    init() {
        // 初始化查询，获取所有可用的菜品
        let predicate = #Predicate<Dish> { $0.isAvailable }
        _dishes = Query(filter: predicate, sort: [SortDescriptor(\.name)])
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)

                // 分类筛选
                CategoryFilter(selectedCategory: $selectedCategory)
                    .padding(.horizontal)

                // 菜品列表
                List {
                    ForEach(filteredDishes) { dish in
                        NavigationLink(destination: DishDetailView(dish: dish)) {
                            DishRow(dish: dish)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("点餐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(action: {
                    showCart = true
                }) {
                    Image(systemName: "cart.fill")
                        .foregroundColor(.orange)
                }
            }
            .sheet(isPresented: $showCart) {
                CartView()
            }
        }
    }

    // 根据搜索文本和分类筛选菜品
    private var filteredDishes: [Dish] {
        var filtered = dishes

        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { dish in
                dish.name.localizedCaseInsensitiveContains(searchText) ||
                dish.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 按分类筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        return filtered
    }
}

struct DishBrowseView_Previews: PreviewProvider {
    static var previews: some View {
        DishBrowseView()
            .modelContainer(for: [Dish.self])
    }
}

// 搜索栏组件
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("搜索菜品...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// 分类筛选组件
struct CategoryFilter: View {
    @Binding var selectedCategory: DishCategory?

    var body: some View {
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
                ForEach(DishCategory.allCases, id: \.self) { category in
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
    }
}

// 菜品行组件
struct DishRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            // 菜品图片
            if let imageData = dish.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 菜品名称
                Text(dish.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                // 菜品描述
                Text(dish.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // 价格和分类
                HStack {
                    Text("$\(dish.price, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Spacer()

                    Text(dish.category.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // 添加按钮
            Button(action: {
                // 添加到购物车的逻辑
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
    }
}