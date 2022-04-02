import Foundation
import Wells
import Meter
import os.log
#if os(macOS)
import AppKit
#endif

extension UUID {
    var lowerAlphaOnly: String {
        return uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

public class MeterReporter {
    private let wellsReporter: WellsReporter
    public var configuration: Configuration
    private let subscriber: DiagnosticSubscriber
    private var log: OSLog { Self.log }
    private static let log = OSLog(subsystem: "com.chimehq.MeterReporter", category: "MeterReporter")

    public init(configuration: Configuration) {
        self.configuration = configuration
        self.subscriber = DiagnosticSubscriber()
        self.wellsReporter = WellsReporter(baseURL: configuration.reportsURL,
                                           backgroundIdentifier: configuration.backgroundIdentifier)

        wellsReporter.locationProvider = IdentifierExtensionLocationProvider(baseURL: configuration.reportsURL,
                                                                             fileExtension: "mxdiagnostic")

        wellsReporter.existingLogHandler = { [weak self] in
            guard let self = self else {
                os_log("deallocated – cannot process log %{public}@", log: Self.log, type: .error, $0.path)
                return
            }
            self.handleExistingLog(at: $0, date: $1)
        }
    }

    public convenience init(endpointURL: URL) {
        self.init(configuration: Configuration(endpointURL: endpointURL))
    }

    public func start() {
        os_log("starting", log: log, type: .debug)

        do {
            try wellsReporter.createReportDirectoryIfNeeded()
        } catch {
            os_log("failed to create reporting directory %{public}@", log: log, type: .error, String(describing: error))
            return
        }

        configureExceptionLogging()

        subscriber.onReceive = { [weak self] in self?.receivedPayloads($0) }
        subscriber.start()
    }

    private var reportDirectoryURL: URL {
        return wellsReporter.baseURL
    }
}

extension MeterReporter {
    public struct Configuration {
        public var endpointURL: URL
        public var hostIdentifier: String?

        public var backgroundIdentifier: String? = WellsUploader.defaultBackgroundIdentifier
        public var reportsURL: URL = WellsReporter.defaultDirectory
        public var log: OSLog = OSLog(subsystem: "com.chimehq.MeterReporter", category: "MeterReporter")
        public var filterSimulatedPayloads = true

        public init(endpointURL: URL) {
            self.endpointURL = endpointURL
        }
    }
}

extension MeterReporter {
    func receivedPayloads(_ payloads: [Data]) {
        os_log("received payloads %{public}d", log: log, type: .info, payloads.count)

        let symbolicator = DlfcnSymbolicator()
        let exceptionInfo = existingExceptionInfo()

        removeExistingExceptionInfo()

        for rawData in payloads {
            let data: Data

            do {
                let payload = try DiagnosticPayload.from(data: rawData)

                if payload.isSimulated && configuration.filterSimulatedPayloads {
                    os_log("skipping simulated payload", log: log, type: .error)
                    continue
                }

                data = processPayload(payload, with: symbolicator, exceptionInfo: exceptionInfo)
            } catch {
                data = rawData
                os_log("failed to decode payload %{public}@", log: log, type: .error, String(describing: error))
            }

            do {
                try submit(data)
            } catch {
                os_log("failed to submit payload %{public}@", log: log, type: .error, String(describing: error))
            }
        }
    }
}

extension MeterReporter {
    private func configureExceptionLogging() {
        #if os(macOS)
        if let app = NSApp as? ExceptionLoggingApplication {
            app.exceptionInfoURL = exceptionInfoURL
        }
        #endif

        UncaughtExceptionLogger.logger.exceptionInfoURL = exceptionInfoURL
    }
    
    private var exceptionInfoURL: URL {
        return reportDirectoryURL.appendingPathComponent("exception_info.json")
    }

    private func existingExceptionInfo() -> ExceptionInfo? {
        let url = exceptionInfoURL

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return nil
        }

        let info: ExceptionInfo?

        do {
            let data = try Data(contentsOf: url)
            info = try JSONDecoder().decode(ExceptionInfo.self, from: data)
        } catch {
            os_log("failed to decode exception_info.json %{public}@", log: log, type: .error, String(describing: error))
            info = nil
        }

        return info
    }

    private func removeExistingExceptionInfo() {
        let url = exceptionInfoURL

        if FileManager.default.fileExists(atPath: url.path) == false {
            return
        }

        removeItem(at: url)
    }

    func processPayload(_ payload: DiagnosticPayload, with symbolicator: Symbolicator, exceptionInfo: ExceptionInfo?) -> Data {
        let symPayload = symbolicator.symbolicate(payload: payload)
        let lastCrash = symPayload.crashDiagnostics?.last

        if let lastCrash = lastCrash, let info = exceptionInfo {
            if info.matchesCrashDiagnostic(lastCrash) {
                lastCrash.exceptionInfo = info
            }
        }

        return symPayload.jsonRepresentation()
    }

    func submit(_ data: Data) throws {
        let id = UUID().lowerAlphaOnly
        let url = reportDirectoryURL.appendingPathComponent(id).appendingPathExtension("mxdiagnostic")

        try data.write(to: url)

        submit(url, identifier: id)
    }

    func submit(_ url: URL, identifier: String? = nil) {
        let id = identifier ?? url.deletingPathExtension().lastPathComponent

        os_log("submitting %{public}@", log: log, type: .info, url.path)

        let request = makeURLRequest(for: id)

        wellsReporter.submit(fileURL: url, identifier: id, uploadRequest: request)
    }

    func removeItem(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            os_log("failed to remove item at %{public}@ %{public}@", log: log, type: .error, url.path, String(describing: error))
        }
    }

    func handleExistingLog(at url: URL, date: Date) {
        if url == exceptionInfoURL {
            os_log("removing existing exception_info.json", log: log, type: .info)
            removeItem(at: url)
            return
        }

        // ~ 7 days
        let oldDate = Date().addingTimeInterval(-7.0 * 24.0 * 60.0 * 60.0)

        if date < oldDate {
            os_log("removing old log %{public}@", log: log, type: .info, url.path)
            removeItem(at: url)
            return
        }

        os_log("resubmitting %{public}@", log: log, type: .info, url.path)

        submit(url)
    }
}

extension MeterReporter {
    private var platformName: String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "unknown"
        #endif
    }

    private func makeURLRequest(for reportID: String) -> URLRequest {
        let url = configuration.endpointURL

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)

        request.httpMethod = "PUT"

        request.addValue(reportID, forHTTPHeaderField: "MeterReporter-Report-Id")
        request.addValue(platformName, forHTTPHeaderField: "MeterReporter-Platform")

        if let host = configuration.hostIdentifier {
            request.addValue(host, forHTTPHeaderField: "MeterReporter-Host-Id")
        }

        request.addValue("application/vnd.chimehq-mxdiagnostic", forHTTPHeaderField: "Content-Type")

        return request
    }
}
