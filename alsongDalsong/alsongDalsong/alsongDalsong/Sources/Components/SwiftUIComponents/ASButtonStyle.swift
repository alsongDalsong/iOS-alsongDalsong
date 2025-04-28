import SwiftUI

struct ASButtonStyle: ButtonStyle {
    var backgroundColor: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.doHyeon(size: .responsiveHeight(32)))
        }
        .tint(.black)
        .frame(maxWidth: .responsiveWidth(345), maxHeight: .responsiveHeight(64))
        .background(backgroundColor)
        .cornerRadius(.responsiveWidth(12))
        .shadow(
            color: .buttonShadowOfDefault,
            radius: .responsiveWidth(0),
            x: .responsiveWidth(5),
            y: .responsiveHeight(5)
        )
        .overlay(RoundedRectangle(cornerRadius: .responsiveWidth(12)).stroke(Color.black, lineWidth: .responsiveWidth(3)))
    }
}

#Preview {
    Button {
        
    } label: {
        Image(systemName: "link")
        Text("hi")
    }
    .buttonStyle(ASButtonStyle(backgroundColor: Color(.asMint)))
}
