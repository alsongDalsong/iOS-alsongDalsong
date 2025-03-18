import SwiftUI

struct AudioPlayView: View {
    private let player1 = ASAudioPlayer()
    private let player2 = ASAudioPlayer()
    private let player3 = ASAudioPlayer()
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Play Beep") { play("beep", by: player1) }
            
            Button("Play Fire") { play("fire", by: player2) }
            
            Button("Play Robot") { play("robot", by: player3) }
        }
        .font(.title)
        .buttonStyle(.bordered)
    }
    
    func play(_ name: String, by player: ASAudioPlayer) {
        Task {
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
            let data = try Data(contentsOf: url)
            try await player.startPlaying(data: data)
        }
    }
}

#Preview {
    AudioPlayView()
}
