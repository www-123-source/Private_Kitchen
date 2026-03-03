import SwiftUI
import SwiftData

struct MemberListView: View {
    let members: [FamilyMember]

    var body: some View {
        VStack(spacing: 16) {
            // 成员列表标题
            HStack {
                Text("家庭成员列表")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(members.count) 位成员")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // 成员卡片列表
            ForEach(members) { member in
                MemberCard(member: member)
            }
        }
    }
}

struct MemberListView_Previews: PreviewProvider {
    static var previews: some View {
        MemberListView(members: [
            FamilyMember(name: "张三", role: .admin),
            FamilyMember(name: "张四", role: .member),
            FamilyMember(name: .member, name: "张五")
        ])
    }
}

// 成员卡片组件
struct MemberCard: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            // 成员头像
            if let avatarData = member.avatar, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(member.role == .admin ? .orange : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 成员名称和角色
                HStack {
                    Text(member.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if member.role == .admin {
                        Text("管理员")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }

                // 成员信息
                Text("加入时间: \(member.joinedAt, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 操作按钮
            VStack(spacing: 8) {
                Button(action: {
                    // 编辑成员
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }

                Button(action: {
                    // 删除成员
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}