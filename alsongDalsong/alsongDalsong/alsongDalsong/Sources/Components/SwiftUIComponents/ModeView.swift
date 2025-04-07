import ASEntity
import SwiftUI

struct ModeView: View {
    /// 뷰의 너비
    let width: CGFloat
    
    /// 실제로 사용되는 뷰모델
    var viewModel: ModeViewModel {
        externalViewModel ?? stateViewModel
    }
    
    @StateObject private var stateViewModel: ModeViewModel
    private var externalViewModel: ModeViewModel?
    
    /// 외부 값에 의해 뷰가 변경될 경우 사용하는 초기화
    init(mode: Mode, width: CGFloat) {
        _stateViewModel = StateObject(wrappedValue: ModeViewModel(mode: mode))
        self.externalViewModel = nil
        self.width = width
    }
    
    /// 외부 뷰에 의해 뷰 모델이 관리되는 경우 사용하는 초기화
    init(viewModel: ModeViewModel, width: CGFloat) {
        _stateViewModel = StateObject(wrappedValue: viewModel)
        self.externalViewModel = viewModel
        self.width = width
    }
    
    var body: some View {
        ZStack {
            if viewModel.selectedCard.isFaceUp {
                frontCard
            } else {
                backCard
                    .overlay(
                        viewModel.selectedCard.isOpened ? nil : lockedView
                    )
            }
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
    var lockedView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 30))
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                
                Text("곧 출시 예정입니다")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
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
                    Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.duration))
                        .font(.doHyeon(size: 20))
                }
                
                HStack {
                    Image(systemName: "person.fill")
                    Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.recommendedPlayers))
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
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    VStack(alignment: .leading, spacing: 50) {
                        Text(viewModel.selectedCard.mode.title)
                            .font(.doHyeon(size: 40))
                            .padding(.top, 50)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.description))
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .lineSpacing(5)
                            
                            Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.footerText))
                                .font(.system(size: 13))
                                .lineSpacing(5)
                                .opacity(0.7)
                        }
                    }
                        .padding(.horizontal, 28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                )
        }
    }
}
