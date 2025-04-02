import ASEntity
import SwiftUI

struct ModeView: View {
    @StateObject var viewModel: ModeViewModel
    let width: CGFloat
    
    var body: some View {
        ZStack {
            frontCard
                .opacity(viewModel.selectedCard.isFaceUp ? 1 : 0)
            backCard
                .opacity(viewModel.selectedCard.isFaceUp ? 0 : 1)
        }
        .rotation3DEffect(
            Angle(degrees: viewModel.rotation + (viewModel.selectedCard.isFaceUp ? 0 : 180)),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .frame(width: width)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.8)) {
                viewModel.flipCard()
            }
        }
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
