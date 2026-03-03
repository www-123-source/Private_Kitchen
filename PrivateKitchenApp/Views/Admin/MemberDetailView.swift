import SwiftUI

struct MemberDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let member: FamilyMember

    @State private var name: String
    @State private var role: MemberRole
    @State private var showingImagePicker = false
    @State private var imageData: Data?

    init(member: FamilyMember) {
        self.member = member
        _name = State(initialValue: member.name)
        _role = State(initialValue: member.role)
        _imageData = State(initialValue: member.avatar)
    }

    var body: some View {
        NavigationView {
            Form {
                // 头像
                Section(header: Text("头像")) {
                    if let image = member.avatar, let uiImage = UIImage(data: image) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .foregroundColor(.orange)
                    }

                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text("更换头像")
                            .foregroundColor(.orange)
                    }
                }

                // 基本信息
                Section(header: Text("基本信息")) {
                    TextField("姓名", text: $name)
                    Picker("角色", selection: $role) {
                        Text("家庭成员").tag(MemberRole.member)
                        Text("管理员").tag(MemberRole.admin)
                    }
                }

                // 统计信息
                Section(header: Text("点餐统计")) {
                    HStack {
                        Text("总订单数:")
                        Spacer()
                        Text("\(member.orders.count)")
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("总消费:")
                        Spacer()
                        Text("¥\(totalSpent, specifier: "%.2f")")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("成员详情")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageData: $imageData)
            }
        }
    }

    private var totalSpent: Double {
        return member.orders.reduce(0) { $0 + $1.totalAmount }
    }

    private func saveChanges() {
        member.name = name
        member.role = role
        member.avatar = imageData
        dismiss()
    }
}

struct MemberDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MemberDetailView(member: FamilyMember(name: "测试成员", role: .member))
            .modelContainer(for: [FamilyMember.self, Order.self])
    }
}