[![License][license badge]][license]

# MeterReporter
Lightweight MetricKit-based diagnostics reporting.

MeterReporter will capture MetricKit payloads. It will then use [Meter](https://github.com/ChimeHQ/Meter) to process and symbolicate them. The resulting data is very close to the MetricKit JSON structure. But, it does add some fields to support the additional features.

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

MeterReporter can capture uncaught NSExceptions on macOS. Unfortunately, AppKit interfers with the flow of runtime exceptions. If you want to capture information about uncaught exceptions, some extra work is required.

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

The request made to the endpoint will be an HTTP `PUT`.

- `Content-Type` will be `application/vnd.chimehq-mxdiagnostic`
- `MeterReporter-Report-Id` as the supplied report id
- `MeterReporter-Platform`
- `MeterReporter-Host-Id` if configuration.hostIdentifier is non-nil

## Suggestions or Feedback
We'd love to hear from you! Get in touch via [twitter](https://twitter.com/ChimeHQ), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/MeterReporter
