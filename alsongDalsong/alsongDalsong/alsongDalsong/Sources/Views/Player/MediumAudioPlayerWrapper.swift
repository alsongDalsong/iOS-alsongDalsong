import SwiftUI

struct MediumAudioPlayerWrapper: UIViewRepresentable {
    let mappedAnswer: MappedAnswer

    func makeUIView(context: Context) -> MediumAudioPlayerView {
        let view = MediumAudioPlayerView(type: .result)
        view.configure(title: mappedAnswer.title, artist: mappedAnswer.artist)
        view.configure(imageData: mappedAnswer.artworkData)
        return view
    }

    func updateUIView(_ uiView: MediumAudioPlayerView, context: Context) {

    }
}
