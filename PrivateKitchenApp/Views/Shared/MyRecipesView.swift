import SwiftUI
import SwiftData

struct MyRecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]
    @State private var selectedRecipe: Recipe? = nil

    init() {
        // 初始化查询，获取已收藏的菜谱并按更新时间排序
        _recipes = Query(filter: #Predicate<Recipe> { $0.isCollected },
                       sort: [SortDescriptor(\.updatedAt, order: .reverse)])
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 标题
                HStack {
                    Text("我的收藏")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal)

                // 收藏的菜谱列表
                if recipes.isEmpty {
                    EmptyMyRecipesView()
                } else {
                    ForEach(recipes) { recipe in
                        RecipeCard(recipe: recipe)
                            .onTapGesture {
                                selectedRecipe = recipe
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }
}

struct MyRecipesView_Previews: PreviewProvider {
    static var previews: some View {
        MyRecipesView()
            .modelContainer(for: [Recipe.self, RecipeComment.self])
    }
}

// 空收藏视图
struct EmptyMyRecipesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)

            Text("还没有收藏菜谱")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("去发现一些喜欢的菜谱吧！")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                // 跳转到发现页面
            }) {
                Text("去发现")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
        }
        .padding()
    }
}