import UIKit

final class FrequencyWaveView: UIView {
    private var frequencyLayers: [CALayer] = []
    
    private let shapeLayersCount = 6
    private let spacing: CGFloat = 1.5
    private let initialHeight: CGFloat = 3
    
    private var initialWidth: CGFloat {
        (bounds.width - spacing * CGFloat(shapeLayersCount - 1)) / CGFloat(shapeLayersCount)
    }
    
    /// 범위는 0 ~ 1
    /// 업데이트하면 자동으로 애니메이션 적용
    /// 해당 속성 이외의 속성, 함수에 접근 불가능
    var normalizedFrequencyAmplitudes: [Float] = [0, 0, 0, 0, 0, 0] {
        didSet {
            updateFrequencyShapeLayers()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
}

// MARK: - Private Methods
extension FrequencyWaveView {
    private func setup() {
        guard frequencyLayers.isEmpty else { return }
        
        for i in 0..<shapeLayersCount {
            let xPosition = CGFloat(i) * (initialWidth + spacing)
            let layer = CALayer()
            layer.frame = CGRect(
                x: xPosition,
                y: (bounds.height - initialHeight) / 2,
                width: initialWidth,
                height: initialHeight
            )
            layer.backgroundColor = UIColor.lightGray.cgColor
            layer.cornerRadius = 2
            layer.masksToBounds = true
            
            frequencyLayers.append(layer)
            self.layer.addSublayer(layer)
        }
    }
    
    private func updateFrequencyShapeLayers() {
        guard normalizedFrequencyAmplitudes.count == shapeLayersCount else { return }
        
        for (index, layer) in frequencyLayers.enumerated() {
            let normalized = CGFloat(normalizedFrequencyAmplitudes[index])
            let newHeight = max(initialHeight, bounds.height * normalized)
            let xPosition = CGFloat(index) * (initialWidth + spacing)
            let newFrame = CGRect(
                x: xPosition,
                y: (bounds.height - newHeight) / 2,
                width: initialWidth,
                height: newHeight
            )
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            layer.frame = newFrame
            CATransaction.commit()
        }
    }
}
