import SwiftUI

struct DishManagementView: View {
    var body: some View {
        DishListView()
    }
}

struct DishManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DishManagementView()
            .modelContainer(for: [Dish.self])
    }
}