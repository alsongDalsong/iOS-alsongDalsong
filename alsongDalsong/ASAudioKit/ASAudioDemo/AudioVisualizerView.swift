import SwiftUI
import Charts

struct AudioVisualizerView: View {
    private let audioVisualizer = ASAudioVisualizer()
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    @State private var data: [Float] = []
    @State private var isPlaying = false
    
    private let harderBetterFasterStronger = "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview112/v4/bf/a6/1b/bfa61b15-a797-ec2d-ef44-bf9bfb9fab10/mzaf_9377760837375603436.plus.aac.p.m4a"

    var body: some View {
        VStack {
            HStack {
                Button(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                    if isPlaying {
                        audioVisualizer.pause()
                    } else {
                        audioVisualizer.play()
                    }
                    
                    isPlaying.toggle()
                }
                
                Button("Stop", systemImage: "stop.fill") {
                    audioVisualizer.stop()
                    isPlaying = false
                    withAnimation {
                        data = Array(repeating: 0, count: 20)
                    }
                }
                .disabled(!isPlaying)
            }
            
            Chart(Array(data.enumerated()), id: \.0) { index, magnitude in
                BarMark(
                    x: .value("Frequency", String(index)),
                    y: .value("Magnitude", magnitude)
                )
                .foregroundStyle(.blue)
            }
            .onAppear {
                guard let url = URL(string: harderBetterFasterStronger) else { return }
                
                Task {
                    let data = try await URLSession.shared.data(from: url)
                    audioVisualizer.bind(data: data.0)
                }
            }
            .onReceive(timer) { _ in
                if isPlaying {
                    withAnimation {
                        data = audioVisualizer.frequencyAmplitudes.map { min($0, 40) }
                    }
                }
            }
            .chartYScale(domain: 0...40)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 100)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
        }
    }
}

#Preview {
    AudioVisualizerView()
}
