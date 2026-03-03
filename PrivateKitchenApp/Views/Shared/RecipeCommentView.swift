import SwiftUI
import SwiftData

struct RecipeCommentView: View {
    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @State private var newComment = ""
    @State private var showCommentSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("评论")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()

                    Text("\(recipe.commentCount) 条评论")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                // 评论列表
                List {
                    ForEach(recipe.comments) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .listStyle(PlainListStyle())

                // 添加评论
                VStack(alignment: .leading, spacing: 8) {
                    Text("发表评论")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.orange)

                        TextField("写下你的评论...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button(action: {
                            if !newComment.isEmpty {
                                addComment()
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .alert("评论成功", isPresented: $showCommentSuccess) {
                Button("确定") { }
            } message: {
                Text("您的评论已发布")
            }
        }
    }

    private func addComment() {
        // 添加评论逻辑
        newComment = ""
        showCommentSuccess = true
    }
}

struct RecipeCommentView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeCommentView(recipe: Recipe(
            remoteId: "recipe1",
            merchantName: "美味餐厅",
            merchantLocation: "北京市朝阳区",
            name: "番茄炒蛋",
            description: "经典家常菜",
            rating: 4.5,
            commentCount: 23,
            isCollected: true,
            isLiked: false
        ))
        .modelContainer(for: [Recipe.self, RecipeComment.self])
    }
}