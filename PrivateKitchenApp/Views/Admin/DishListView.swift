import SwiftUI

struct DishListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dishes: [Dish]
    @State private var selectedCategory: DishCategory? = nil
    @State private var showingAddDish = false
    @State private var showingEditDish: Dish? = nil

    var filteredDishes: [Dish] {
        if let category = selectedCategory {
            return dishes.filter { $0.category == category }
        }
        return dishes
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 分类筛选
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryChip(title: "全部", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(DishCategory.allCases, id: \.self) { category in
                                CategoryChip(title: category.displayName, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white.opacity(0.6))

                    // 菜品列表
                    if filteredDishes.isEmpty {
                        EmptyDishState(onAddTap: { showingAddDish = true })
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredDishes) { dish in
                                    DishRow(dish: dish)
                                        .onTapGesture {
                                            showingEditDish = dish
                                        }
                                        .contextMenu {
                                            Button {
                                                showingEditDish = dish
                                            } label: {
                                                Label("编辑", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                deleteDish(dish)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("菜品管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.cream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddDish = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.terracotta)
                    }
                }
            }
            .sheet(isPresented: $showingAddDish) {
                AddEditDishView()
            }
            .sheet(item: $showingEditDish) { dish in
                AddEditDishView(dish: dish)
            }
        }
    }

    private func deleteDish(_ dish: Dish) {
        modelContext.delete(dish)
    }
}

// MARK: - 分类标签
private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.terracotta : AppTheme.terracottaMuted)
                .foregroundStyle(isSelected ? .white : AppTheme.terracotta)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 空状态
private struct EmptyDishState: View {
    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.terracotta.opacity(0.5))
            Text("暂无菜品")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.charcoal)
            Text("点击右上角添加第一道菜")
                .font(.subheadline)
                .foregroundStyle(AppTheme.sage)
            Button(action: onAddTap) {
                Label("添加菜品", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.terracotta)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            Spacer()
        }
    }
}

// MARK: - 菜品行
struct DishRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 16) {
            // 缩略图
            Group {
                if let image = dish.image, let uiImage = UIImage(data: image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(AppTheme.sageLight)
                }
            }
            .frame(width: 72, height: 72)
            .background(
                LinearGradient(
                    colors: [AppTheme.sageLight.opacity(0.4), AppTheme.sage.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 信息
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dish.name)
                        .font(.headline)
                        .fontWeight(.600)
                        .foregroundStyle(AppTheme.charcoal)
                    Spacer()
                    Text("¥\(dish.price, specifier: "%.0f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.terracotta)
                }
                Text(dish.description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.sage)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(dish.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.terracottaMuted)
                        .foregroundStyle(AppTheme.terracotta)
                        .clipShape(Capsule())
                    AvailabilityBadge(isAvailable: dish.isAvailable)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.border)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - 上架状态标签
private struct AvailabilityBadge: View {
    let isAvailable: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isAvailable ? AppTheme.sage : Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)
            Text(isAvailable ? "上架" : "下架")
                .font(.caption2)
                .foregroundStyle(isAvailable ? AppTheme.sage : .secondary)
        }
    }
}

struct DishListView_Previews: PreviewProvider {
    static var previews: some View {
        DishListView()
            .modelContainer(for: [Dish.self])
    }
}
