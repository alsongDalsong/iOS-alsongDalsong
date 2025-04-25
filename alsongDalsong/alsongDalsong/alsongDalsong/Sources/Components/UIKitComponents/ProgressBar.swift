import Combine
import UIKit

final class ProgressBar: UIView {
    private let progressBar = UIView()
    private var cancellables = Set<AnyCancellable>()
    
    private var shakeTimer: Timer?
    private var shakeWorkItem: DispatchWorkItem?
    
    private var targetDate: Date?
    private var progressBarWidthConstraint: NSLayoutConstraint?
    typealias CompletionHandler = () -> Void
    private var completionHandler: CompletionHandler?
    private var isCancelled = false
    private var isAnimating = false
    
    init() {
        super.init(frame: .zero)
        setupProgressBar()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(
        to dataSource: Published<Date?>.Publisher
    ) {
        dataSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDate in
                self?.targetDate = newDate
                self?.startProgressAnimation()
            }
            .store(in: &cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isAnimating {
            progressBarWidthConstraint?.constant = bounds.width
        }
    }
    
    private func setupProgressBar() {
        progressBar.backgroundColor = .asYellow
        addSubview(progressBar)
        
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBarWidthConstraint = progressBar.widthAnchor.constraint(equalToConstant: .responsiveWidth(0))
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressBarWidthConstraint!
        ])
    }
    
    func setCompletionHandler(_ handler: @escaping () -> Void) {
        completionHandler = handler
    }
    
    func cancelCompletion() {
        isCancelled = true
        shakeWorkItem?.cancel()
        shakeTimer?.invalidate()
        shakeTimer = nil
    }
    
    // MARK: - 진행 애니메이션 + shake 예약

    private func startProgressAnimation() {
        guard let targetDate else { return }
        let remaining = targetDate.timeIntervalSince(Date())
        guard remaining > 0 else { return }
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        shakeWorkItem?.cancel()
        isCancelled = false
        isAnimating = true
        
        progressBarWidthConstraint?.constant = bounds.width
        layoutIfNeeded()
        
        if remaining > 20 {
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                shakeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    Task { @MainActor in
                        guard !self.isCancelled else { return }
                        HapticManager.shared.impact(style: .light)
                        self.performShakeAnimation()
                    }
                }
                RunLoop.main.add(shakeTimer ?? Timer(), forMode: .common)
            }
            shakeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + (remaining - 20), execute: workItem)
        }
        
        UIView.animate(
            withDuration: remaining,
            delay: 0,
            options: .curveLinear,
            animations: { [weak self] in
                guard let self else { return }
                progressBarWidthConstraint?.constant = .responsiveWidth(0)
                progressBar.backgroundColor = .asLightRed
                layoutIfNeeded()
            },
            completion: { [weak self] _ in
                guard let self else { return }
                if !isCancelled {
                    completionHandler?()
                }
            }
        )
    }
    
    // MARK: - shake 애니메이션 정의

    private func performShakeAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.values   = [-5, 5, -4, 4, -2, 2, 0]
        animation.keyTimes = [0, 0.15, 0.3, 0.45, 0.6, 0.75, 1]
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(animation, forKey: "shake")
    }
}
