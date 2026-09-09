[![Unit Tests](https://github.com/Adyen/adyen-networking-ios/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/Adyen/adyen-networking-ios/actions/workflows/unit-tests.yml)

# Adyen Networking for iOS

Adyen Networking for iOS provides reusable and user-friendly, generic http/https API client functionalities.

## Requirements

- iOS 12.0+
- Xcode 12.0+
- Swift 5.3

## Installation

Adyen Networking for iOS are available through either [CocoaPods](http://cocoapods.org) or [Swift Package Manager](https://swift.org/package-manager/).

### CocoaPods

1. Add `pod 'AdyenNetworking'` to your `Podfile`.
2. Run `pod install`.

### Swift Package Manager

1. Follow Apple's [Adding Package Dependencies to Your App](
https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app
) guide on how to add a Swift Package dependency.
2. Use `https://github.com/Adyen/adyen-networking-ios` as the repository URL.
3. Specify the version to be at least `1.0.0`.

## Usage

1. Create a `class/struct` that conforms to `AnyAPIContext`, to define the API that you're going to call.
2. Create a `class/struct` that conforms to `Request` protocol and another one conforming to the corresponding `Response` protocol for each endpoint you want to call from the API you defined in step 1.
3. Create an instance of  `APIClient` or one of the other convenience `APIClientProtocol` implementations, and perform the request:

```Swift
let apiClient = APIClient(apiContext: APIContext())
let request = GetUsersRequest()
apiClient.perform(request) { result in
    switch result {
    case let .success(response):
        print(response)
    case let .failure(error):
        print(error)
    }
}
```

:warning: _Please make sure to retain the `APIClient` instance, otherwise the completion handler will not be called._

## Testing

Running End-to-End Tests

Our `EndToEndTests` interact with the gorest.co.in API and require bearer authentication.

To run these tests locally:
1. Generate a Token: Obtain your personal bearer token from [gorest.co.in](https://gorest.co.in/).
2. Create DevSecrets.xcconfig: In the root directory of this project, create a new file named DevSecrets.xcconfig.
3. Add Your Token: Copy the content from DevSecrets.xcconfig.template into your new DevSecrets.xcconfig file. Replace the placeholder token with the actual bearer token you generated.

## Support

If you have a feature request, or spotted a bug or a technical problem, create a GitHub issue. For other questions, contact our Support Team via [Customer Area](https://ca-live.adyen.com/ca/ca/contactUs/support.shtml) or via email: support@adyen.com

## Contributing
We strongly encourage you to join us in contributing to this repository so everyone can benefit from it:
* New features and functionality
* Resolved bug fixes and issues
* Any general improvements


Read our [**contribution guidelines**](CONTRIBUTING.md) to find out how.

## License

This repository is open source and available under the MIT license. For more information, see the LICENSE file.
