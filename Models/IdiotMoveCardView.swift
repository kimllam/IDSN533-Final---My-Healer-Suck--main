import SwiftUI

struct IdiotMoveCardView: View {
    let card: IdiotCard?
    let textColor = Color(red: 0.32, green: 0.18, blue: 0.10)
    
    var body: some View {
        if let card = card {
            Image(card.imageName)
                .resizable()
                .scaledToFit()
                .overlay {
                    GeometryReader { geo in
                        Text(card.description)
                            .font(.system(
                                size: max(6.5, geo.size.height * 0.068),
                                weight: .bold,
                                design: .serif
                            ))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                            .frame(
                                width: geo.size.width * 0.74,
                                height: geo.size.height * 0.22
                            )
                            .position(
                                x: geo.size.width * 0.5,
                                y: geo.size.height * 0.815
                            )
                    }
                }
        } else {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.brown.opacity(0.4), lineWidth: 1)
                .overlay(
                    Text("Empty")
                        .font(.caption2)
                        .foregroundColor(.gray)
                )
        }
    }
}