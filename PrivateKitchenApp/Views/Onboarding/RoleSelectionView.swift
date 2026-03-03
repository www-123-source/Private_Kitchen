import SwiftUI

struct RoleSelectionView: View {
    @State private var selectedRole: MemberRole? = nil
    @State private var navigateToNext = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                Text("选择您的身份")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.bottom, 20)

                Text("请选择您在家庭厨房中的角色")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // 管理员按钮
                NavigationLink(
                    destination: AdminHomeView(),
                    tag: MemberRole.admin,
                    selection: $selectedRole
                ) {
                    Button(action: {
                        selectedRole = .admin
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                            Text("我是厨房管理员")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // 成员按钮
                NavigationLink(
                    destination: CustomerHomeView(),
                    tag: MemberRole.member,
                    selection: $selectedRole
                ) {
                    Button(action: {
                        selectedRole = .member
                    }) {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.orange)
                            Text("我是家庭成员")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .border(Color.orange, width: 2)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // 底部说明
                VStack(spacing: 10) {
                    Text("家庭厨房点餐服务")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("版本 1.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .navigationTitle("身份选择")
            .navigationBarHidden(true)
        }
    }
}

struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoleSelectionView()
    }
}