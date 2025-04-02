import ASEntity
import SwiftUI

struct ModeView: View {
    let modeInfo: Mode
    @StateObject var viewModel = ModeViewModel()
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

private extension ModeView {
    var cardBaseView: some View {
        Image(viewModel.selectedCard.mode.imageName)
            .resizable()
            .scaledToFit()
            .blur(radius: viewModel.selectedCard.isFaceUp ? 0 : 10)
            .cornerRadius(30)
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
    
    var frontCard: some View {
        cardBaseView
            .overlay(frontOverlay)
    }
    
    var backCard: some View {
        cardBaseView
            .overlay(backOverlay)
    }
    
    var frontOverlay: some View {
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
    
    var backOverlay: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(Color.white.opacity(0.05))
            .overlay(
                VStack(alignment: .leading, spacing: 15) {
                    Text(viewModel.selectedCard.mode.title)
                        .font(.doHyeon(size: 40))
                    Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.description))
                        .font(.system(size: 18))
                }
                    .padding(.horizontal, 20)
            )
    }
}
