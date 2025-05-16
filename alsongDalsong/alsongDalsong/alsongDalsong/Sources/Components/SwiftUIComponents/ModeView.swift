import ASEntity
import SwiftUI

struct ModeView: View {
    /// 뷰의 너비
    let width: CGFloat
    
    /// 실제로 사용되는 뷰모델
    @ObservedObject private var viewModel: ModeViewModel
    
    /// 외부 값에 의해 뷰가 변경될 경우 사용하는 초기화
    init(mode: Mode, width: CGFloat) {
        self.viewModel = ModeViewModel(mode: mode)
        self.width = width
    }
    
    /// 외부 뷰에 의해 뷰 모델이 관리되는 경우 사용하는 초기화
    init(viewModel: ModeViewModel, width: CGFloat) {
        self.viewModel = viewModel
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
            .clipShape(.rect(cornerRadius: .responsiveWidth(30), style: .continuous))
            .shadow(color: Color.black.opacity(0.25), radius: .responsiveWidth(4), x: .responsiveWidth(0), y: .responsiveHeight(4))
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
                        .font(.doHyeon(size: .responsiveHeight(20)))
                }
                
                HStack {
                    Image(systemName: "person.fill")
                    
                    Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.recommendedPlayers))
                        .font(.doHyeon(size: .responsiveHeight(20)))
                }
            }
            .padding(.top, .responsiveHeight(16))
            .padding(.trailing, .responsiveWidth(24))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
            VStack(alignment: .leading) {
                Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.title))
                    .font(.doHyeon(size: .responsiveHeight(40)))
                    .layoutPriority(1)
                
                Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.summary))
                    .font(.doHyeon(size: .responsiveHeight(24)))
                    .minimumScaleFactor(0.01)
            }
            .padding(.bottom, .responsiveHeight(25))
            .padding(.leading, .responsiveWidth(24))
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
        RoundedRectangle(cornerRadius: .responsiveWidth(30), style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading) {
                    Text(viewModel.selectedCard.mode.title)
                        .font(.doHyeon(size: .responsiveHeight(40)))

                    Text(LocalizedStringResource(stringLiteral: viewModel.selectedCard.mode.description))
                        .font(.system(size: .responsiveHeight(18)))
                        .fontWeight(.medium)
                        .lineSpacing(.responsiveHeight(6))
                        .frame(maxHeight: .infinity)
                }
                .padding(.vertical, .responsiveHeight(50))
                .padding(.horizontal, .responsiveWidth(28))
            }
    }
    
    var lockedView: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.3))
            .clipShape(.rect(cornerRadius: .responsiveWidth(30), style: .continuous))
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: .responsiveHeight(40), weight: .bold))

                    Text("곧 출시 예정입니다")
                        .font(.system(size: .responsiveHeight(18)))
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
            }
    }
}
