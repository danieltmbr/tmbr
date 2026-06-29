import SwiftUI

struct AccountView: View {

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            SignOutButton()
                .padding(.bottom, 60)
        }
    }
}
