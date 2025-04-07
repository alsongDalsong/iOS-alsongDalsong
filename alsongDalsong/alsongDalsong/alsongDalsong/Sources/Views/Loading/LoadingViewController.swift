import ASContainer
import ASRepositoryProtocol
import AVFoundation
import Combine
import UIKit

final class LoadingViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let stackView = UIStackView()
    
    private var viewModel: LoadingViewModel?
    private var inviteCode = ""
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: LoadingViewModel, inviteCode: String) {
        self.viewModel = viewModel
        self.inviteCode = inviteCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestMicrophonePermission()
        setupUI()
        setupLayout()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .asBackground
        
        titleLabel.text = "알쏭달쏭"
        titleLabel.font = .font(.riaSans, ofSize: 80)
        titleLabel.textColor = .onboardingForeground
        
        subtitleLabel.text = "기다려라"
        subtitleLabel.font = .font(.riaSans, ofSize: 20)
        subtitleLabel.textColor = .onboardingForeground
                
        activityIndicatorView.startAnimating()
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(activityIndicatorView)
        
        view.addSubview(stackView)
    }
    
    private func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func bindViewModel() {
        bind(viewModel?.$avatarData) { [weak self] avatarData in
            guard let avatarData,
                  let avatars = self?.viewModel?.avatars,
                  let selectedAvatar = self?.viewModel?.selectedAvatar else { return }
            
            self?.titleLabelAnimation {
                self?.navigateToOnboarding(avatars: avatars, selectedAvatar: selectedAvatar, avatarData: avatarData)
            }
        }
    }
    
    private func bind<T>(
        _ publisher: Published<T>.Publisher?,
        handler: @escaping (T) -> Void
    ) {
        publisher?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }
    
    private func titleLabelAnimation(completion: @escaping () -> Void) {
        guard let superview = titleLabel.superview else { return }

        let currentY = superview.convert(titleLabel.frame, to: nil).minY
        let targetY = view.safeAreaInsets.top
                
        let scaleFactor: CGFloat = 32 / 80 /// 폰트 크기 변화
        let fontHeightDifference = titleLabel.frame.height * (1 - scaleFactor)
        
        let translationY = targetY - currentY - (fontHeightDifference / 2)

        let animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.85) { [weak self] in
            self?.titleLabel.transform = CGAffineTransform(translationX: 0, y: translationY)
                .scaledBy(x: scaleFactor, y: scaleFactor)
            
            self?.subtitleLabel.alpha = 0
            self?.activityIndicatorView.alpha = 0
        }

        animator.addCompletion { _ in
            completion()
        }
        
        animator.startAnimation()
    }
    
    private func navigateToOnboarding(avatars: [URL], selectedAvatar: URL, avatarData: Data) {
        let roomActionRepository = DIContainer.shared.resolve(RoomActionRepositoryProtocol.self)
        let dataDownloadRepository = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)
        
        let onboardingVM = OnboardingViewModel(
            roomActionRepository: roomActionRepository,
            dataDownloadRepository: dataDownloadRepository,
            avatars: avatars,
            selectedAvatar: selectedAvatar,
            avatarData: avatarData
        )
        let onboardingVC = OnboardingViewController(
            viewModel: onboardingVM,
            inviteCode: inviteCode
        )
        let navigationController = UINavigationController(rootViewController: onboardingVC)
        navigationController.navigationBar.isHidden = true
        navigationController.interactivePopGestureRecognizer?.isEnabled = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first
        {
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
            UIView.transition(with: window, duration: 1, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    func requestMicrophonePermission() {
        Task {
            await AVCaptureDevice.requestAccess(for: .audio)
        }
    }
}
