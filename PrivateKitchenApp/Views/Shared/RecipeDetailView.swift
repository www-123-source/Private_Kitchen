import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @State private var showComments = false
    @State private var newComment = ""
    @State private var showCommentSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 菜谱图片
                if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                }

                // 菜谱信息
                VStack(alignment: .leading, spacing: 12) {
                    // 名称和商家
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("\(recipe.merchantName) · \(recipe.merchantLocation)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // 评分和互动
                    HStack(spacing: 16) {
                        // 评分
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(recipe.rating, specifier: "%.1f")")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        // 点赞
                        Button(action: {
                            // 点赞逻辑
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: recipe.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .foregroundColor(recipe.isLiked ? .blue : .gray)
                                Text("点赞")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }

                        // 收藏
                        Button(action: {
                            // 收藏/取消收藏逻辑
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: recipe.isCollected ? "heart.fill" : "heart")
                                    .foregroundColor(recipe.isCollected ? .red : .gray)
                                Text(recipe.isCollected ? "已收藏" : "收藏")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }

                        Spacer()

                        // 评论数
                        HStack(spacing: 2) {
                            Image(systemName: "message")
                                .foregroundColor(.gray)
                            Text("\(recipe.commentCount) 条评论")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // 菜谱描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("菜谱描述")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(recipe.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }

                // 评论区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("评论")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: {
                            showComments = true
                        }) {
                            Text("查看全部")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }

                    // 最新评论
                    if !recipe.comments.isEmpty {
                        CommentRow(comment: recipe.comments[0])
                    }

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
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(action: {
                showComments = true
            }) {
                Image(systemName: "message")
                    .foregroundColor(.orange)
            }
        }
        .sheet(isPresented: $showComments) {
            RecipeCommentView(recipe: recipe)
        }
        .alert("评论成功", isPresented: $showCommentSuccess) {
            Button("确定") { }
        } message: {
            Text("您的评论已发布")
        }
    }

    private func addComment() {
        // 添加评论逻辑
        newComment = ""
        showCommentSuccess = true
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipe: Recipe(
            remoteId: "recipe1",
            merchantName: "美味餐厅",
            merchantLocation: "北京市朝阳区",
            name: "番茄炒蛋",
            description: "经典家常菜，酸甜可口，营养丰富，做法简单",
            rating: 4.5,
            commentCount: 23,
            isCollected: true,
            isLiked: false
        ))
        .modelContainer(for: [Recipe.self, RecipeComment.self])
    }
}

// 评论行组件
struct CommentRow: View {
    let comment: RecipeComment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(comment.content)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // 评分
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < comment.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}