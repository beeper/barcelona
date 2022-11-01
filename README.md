# Barcelona
A Swift framework for interacting with iMessage.

## [Downloads](https://nightly.link/beeper/barcelona/workflows/build/main)

| Host  | Grapple  | Mautrix  |
|-------|----------|----------|
| macOS | [Download](https://nightly.link/beeper/barcelona/workflows/build/main/darwin-grapple.zip) | [Download](https://nightly.link/beeper/barcelona/workflows/build/main/darwin-barcelona-mautrix.zip) |
| iOS   | Unavailable | Unavailable |

## Getting Started

### Prerequisites
These are not strict requirements – this project is simply only ensured to build on the following specs:

- Xcode 12.4
- macOS Big Sur
- Git LFS

### Building

Prepare your system to build Barcelona by following the instructions at [BUILDING.md](BUILDING.md)

Build products go to `./Build/(iOS|macOS)/Products/(Debug|Release)/(barcelona-mautrix|grapple)`

### Running

Prepare your system to run Barcelona tools by following the instructions at [RUNNING.md](RUNNING.md)

#### Grapple

Grapple is a debugging tool used to inspect the iMessage environment. A help page is displayed by just running `./grapple`

##### Grudge

Grudge is a testing suite within Grapple. It is configured from a YML file, and is used to debug Barcelona.

```bash
grapple grudge ./grudge.yml
```

```yml
# Example grudge.yml - everything optional unless stated required - no top level is required, you can mix and match

# Alerts when two message events for the same ID are dispatched
duplicateDetector: true

# Routinely sends messages in a chat to test message processing and delivery
automaticSending:
    chat: "info@orders.apple.com" # chat ID to send to - required
    messages: ["hey", "there", "darling!"] # messages to send, cycles through until stopped - required
    delay: 1000 # milliseconds between messages, minimum 250ms unless count is below 100 - required
    count: 100 # number of messages to send, -1 for infinite
    waitForDelivery: true # whether to wait for delivery before waiting delay
    trackNonAutomated: true # whether to report messages sent from current user that werent part of automaticSending
    tapbacks:
        interval: 10 # every ten messages, tapback the message
        type: 2000 # tapback with a heart
```

#### Mautrix

`barcelona-mautrix` is a driver for connecting to matrix, via [matrix-imessage](https://github.com/mautrix/imessage). **This driver is in heavy development and stability is not guaranteed. You will find bugs! Please open issues as you find them so we can improve the driver.**

Downloads for barcelona-mautrix are currently only available for [macOS](https://nightly.link/beeper/barcelona/workflows/build/main/darwin-barcelona-mautrix.zip). iOS is completely untested and currently not built in CI.

Ensure you have [com.apple.security.xpc.plist](https://github.com/beeper/barcelona/raw/main/com.apple.security.xpc.plist) installed to `/Library/Preferences/com.apple.security.xpc.plist`, as this is required to allow communication with IMDPersistenceAgent directly (imagent does not provide efficient message querying APIs, IMDPersistenceAgent does).

## Built With
- [Swift Package Manager](https://github.com/apple/swift-package-manager) – Dependency management
- [GRDB](https://github.com/groue/GRDB.swift) – Used for SQLite
- [AnyCodable](https://github.com/Flight-School/AnyCodable) – To make my life easier
- The IM family of frameworks
- Tons and tons of love, reverse engineering, and muzzled AMFI

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

### Versioning
We use [SemVer](http://semver.org/) for versioning.

## Authors
* Created by **[Eric Rabil](https://twitter.com/ericrabil)**
* Maintained by **[Beeper](https://www.beeper.com)**
* [Other Contributors](https://github.com/beeper/barcelona/contributors)

## License
This project is licensed under the Apache 2 license – see the [LICENSE.md](LICENSE.md) for details.

## Acknowledgments
- I could not have done this without [Hopper](https://www.hopperapp.com/) – It is an excellent tool for reverse-engineering and I have spent countless hours using it for this project.
- The Messages team has fleshed out a truly remarkable ecosystem of frameworks and daemons. The struggles working with these APIs were due to a lack of documentation – the frameworks themselves are very feature-rich and easy to use once properly understood.
