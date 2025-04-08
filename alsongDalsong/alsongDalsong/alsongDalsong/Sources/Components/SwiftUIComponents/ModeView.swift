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
            }
        }
        .rotation3DEffect(
            Angle(degrees: viewModel.rotation + (viewModel.selectedCard.isFaceUp ? 0 : 180)),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.8)) {
                viewModel.flipCard()
            }
        }
        .frame(width: width)
    }
}

private extension ModeView {
    var cardBaseView: some View {
        Image(viewModel.selectedCard.mode.imageName)
            .resizable()
            .scaledToFit()
            .clipShape(.rect(cornerRadius: 30, style: .continuous))
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
        VStack {
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
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
        }
        .foregroundStyle(.white)  //TO-DO
    }
    
    var backOverlay: some View {
        VStack {
            if viewModel.selectedCard.isOpened {
                descriptionView
            } else {
                lockedView
            }
        }
    }
    
    var descriptionView: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading) {
                    Text(viewModel.selectedCard.mode.title)
                        .font(.doHyeon(size: 40))
                    
                    Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.description))
                        .font(.doHyeon(size: 18))
                        .lineSpacing(6)
                        .frame(maxHeight: .infinity)
                }
                .padding(.vertical, 50)
                .padding(.horizontal, 28)
            }
    }
    
    var lockedView: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.3))
            .clipShape(.rect(cornerRadius: 30, style: .continuous))
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40, weight: .bold))
                    
                    Text("곧 출시 예정입니다")
                        .font(.doHyeon(size: 18))
                }
                .foregroundColor(.white)
            }
    }
}
