import LinkPresentation

final class InviteShareItem: NSObject, UIActivityItemSource {
    private let title = "알쏭달쏭 방에 친구 초대하기"
    private let url: URL
    private let icon: UIImage?

    init(roomNumber: String) {
        self.url = URL(string: "alsongDalsong://invite/?roomnumber=\(roomNumber)")!
        self.icon = UIImage(named: "InviteIcon")
    }

    func activityViewControllerPlaceholderItem(
        _ controller: UIActivityViewController
    ) -> Any {
        return title as NSString
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        return "알쏭달쏭에 초대되셨습니다.\n\n초대 링크: \(url.absoluteString)" as NSString
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return title
    }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.originalURL = url
        metadata.url = url

        if let iconImage = icon {
            let provider = NSItemProvider(object: iconImage)
            metadata.iconProvider = provider
            metadata.imageProvider = provider
        } else {
            let provider = NSItemProvider(object: UIImage())
            metadata.iconProvider = provider
            metadata.imageProvider = provider
        }
        
        return metadata
    }
}
