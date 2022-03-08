#if os(macOS)
import Cocoa
import Meter

public class ExceptionLoggingApplication: NSApplication {
    public var exceptionInfoURL: URL?

    public override func reportException(_ exception: NSException) {
        writeExceptionInfo(with: exception)
        super.reportException(exception)
    }

    private func writeExceptionInfo(with exception: NSException) {
        guard let url = exceptionInfoURL else {
            return
        }

        let info = ExceptionInfo(exception: exception)

        try? info.write(to: url)
    }
}

#endif
