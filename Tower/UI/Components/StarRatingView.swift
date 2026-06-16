import SwiftUI

struct StarRatingView: View {
    let stars: Int
    let maxStars: Int
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= stars ? Color.yellow : Color.gray.opacity(0.4))
            }
        }
    }
}
