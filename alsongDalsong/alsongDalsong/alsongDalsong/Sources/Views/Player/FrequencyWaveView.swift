import UIKit

final class FrequencyWaveView: UIView {
    private var frequencyShapeLayers: [CAShapeLayer] = []
    
    private let shapeLayersCount = 6
    private let spacing: CGFloat = 1.5
    private let initialHeight: CGFloat = 3
    
    private var initialWidth: CGFloat {
        (bounds.width - spacing * CGFloat(shapeLayersCount - 1)) / CGFloat(shapeLayersCount)
    }
    
    var normalizedFrequencyAmplitudes: [Float] = [0, 0, 0, 0, 0, 0] {
        didSet {
            updateFrequencyShapeLayers()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if frequencyShapeLayers.isEmpty {
            setup()
        }
    }
    
    private func setup() {
        for i in 0..<shapeLayersCount {
            let shapeLayer = CAShapeLayer()
            let xPosition = CGFloat(i) * (initialWidth + spacing)
            
            let rect = CGRect(
                x: xPosition,
                y: (bounds.height - initialHeight) / 2,
                width: initialWidth,
                height: initialHeight
            )
            
            shapeLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath
            shapeLayer.fillColor = UIColor.lightGray.cgColor
            frequencyShapeLayers.append(shapeLayer)
            layer.addSublayer(shapeLayer)
        }
    }

    private func updateFrequencyShapeLayers() {
        guard normalizedFrequencyAmplitudes.count == 6 else { return }
        
        for (index, shapeLayer) in frequencyShapeLayers.enumerated() {
            let normalizedFrequencyAmplitude = CGFloat(normalizedFrequencyAmplitudes[index])
            let newHeight = max(initialHeight, bounds.height * normalizedFrequencyAmplitude)
            
            let xPosition = CGFloat(index) * (initialWidth + spacing)
            
            let newRect = CGRect(
                x: xPosition,
                y: (bounds.height - newHeight) / 2,
                width: initialWidth,
                height: newHeight
            )
            
            let newPath = UIBezierPath(roundedRect: newRect, cornerRadius: 2).cgPath
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.fromValue = shapeLayer.path
            animation.toValue = newPath
            
            animation.isRemovedOnCompletion = true
            animation.fillMode = .forwards
            
            shapeLayer.add(animation, forKey: "pathAnimation")
            shapeLayer.path = newPath
        }
    }
}
