<div align="center">

[![Platforms][platforms badge]][platforms]
[![Matrix][matrix badge]][matrix]

</div>

# MeterReporter
Lightweight MetricKit-based diagnostics reporting.

MeterReporter will capture MetricKit payloads and relay them to a backend. It uses [Meter](https://github.com/ChimeHQ/Meter) to process and symbolicate payloads. The resulting data is very close to the MetricKit JSON structure. But, it does add some fields to support the additional features.

## Integration
```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/MeterReporter")
]
```

## Usage

```swift
let url = URL(string: "https://my.backend.com/reports")!

var config = MeterReporter.Configuration(endpointURL: url)

config.hostIdentifier = Bundle.main.bundleIdentifier

let reporter = MeterReporter(configuration: config)

reporter.start()
```

## Background Uploads

By default, MeterReporter uses `URLSession` background uploads for both reliability and performance. However, sometimes these can take **hours** for the OS to actually execute. This can be a pain if you are just testing things out. To make that easier, you can disable background uploads with another property of `MeterReporter.Configuration`.

## NSException Capture

MeterReporter can capture uncaught NSExceptions on macOS. Unfortunately, AppKit interfers with the flow of runtime exceptions. If you want to get this information about uncaught exceptions, some extra work is required.

The top-level `NSApplication` instance for your app must be a subclass of `ExceptionLoggingApplication`.

```swift
import MeterReporter

class Application: ExceptionLoggingApplication {
}
```

and, you must update your Info.plist to ensure that the `NSPrincipalClass` key references this class with `<App Module Name>.Application`.

I realize this is a huge pain. If you feel so motivated, please file feedback with Apple to ask them to make AppKit behave like UIKit in this respect.

I would also strongly recommend setting the `NSApplicationCrashOnExceptions` defaults key to true. The default setting will allow your application to continue executing post-exception, virtually guaranteeing state corruption and incorrect behavior.

## Submission Request

The request made to the endpoint will be an HTTP `PUT`. The request will also set some headers.

- `Content-Type` will be `application/vnd.chimehq-mxdiagnostic`
- `MeterReporter-Report-Id` will be a unique identifier
- `MeterReporter-Platform`
- `MeterReporter-Host-Id` if `configuration.hostIdentifier` is non-nil

The data itself is the result of Meter's `DiagnosticPayload.jsonRepresentation()`.

## Suggestions or Feedback

I would love to hear from you! Issues or pull requests work great. A [Matrix space][matrix] is also available for live help, but I have a strong bias towards answering in the form of documentation.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[platforms]: https://swiftpackageindex.com/ChimeHQ/MeterReporter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FMeterReporter%2Fbadge%3Ftype%3Dplatforms
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
