enum StorageState {
    case available
    case writeFailed
    case readFailed

    var hasError: Bool {
        self != .available
    }

    var allowsWriting: Bool {
        self != .readFailed
    }
}
