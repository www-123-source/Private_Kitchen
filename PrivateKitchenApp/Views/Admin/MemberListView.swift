import SwiftUI

struct MemberListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var members: [FamilyMember]
    @State private var showingAddMember = false
    @State private var showingEditMember: FamilyMember? = nil

    var body: some View {
        NavigationView {
            VStack {
                // 成员列表
                List {
                    ForEach(members) { member in
                        NavigationLink(destination: MemberDetailView(member: member)) {
                            MemberRow(member: member)
                        }
                    }
                    .onDelete(perform: deleteMembers)
                }
                .listStyle(PlainListStyle())

                Spacer()
            }
            .navigationTitle("成员管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMember = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddEditMemberView()
            }
            .sheet(item: $showingEditMember) { member in
                AddEditMemberView(member: member)
            }
        }
    }

    private func deleteMembers(at offsets: IndexSet) {
        for index in offsets {
            let member = members[index]
            modelContext.delete(member)
        }
    }
}

struct MemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack {
            // 头像
            if let avatar = member.avatar, let uiImage = UIImage(data: avatar) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // 角色标签
                    if member.role == .admin {
                        Text("管理员")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text("加入时间: \(formattedDate(member.joinedAt))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 订单数量
            Text("订单: \(member.orders.count)")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 8)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct MemberListView_Previews: PreviewProvider {
    static var previews: some View {
        MemberListView()
            .modelContainer(for: [FamilyMember.self, Order.self])
    }
}