//
//  FriendsStories
//

import SwiftUI

struct FriendsListView: View {
    var body: some View {
        LazyVStack {
            ForEach(0..<10) { index in
                Text("Friend \(index)")
            }
        }
    }
}
