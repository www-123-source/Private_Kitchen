import SwiftUI
import SwiftData

struct UserProfileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var userName = ""
    @State private var showEditAvatar = false
    @State private var showChangePassword = false
    @State private var showNotifications = false
    @State private var showAbout = false

    var body: some View {
        NavigationView {
            List {
                // 个人资料设置
                Section(header: Text("个人资料").font(.headline).foregroundColor(.primary)) {
                    // 用户名
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.orange)
                        TextField("用户名", text: $userName)
                    }

                    // 头像
                    Button(action: {
                        showEditAvatar = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.orange)
                            Text("更换头像")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }

                    // 角色
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.orange)
                        Text("角色")
                        Spacer()
                        Text("家庭成员")
                            .foregroundColor(.gray)
                    }
                }

                // 账户安全
                Section(header: Text("账户安全").font(.headline).foregroundColor(.primary)) {
                    Button(action: {
                        showChangePassword = true
                    }) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.orange)
                            Text("修改密码")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }

                    Button(action: {
                        // 绑定手机号
                    }) {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.orange)
                            Text("绑定手机号")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }

                // 通知设置
                Section(header: Text("通知设置").font(.headline).foregroundColor(.primary)) {
                    Toggle("订单通知", isOn: .constant(true))
                    Toggle("活动通知", isOn: .constant(false))
                    Toggle("系统通知", isOn: .constant(true))
                }

                // 关于应用
                Section(header: Text("关于").font(.headline).foregroundColor(.primary)) {
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("关于私厨")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        Image(systemName: "version")
                            .foregroundColor(.orange)
                        Text("版本 1.0.0")
                        Spacer()
                    }
                }

                // 退出登录
                Section {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditAvatar) {
                EditAvatarView()
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .onAppear(perform: loadSettings)
        }
    }

    private func loadSettings() {
        // 加载设置数据
        userName = "张三"
    }
}

struct UserProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileSettingsView()
            .modelContainer(for: [FamilyMember.self])
    }
}

// 更换头像页面
struct EditAvatarView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("更换头像")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.top)

            // 当前头像
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.orange)

            // 选择图片按钮
            Button(action: {
                // 选择图片逻辑
            }) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.white)
                    Text("从相册选择")
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                .shadow(radius: 5)
            }

            // 拍照按钮
            Button(action: {
                // 拍照逻辑
            }) {
                HStack {
                    Image(systemName: "camera")
                        .foregroundColor(.white)
                    Text("拍照")
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                .shadow(radius: 5)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("更换头像")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("取消") {
                dismiss()
            }
        }
    }
}

// 修改密码页面
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("修改密码")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.top)

            VStack(spacing: 16) {
                SecureField("当前密码", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("新密码", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("确认新密码", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            Button(action: {
                // 修改密码逻辑
                dismiss()
            }) {
                Text("确认修改")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("修改密码")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("取消") {
                dismiss()
            }
        }
    }
}

// 通知设置页面
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("通知设置")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.top)

            List {
                Toggle("订单通知", isOn: .constant(true))
                Toggle("活动通知", isOn: .constant(false))
                Toggle("系统通知", isOn: .constant(true))
                Toggle("营销通知", isOn: .constant(false))
            }
            .listStyle(PlainListStyle())

            Spacer()
        }
        .padding()
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("完成") {
                dismiss()
            }
        }
    }
}

// 关于页面
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("关于私厨")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.top)

            VStack(spacing: 16) {
                Text("私厨 - 家庭厨房点餐服务")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("版本 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("© 2024 私厨团队")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("关于私厨")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("关闭") {
                dismiss()
            }
        }
    }
}