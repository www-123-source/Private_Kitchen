import SwiftUI

struct MemberManagementView: View {
    var body: some View {
        MemberListView()
    }
}

struct MemberManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MemberManagementView()
            .modelContainer(for: [FamilyMember.self, Order.self])
    }
}