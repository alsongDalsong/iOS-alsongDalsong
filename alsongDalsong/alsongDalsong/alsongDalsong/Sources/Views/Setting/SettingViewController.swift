import UIKit

class SettingViewController: UIViewController {
    var settingView = ASPanel()
    var stackView = UIStackView()
    var titleLabel = UILabel()

    var bgmSlider = ASSlider()
    var effectSlider = ASSlider()

    var confirmButton = ASButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setLayout()
        setAction()
        setSliderValue()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.settingView.transform = .identity
        }
    }

    private func setSliderValue() {
        bgmSlider.value = BgmAudioHelper.shared.volume
        Task {
            effectSlider.value = await EffectAudioHelper.shared.getVolume()
        }
    }

    private func setAction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissAlert))
        view.addGestureRecognizer(tapGesture)

        confirmButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }, for: .touchUpInside)

        bgmSlider.addTarget(self, action: #selector(changeBgmSlider), for: .valueChanged)
        effectSlider.addTarget(self, action: #selector(changeEffectSlider), for: .valueChanged)
    }

    private func setupUI() {
        view.backgroundColor = .black.withAlphaComponent(0.3)
        setSettingView()
        setStackView()
        setTitleLabel()
    }

    private func setSettingView() {
        settingView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        settingView.backgroundColor = .asBackground
        settingView.layer.borderWidth = .responsiveWidth(2.5)
        settingView.layer.borderColor = UIColor.profileViewCircle.cgColor
        view.addSubview(settingView)
    }

    private func setStackView() {
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = .responsiveHeight(20)
        stackView.alignment = .center

        let sliders = [bgmSlider, effectSlider]
        let sliderTitles = ["배경음악".localized(), "효과음".localized()]

        let sliderPairs = zip(sliders, sliderTitles)

        for (slider, title) in sliderPairs {
            let sliderTitleLabel = UILabel()
            sliderTitleLabel.text = title
            sliderTitleLabel.font = .font(forTextStyle: .title2)

            let pairStack = UIStackView(arrangedSubviews: [sliderTitleLabel, slider])
            pairStack.axis = .vertical
            pairStack.spacing = .responsiveHeight(4)
            pairStack.alignment = .center

            stackView.addArrangedSubview(pairStack)
        }

        confirmButton.setConfiguration(text: "확인", textStyle: .title3, backgroundColor: .asLightSky, shadowColor: .buttonShadowOfBlue)
        stackView.addArrangedSubview(confirmButton)

        settingView.addSubview(stackView)
    }

    private func setTitleLabel() {
        titleLabel.text = "설정".localized()
        titleLabel.font = .font(forTextStyle: .largeTitle)
        settingView.addSubview(titleLabel)
    }

    func settingViewWidthConstraint() -> NSLayoutConstraint {
        return settingView.widthAnchor.constraint(equalToConstant: .responsiveWidth(345))
    }

    func settingViewHeightConstraint() -> NSLayoutConstraint {
        return settingView.heightAnchor.constraint(equalToConstant: .responsiveHeight(380))
    }

    private func setLayout() {
        settingView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        bgmSlider.translatesAutoresizingMaskIntoConstraints = false
        effectSlider.translatesAutoresizingMaskIntoConstraints = false

        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            settingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingViewWidthConstraint(),
            settingViewHeightConstraint(),

            titleLabel.centerXAnchor.constraint(equalTo: settingView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: settingView.topAnchor, constant: .responsiveHeight(20)),
            titleLabel.heightAnchor.constraint(equalToConstant: .responsiveHeight(50)),

            bgmSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8),
            effectSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8),

            confirmButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8),

            stackView.leadingAnchor.constraint(equalTo: settingView.leadingAnchor, constant: .responsiveWidth(10)),
            stackView.trailingAnchor.constraint(equalTo: settingView.trailingAnchor, constant: .responsiveWidth(-10)),
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .responsiveHeight(20)),
            stackView.bottomAnchor.constraint(equalTo: settingView.bottomAnchor, constant: .responsiveHeight(-30)),

        ])
    }

    @objc func dismissAlert(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: view)
        if !settingView.frame.contains(touchLocation) {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc func changeBgmSlider() {
        BgmAudioHelper.shared.volume = bgmSlider.value
    }

    @objc func changeEffectSlider() {
        EffectAudioHelper.shared.changeVolume(effectSlider.value)
    }
}
