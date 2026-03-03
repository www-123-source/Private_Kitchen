import SwiftUI
import SwiftData

struct RecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showSearch = false
    @State private var showMyRecipes = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题和搜索
                HStack {
                    Text("私人菜谱")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()

                    Button(action: {
                        showSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // 标签栏
                HStack(spacing: 16) {
                    Button(action: {
                        showMyRecipes = false
                    }) {
                        Text("发现")
                            .foregroundColor(showMyRecipes ? .gray : .orange)
                            .fontWeight(!showMyRecipes ? .bold : .regular)
                    }

                    Button(action: {
                        showMyRecipes = true
                    }) {
                        Text("我的收藏")
                            .foregroundColor(showMyRecipes ? .orange : .gray)
                            .fontWeight(showMyRecipes ? .bold : .regular)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // 内容区域
                if showMyRecipes {
                    MyRecipesView()
                } else {
                    RecipeListView()
                }
            }
            .navigationTitle("私人菜谱")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSearch) {
                RecipeSearchView()
            }
        }
    }
}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeView()
            .modelContainer(for: [Recipe.self, RecipeComment.self])
    }
}