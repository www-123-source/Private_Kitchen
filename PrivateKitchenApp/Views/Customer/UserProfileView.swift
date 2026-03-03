import SwiftUI
import SwiftData

struct UserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showSettings = false
    @State private var showLogoutConfirm = false
    @State private var user: FamilyMember? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 用户头像和基本信息
                VStack(spacing: 16) {
                    // 头像
                    if let avatarData = user?.avatar, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.orange)
                    }

                    // 用户名和角色
                    VStack(alignment: .center, spacing: 4) {
                        Text(user?.name ?? "用户名")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(userRoleDisplay)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 40)

                // 统计信息
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatCard(title: "累计订单", value: "12", icon: "doc.text")
                        StatCard(title: "收藏菜谱", value: "8", icon: "heart")
                    }

                    HStack(spacing: 16) {
                        StatCard(title: "家庭积分", value: "1560", icon: "gift")
                        StatCard(title: "消费金额", value: "$856", icon: "dollarsign.circle")
                    }
                }
                .padding(.horizontal)

                // 功能按钮
                VStack(spacing: 12) {
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                            Text("设置")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    Button(action: {
                        // 同步设置
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                            Text("数据同步")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    Button(action: {
                        showLogoutConfirm = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.white)
                            Text("退出登录")
                                .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
            .sheet(isPresented: $showSettings) {
                UserProfileSettingsView()
            }
            .alert("确认退出", isPresented: $showLogoutConfirm) {
                Button("取消", role: .cancel) { }
                Button("确认退出", role: .destructive) {
                    // 退出登录逻辑
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .onAppear(perform: loadUserData)
        }
    }

    // 用户角色显示
    private var userRoleDisplay: String {
        switch user?.role {
        case .admin:
            return "厨房管理员"
        case .member:
            return "家庭成员"
        case .none:
            return "未知角色"
        }
    }

    // 加载用户数据
    private func loadUserData() {
        // 模拟加载当前用户数据
        user = FamilyMember(name: "张三", role: .member)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
            .modelContainer(for: [FamilyMember.self])
    }
}

// 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.title2)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}