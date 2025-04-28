import ASContainer
import ASLogKit
import ASNetworkKit
import ASRepositoryProtocol
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo _: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions)
    {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        ASFirebaseAuth.configure()
        var inviteCode = ""

        if let url = connectionOptions.urlContexts.first?.url {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            if let roomNumber = components?.queryItems?.first(where: { item in
                item.name == "roomnumber"
            })?.value {
                inviteCode = roomNumber
            }
        }
        window = UIWindow(windowScene: windowScene)
        HapticManager.shared.prepare()

        let avatarRepository = DIContainer.shared.resolve(AvatarRepositoryProtocol.self)
        let bgmRepository = DIContainer.shared.resolve(BgmRepositoryProtocol.self)
        let dataDownloadRepository = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)
        let loadingVM = LoadingViewModel(
            avatarRepository: avatarRepository,
            bgmRepository: bgmRepository,
            dataDownloadRepository: dataDownloadRepository
        )

        let loadingVC = LoadingViewController(viewModel: loadingVM, inviteCode: inviteCode)
        window?.rootViewController = loadingVC
        window?.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_: UIScene) {
        let firebaseManager = DIContainer.shared.resolve(ASFirebaseAuthProtocol.self)
        guard
            let rootViewController = UIApplication.shared.topViewController(),
            let navigationController = rootViewController.navigationController
        else { return }

        Task {
            await AudioHelper.shared.resume()

            let isConnected = await firebaseManager.checkConnection()
            if !isConnected {
                let alert = SingleButtonAlertController(titleText: .networkConnectionLost) { _ in
                    navigationController.popToRootViewController(animated: true)
                    navigationController.navigationBar.isHidden = true
                }
                navigationController.presentAlert(alert)
            }
        }
    }

    func sceneDidEnterBackground(_: UIScene) {
        Task {
            await AudioHelper.shared.pause()
        }
    }

    func sceneDidDisconnect(_: UIScene) {
        let firebaseManager = DIContainer.shared.resolve(ASFirebaseAuthProtocol.self)
        Task {
            do {
                try await firebaseManager.signOut()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }
}
