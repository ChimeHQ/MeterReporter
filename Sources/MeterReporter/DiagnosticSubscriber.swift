import Foundation
#if canImport(MetricKit)
import MetricKit
#endif

class DiagnosticSubscriber: NSObject {
    var onReceive: (([Data]) -> Void)?

    override init() {
        super.init()
    }

    static var metricKitAvailable: Bool {
        #if canImport(MetricKit) && compiler(>=5.5.1)
        if #available(iOS 14.0, macOS 12.0, *) {
            return true
        }
        #endif

        return false
    }

    func start() {
        #if canImport(MetricKit) && compiler(>=5.5.1)
        if #available(iOS 14.0, macOS 12.0, *) {
            MXMetricManager.shared.add(self)
        }
        #endif
    }
}

#if canImport(MetricKit) && compiler(>=5.5.1)
@available(iOS 13.0, macOS 12.0, *)
extension DiagnosticSubscriber: MXMetricManagerSubscriber {
    #if os(iOS)
    @available(iOS 13.0, *)
    func didReceive(_ payloads: [MXMetricPayload]) {
    }
    #endif

    @available(iOS 14.0, macOS 12.0, *)
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        guard payloads.isEmpty == false else { return }

        onReceive?(payloads.map({ $0.jsonRepresentation() }))
    }
}
#endif
