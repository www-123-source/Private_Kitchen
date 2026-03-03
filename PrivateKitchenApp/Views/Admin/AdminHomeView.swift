import SwiftUI

struct AdminHomeView: View {
    var body: some View {
        NavigationView {
            KitchenDashboardView()
        }
    }
}

struct AdminHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AdminHomeView()
    }
}