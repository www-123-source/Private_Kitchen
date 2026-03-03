import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]
    @State private var selectedRecipe: Recipe? = nil

    init() {
        // 初始化查询，获取所有菜谱并按评分排序
        _recipes = Query(sort: [SortDescriptor(\.rating, order: .reverse)])
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 菜谱列表
                ForEach(recipes) { recipe in
                    RecipeCard(recipe: recipe)
                        .onTapGesture {
                            selectedRecipe = recipe
                        }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("发现菜谱")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }
}

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView()
            .modelContainer(for: [Recipe.self, RecipeComment.self])
    }
}

// 菜谱卡片组件
struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            // 菜谱图片
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 菜谱名称
                Text(recipe.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // 商家信息
                Text("\(recipe.merchantName) · \(recipe.merchantLocation)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // 评分和评论数
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(recipe.rating, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }

                    Text("·")

                    Text("\(recipe.commentCount) 条评论")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // 收藏按钮
            Button(action: {
                // 收藏/取消收藏逻辑
            }) {
                Image(systemName: recipe.isCollected ? "heart.fill" : "heart")
                    .foregroundColor(recipe.isCollected ? .red : .gray)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}