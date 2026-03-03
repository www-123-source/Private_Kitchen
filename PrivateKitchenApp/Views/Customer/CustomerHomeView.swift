import SwiftUI

struct CustomerHomeView: View {
    @EnvironmentObject private var syncManager: SyncManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("顾客端")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal)

                // 同步状态
                SyncStatusView(syncManager: syncManager)
                    .padding(.horizontal)

                // 功能按钮
                VStack(spacing: 15) {
                    NavigationLink(destination: DishBrowseView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.white)
                            Text("点餐")
                                .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    NavigationLink(destination: CartView()) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.white)
                            Text("购物车")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    NavigationLink(destination: OrderHistoryView()) {
                        HStack {
                            Image(systemName: "doc.text")
                            .foregroundColor(.white)
                            Text("我的订单")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    NavigationLink(destination: RecipeView()) {
                        HStack {
                            Image(systemName: "book.fill")
                            .foregroundColor(.white)
                            Text("私人菜谱")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    NavigationLink(destination: UserProfileView()) {
                        HStack {
                            Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            Text("个人资料")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }

                    NavigationLink(destination: MemberManagementView()) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            .foregroundColor(.white)
                            Text("家庭成员")
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
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("顾客端")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CustomerHomeView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerHomeView()
            .environmentObject(SyncManager())
    }
}