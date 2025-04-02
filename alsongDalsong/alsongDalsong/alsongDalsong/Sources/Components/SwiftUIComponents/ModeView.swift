import ASEntity
import SwiftUI

struct ModeView: View {
    let modeInfo: Mode
    let width: CGFloat
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.purplePanel)
                .cornerRadius(30)
                .shadow(color: .asShadow, radius: 2, x: 0, y: 4)
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: "clock")
                    Text(LocalizedStringResource(stringLiteral: modeInfo.duration))
                        .font(.doHyeon(size: 20))
                        .layoutPriority(1)
                }
                HStack {
                    Spacer()
                    Image(systemName: "person.2.fill")
                    Text(LocalizedStringResource(stringLiteral: modeInfo.recommendedPlayers))
                        .font(.doHyeon(size: 20))
                        .layoutPriority(1)
                }
                GeometryReader { geometry in
                    VStack {
                        Image(modeInfo.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                            .frame(width: width, height: min(geometry.size.height * 0.6, 150))
                    }
                }
                Text(LocalizedStringResource(stringLiteral: modeInfo.title))
                    .font(.doHyeon(size: 40))
                    .layoutPriority(1)
                Text(LocalizedStringResource(stringLiteral: modeInfo.summary))
                    .font(.doHyeon(size: 24))
                    .foregroundStyle(Color(red: 0.913, green: 0.913, blue: 0.913))
                    .layoutPriority(1)
            }
            .foregroundStyle(.white)
            .padding(16)
        }
        .frame(width: width)
    }
}
