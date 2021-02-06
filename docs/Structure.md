# Project Structure
The project is broken down into five components.

## [CoreBarcelona](../CoreBarcelona)
This is the framework where all bindings with IMCore happen. There's no REST logic here – this is simply a wrap of the IMCore library for our purposes. It provides many conveniences for sending messages, attachments, interacting with plugin payloads, sending replies, and more.

## [BarcelonaVapor](../BarcelonaVapor)
This framework is responsible for the binding between CoreBarcelona and the Vapor framework. It provides all the API and streaming endpoints, along with bindings for the notification center.

## [BarcelonaSharedUI](../BarcelonaSharedUI)
This framework provides shared SwiftUI components for iOS and macOS

## [BarcelonaFoundation](../BarcelonaFoundation)
This framework provides shared logic between multiple components of the project

## [SPMLibraries](../SPMLibraries)
This is a stub project that allows us to refer to the same set of SPM libraries from multiple targets. This cuts down on build size and is simply an optimization.

## [imessage-rest](../imessage-rest)
This is the XPC service where the daemon lives. It can be run directly if you pass `ERRunningOutOfAgent=1` as an environment variable. This XPC service is platform-independent and will run on both macOS and iOS.

## [imessage-rest-mac-controller](../imessage-rest-mac-controller)
This is the app responsible for communicating with the daemon on macOS. Currently, the daemon is embedded in this app and cannot run without the app running. This will be changed when the project is further along. This app may even be replaced eventually.

## MyMessage for iOS
This is the app responsible for communicating with the daemon on iOS. The daemon on iOS resides outside the app and the app is simply responsible for waking the ademon and killing it when it is no longer needed.