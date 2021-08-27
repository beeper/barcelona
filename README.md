# Barcelona
A Swift framework for interacting with iMessage.

## Getting Started

### Prerequisites
These are not strict requirements – this project is simply only ensured to build on the following specs:

- Xcode 12.4
- macOS Big Sur

### Building

> Heads up! Barcelona requires `xcpretty` to build using the Makefiles. Install it using `sudo gem install xcpretty`

| Host  | Grapple            | Mautrix            |
|-------|--------------------|--------------------|
| macOS | make grapple-macos | make mautrix-macos |
| iOS   | make grapple-ios   | make mautrix-ios   |

### Running

Barcelona has three requirements to run correctly:

- SIP must be disabled (`csrutil disable` from recovery mode)
- AMFI must be disabled (`nvram boot-args=amfi_get_out_of_my_way=0x1`)

#### Grapple

Grapple is a debugging tool used to inspect the iMessage environment. A help page is displayed by just running `./grapple`

#### Mautrix

`barcelona-mautrix` is a driver for connecting to matrix, via [matrix-imessage](https://github.com/mautrix/imessage). **This driver is in heavy development and stability is not guaranteed. You will find bugs! Please open issues as you find them so we can improve the driver.**

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
- **[Eric Rabil](https://twitter.com/ericrabil)** – Creator and maintainer
- [Other Contributors](https://github.com/open-imcore/imessage-rest/contributors)

## License
This project is licensed under the Apache 2 license – see the [LICENSE.md](LICENSE.md) for details.

## Acknowledgments
- I could not have done this without [Hopper](https://www.hopperapp.com/) – It is an excellent tool for reverse-engineering and I have spent countless hours using it for this project.
- The Messages team has fleshed out a truly remarkable ecosystem of frameworks and daemons. The struggles working with these APIs were due to a lack of documentation – the frameworks themselves are very feature-rich and easy to use once properly understood.
