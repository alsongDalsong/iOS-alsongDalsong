import SwiftUI
import ASEntity

struct ModeView: View {
    let modeInfo: Mode
    @StateObject var viewModel = ModeViewModel()
    let width: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.asSystem)
                .cornerRadius(12)
                .shadow(color: .asShadow, radius: 0, x: 5, y: 5)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
            VStack {
                Text(LocalizedStringResource(stringLiteral: modeInfo.title))
                    .font(.doHyeon(size: 32))
                    .padding(.top, 16)
                    .layoutPriority(1)
                GeometryReader { geometry in
                    VStack {
                        Image(modeInfo.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                            .frame(width: width, height: min(geometry.size.height * 0.6, 150))
                        
                        Text(LocalizedStringResource(stringLiteral: modeInfo.description))
                            .font(.doHyeon(size: 20))
                            .minimumScaleFactor(0.01)
                            .lineLimit(nil)
                            .padding(.top, 0)
                            .padding(.horizontal)
                            .frame(maxHeight: geometry.size.height * 0.3, alignment: .top)
                    }
                }
            }
            
        }
        .frame(width: width)
    }
}

extension ModeView {
    private var frontOverlay: some View {
          ZStack {
              VStack(alignment: .leading) {
                  HStack {
                      Image(systemName: "clock")
                      Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.recommended.time))
                          .font(.doHyeon(size: 20))
                  }

                  HStack {
                      Image(systemName: "person.fill")
                      Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.recommended.peopleCount))
                          .font(.doHyeon(size: 20))
                  }
              }
              .padding(.top, 16)
              .padding(.trailing, 24)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

              VStack(alignment: .leading) {
                  Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.title))
                      .font(.doHyeon(size: 40))
                      .layoutPriority(1)

                  Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.summary))
                      .font(.doHyeon(size: 24))
                      .minimumScaleFactor(0.01)
              }
              .padding(.bottom, 25)
              .padding(.leading, 24)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
          }
          .foregroundStyle(.white)  //TO-DO
      }
}
