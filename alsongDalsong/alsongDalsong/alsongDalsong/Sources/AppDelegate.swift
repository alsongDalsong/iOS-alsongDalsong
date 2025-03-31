import UIKit
import FirebaseCore
import ASContainer
import ASLogKit
import ASRepository
import ASRepositoryProtocol
import ASNetworkKit
import ASCacheKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        assembleDependencies()
        return true
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        leaveRoom()
        sleep(5)
    }

    private func leaveRoom() {
        let roomActionRepository = DIContainer.shared.resolve(RoomActionRepositoryProtocol.self)
        
        Task {
            do {
                try await roomActionRepository.leaveRoom()
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
    
    private func assembleDependencies() {
        DIContainer.shared.addAssemblies([CacheAssembly(), NetworkAssembly(), RepsotioryAssembly()])
    }
}
