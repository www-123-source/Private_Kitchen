import SwiftUI

struct AddEditMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var role: MemberRole = .member
    @State private var showingImagePicker = false
    @State private var imageData: Data?

    var member: FamilyMember?

    init(member: FamilyMember? = nil) {
        if let member = member {
            _name = State(initialValue: member.name)
            _role = State(initialValue: member.role)
            _imageData = State(initialValue: member.avatar)
            self.member = member
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // 头像
                Section(header: Text("头像")) {
                    if let image = imageData, let uiImage = UIImage(data: image) {
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
                        Text("选择头像")
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
            }
            .navigationTitle(member == nil ? "添加成员" : "编辑成员")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMember()
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

    private func saveMember() {
        if let member = member {
            // 编辑现有成员
            member.name = name
            member.role = role
            member.avatar = imageData
        } else {
            // 添加新成员
            let newMember = FamilyMember(name: name, role: role)
            newMember.avatar = imageData
            modelContext.insert(newMember)
        }
        dismiss()
    }
}

struct AddEditMemberView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditMemberView()
            .modelContainer(for: [FamilyMember.self])
    }
}