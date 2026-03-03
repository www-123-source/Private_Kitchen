import SwiftUI
import SwiftData

struct MemberManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddMember = false
    @State private var family: Family? = nil
    @State private var members: [FamilyMember] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题和添加按钮
                HStack {
                    Text("家庭成员")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()

                    Button(action: {
                        showAddMember = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top)

                // 家庭信息
                if let family = family {
                    FamilyInfoView(family: family)
                        .padding(.horizontal)
                }

                // 成员列表
                MemberListView(members: members)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("家庭成员")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddMember) {
                AddEditMemberView()
            }
            .onAppear(perform: loadFamilyData)
        }
    }

    // 加载家庭数据
    private func loadFamilyData() {
        // 模拟加载家庭数据
        family = Family(name: "张氏家庭", adminId: UUID())
        members = [
            FamilyMember(name: "张三", role: .admin),
            FamilyMember(name: "张四", role: .member),
            FamilyMember(name: "张五", role: .member)
        ]
    }
}

struct MemberManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MemberManagementView()
            .modelContainer(for: [Family.self, FamilyMember.self])
    }
}

// 家庭信息组件
struct FamilyInfoView: View {
    let family: Family

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("家庭信息")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("家庭名称")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(family.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("成员数量")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(family.members.count) 人")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("创建时间")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(family.createdAt, style: .date)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}