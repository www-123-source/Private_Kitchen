import SwiftUI

struct CartBadgeView: View {
    @EnvironmentObject private var cartManager: CartManager
    @State private var showCart = false

    var body: some View {
        Button(action: {
            showCart = true
        }) {
            ZStack {
                Image(systemName: "cart")
                    .foregroundColor(.orange)
                    .font(.title2)

                if cartManager.totalQuantity > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .position(x: 20, y: -5)

                    Text("\(cartManager.totalQuantity)")
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
            .environmentObject(CartManager(
                modelContext: ModelContext(DataInitializer.configureModelContainer()),
                dataManager: DataManager(modelContext: ModelContext(DataInitializer.configureModelContainer()))
            ))
    }
}