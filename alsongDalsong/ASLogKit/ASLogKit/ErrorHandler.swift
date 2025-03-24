public enum ErrorHandler {
    public static func handle(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let error = "(\(file):\(line) \(function)) \(error.localizedDescription)"
        Logger.error(error)
    }
}
