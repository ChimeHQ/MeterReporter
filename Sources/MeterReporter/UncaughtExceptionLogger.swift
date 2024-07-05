import Foundation
import Meter

final class UncaughtExceptionLogger {
    public var exceptionInfoURL: URL?
    fileprivate let existingHandler: NSUncaughtExceptionHandler?

	nonisolated(unsafe) static let logger = UncaughtExceptionLogger()

    private init() {
        self.existingHandler = NSGetUncaughtExceptionHandler()

        NSSetUncaughtExceptionHandler(writeException)
    }

    fileprivate func writeExceptionInfo(exception: NSException) {
        guard let url = exceptionInfoURL else {
            return
        }

        let info = ExceptionInfo(exception: exception)

        try? info.write(to: url)
    }
}

private func writeException(_ exception: NSException) {
    let logger = UncaughtExceptionLogger.logger

    logger.writeExceptionInfo(exception: exception)

    logger.existingHandler?(exception)
}
