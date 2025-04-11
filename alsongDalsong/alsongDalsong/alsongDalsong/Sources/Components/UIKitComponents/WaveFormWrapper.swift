import SwiftUI

struct WaveFormWrapper: UIViewRepresentable {
    let columns: [CGFloat]
    let sampleCount: Int
    let circleColor: UIColor
    let highlightColor: UIColor
    
    func makeUIView(context: Context) -> WaveForm {
        let view = WaveForm(numOfColumns: sampleCount, circleColor: circleColor, highlightColor: highlightColor)
        return view
    }
    
    func updateUIView(_ uiView: WaveForm, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            uiView.drawColumns(with: columns)
            
            for i in 0..<sampleCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                    uiView.updatePlayingIndex(i)
                }
            }
        }
    }
}
