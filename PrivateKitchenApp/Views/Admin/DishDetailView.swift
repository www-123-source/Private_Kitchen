import SwiftUI

/// 菜品详情 / 编辑视图，复用 AddEditDishView 的编辑能力
struct DishDetailView: View {
    let dish: Dish

    var body: some View {
        AddEditDishView(dish: dish)
    }
}

struct DishDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DishDetailView(dish: Dish(name: "番茄炒蛋", description: "家常美味", price: 12, category: .lunch))
            .modelContainer(for: [Dish.self])
    }
}
