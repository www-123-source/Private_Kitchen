import SwiftUI

struct LaunchView: View {
    @State private var isActive = false

    var body: some View {
        VStack {
            Spacer()

            // Logo
            Image(systemName: "fork.knife")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
                .padding(.bottom, 20)

            Text("私厨")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)

            Text("家庭厨房点餐服务")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)

            Spacer()

            // Loading indicator
            if isActive {
                ProgressView()
                    .padding(.bottom, 20)
            }

            Text("版本 1.0")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .padding()
        .onAppear {
            // 模拟加载过程，然后跳转到身份选择
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // 跳转到身份选择
                }
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}