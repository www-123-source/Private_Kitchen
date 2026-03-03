import SwiftUI
import SwiftData

struct AddEditMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var memberName = ""
    @State private var selectedRole: MemberRole = .member
    @State private var avatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var isEditing = false
    @State private var memberToEdit: FamilyMember? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text(isEditing ? "编辑成员" : "添加成员")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // 成员头像
                VStack(spacing: 16) {
                    Image(uiImage: avatarImage ?? UIImage(systemName: "person.circle.fill")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .onTapGesture {
                            showImagePicker = true
                        }

                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text("更换头像")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }

                // 成员信息表单
                VStack(spacing: 16) {
                    // 成员姓名
                    VStack(alignment: .leading, spacing: 4) {
                        Text("成员姓名")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        TextField("请输入成员姓名", text: $memberName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 成员角色
                    VStack(alignment: .leading, spacing: 4) {
                        Text("成员角色")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Picker("角色", selection: $selectedRole) {
                            Text("家庭成员").tag(MemberRole.member)
                            Text("管理员").tag(MemberRole.admin)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // 加入时间（仅编辑时显示）
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("加入时间")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(memberToEdit?.joinedAt ?? Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()

                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: {
                        saveMember()
                    }) {
                        Text(isEditing ? "保存修改" : "添加成员")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(isEditing ? "编辑成员" : "添加成员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("取消") {
                    dismiss()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $avatarImage)
            }
            .onAppear(perform: loadMemberData)
        }
    }

    // 加载成员数据（编辑模式）
    private func loadMemberData() {
        // 模拟编辑模式
        isEditing = false
        memberName = ""
        selectedRole = .member
        avatarImage = nil
    }

    // 保存成员
    private func saveMember() {
        // 保存逻辑
        dismiss()
    }
}

struct AddEditMemberView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditMemberView()
            .modelContainer(for: [FamilyMember.self])
    }
}

// 图片选择器组件
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}