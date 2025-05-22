import ASLogKit
import Combine
import SwiftUI

class HummingResultViewController: UIViewController {
    deinit {
        Logger.debug("HummingResultViewController deinit")
    }
    private let answerView = MediumAudioPlayerView(type: .result)
    private let resultTableView = UITableView()
    private let nextButton = ASButton()

    private var resultTableViewDiffableDataSource: HummingResultTableViewDiffableDataSource?
    private var viewModel: HummingResultViewModel?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: HummingResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        viewModel = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .asBackground
        setupUI()
        setupLayout()
        bindViewModel()
        viewModel?.bindResult()
    }

    override func viewDidDisappear(_ animation: Bool) {
        super.viewDidDisappear(animation)
        answerView.unbind()
        viewModel?.cancelSubscriptions()
    }

    private func setupUI() {
        setResultTableView()
        setButton()
        setAction()
        view.addSubview(resultTableView)
        view.addSubview(nextButton)
        view.addSubview(answerView)
    }

    private func setResultTableView() {
        resultTableViewDiffableDataSource = HummingResultTableViewDiffableDataSource(tableView: resultTableView)
        resultTableView.separatorStyle = .none
        resultTableView.allowsSelection = false
        resultTableView.backgroundColor = .asBackground
        resultTableView.contentInset = UIEdgeInsets(
            top: .responsiveHeight(10),
            left: .responsiveWidth(0),
            bottom: .responsiveHeight(0),
            right: .responsiveWidth(0)
        )
    }

    private func setButton() {
        viewModel?.isHost == true
        ? nextButton.setConfiguration(.next)
        : nextButton.setConfiguration(.nextResultWaiting)
        nextButton.setDisabledState()
    }

    private func setAction() {
        nextButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            showNextResultLoading()
        }, for: .touchUpInside)
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        answerView.translatesAutoresizingMaskIntoConstraints = false
        resultTableView.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            answerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: .responsiveHeight(20)),
            answerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(20)),
            answerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-20)),
            answerView.heightAnchor.constraint(equalToConstant: .responsiveHeight(80)),

            resultTableView.topAnchor.constraint(equalTo: answerView.bottomAnchor, constant: .responsiveHeight(20)),
            resultTableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            resultTableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            resultTableView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: .responsiveHeight(-30)),

            nextButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(24)),
            nextButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-24)),
            nextButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(64)),
            nextButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: .responsiveHeight(-16)),
        ])
    }

    func addDataSource(_ phase: ResultPhase, result: Result) {
        switch phase {
        case .answer:
            resultTableViewDiffableDataSource?.applySnapshot((result.answer, [], nil))
            
        case .record(let count):
            resultTableViewDiffableDataSource?.applySnapshot((result.answer, Array(result.records[0...count]), nil))
            
        case .submit:
            resultTableViewDiffableDataSource?.applySnapshot(result)
            
        case .none: return
        }
    }

    private func changeButton(_ phase: ResultPhase) {
        if case .none = phase {
            if viewModel?.totalResult.isEmpty == true {
                nextButton.setConfiguration(.complete)
            } else {
                nextButton.setConfiguration(.next)
                nextButton.isEnabled = true
                nextButton.removeTarget(nil, action: nil, for: .touchUpInside)
                nextButton.addAction(UIAction { _ in
                    self.showNextResultLoading()
                }, for: .touchUpInside)
            }
        } else {
            nextButton.setDisabledState()
        }
    }
    
    private func bindViewModel() {
        guard let viewModel else { return }
        
        viewModel.$result
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let answer = result.answer else { return }
                self?.answerView.bind(to: answer)
            }
            .store(in: &cancellables)
        
        viewModel.$resultPhase
            .combineLatest(viewModel.$result, viewModel.$isHost)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase, result, isHost in
                self?.addDataSource(phase, result: result)
                if result.answer != nil, isHost {
                    self?.changeButton(phase)
                }
            }
            .store(in: &cancellables)

        viewModel.$canEndGame
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canEndGame in
                if canEndGame {
                    guard viewModel.isHost else {
                        self?.nextButton.setConfiguration(.endWaiting)
                        return
                    }
                    self?.nextButton.isEnabled = true
                    self?.nextButton.removeTarget(nil, action: nil, for: .touchUpInside)
                    self?.nextButton.addAction(UIAction { _ in
                        self?.showLobbyLoading()
                    }, for: .touchUpInside)
                } else {
                    self?.nextButton.setDisabledState()
                }
            }
            .store(in: &cancellables)
    }
}

extension HummingResultViewController {
    private func showNextResultLoading() {
        let alert = LoadingAlertController(
            progressText: .nextResult,
            loadAction: { [weak self] in
                try await self?.viewModel?.changeRecordOrder()
            },
            errorCompletion: { [weak self] error in
                self?.showFailedAlert(error)
            }
        )
        presentAlert(alert)
    }

    private func showLobbyLoading() {
        let alert = LoadingAlertController(
            progressText: .toLobby,
            loadAction: { [weak self] in
                try await self?.viewModel?.navigateToLobby()
            },
            errorCompletion: { [weak self] error in
                self?.showFailedAlert(error)
            }
        )
        presentAlert(alert)
    }

    private func showFailedAlert(_ error: Error) {
        let alert = SingleButtonAlertController(titleText: .error(error))
        presentAlert(alert)
    }
}
