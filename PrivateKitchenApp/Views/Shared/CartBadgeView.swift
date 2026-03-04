import SwiftUI

struct CartBadgeView: View {
    @State private var showCart = false
    // 模拟购物车数量
    @State private var cartQuantity = 0

    var body: some View {
        Button(action: {
            showCart = true
        }) {
            ZStack {
                Image(systemName: "cart")
                    .foregroundColor(.orange)
                    .font(.title2)

                if cartQuantity > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .position(x: 20, y: -5)

                    Text("\(cartQuantity)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .offset(x: 15, y: -10)
                }
            }
        }
        .sheet(isPresented: $showCart) {
            CartView()
        }
    }
}

struct CartBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        CartBadgeView()
    }
}