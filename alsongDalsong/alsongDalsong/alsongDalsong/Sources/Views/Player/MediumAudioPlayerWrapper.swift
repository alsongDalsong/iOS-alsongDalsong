import SwiftUI
import ASEntity

struct MediumAudioPlayerWrapper: UIViewRepresentable {
    let mappedAnswer: MappedAnswer

    func makeUIView(context: Context) -> MediumAudioPlayerView {
        let view = MediumAudioPlayerView(type: .result)
        view.bind(to: mappedAnswer)
        return view
    }

    func updateUIView(_ uiView: MediumAudioPlayerView, context: Context) {

    }
}
