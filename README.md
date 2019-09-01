# CombineValidations

[![Build Status](https://travis-ci.org/m-housh/CombineValidations.svg?branch=develop)](https://travis-ci.org/m-housh/CombineValidations)
[![codecov](https://codecov.io/gh/m-housh/CombineValidations/branch/master/graph/badge.svg)](https://codecov.io/gh/m-housh/CombineValidations)
[![SPM compatible](https://img.shields.io/badge/SPM-Compatible-blueviolet.svg?style=flat)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/iOS-13-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-11-blue.svg)](https://developer.apple.com/xcode)
[![MIT](https://img.shields.io/badge/License-MIT-red.svg)](https://opensource.org/licenses/MIT)


A package of `Combine` operators for validating objects, such as `name`, `email`, etc.  

This includes a stripped down fork of [vapor/validation](https://github.com/vapor/validation), check out their documentation
for more examples.

## Documentation
-------------

For full API documentation you can click [here](https://m-housh.github.io/CombineValidations/index.html).


## Installation
-----------
Just add as a package dependency to your Xcode Project or to your `Package.swift`.
``` swift
// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyProject",
    platforms: [
        .macOS(.v10_15)
        .iOS(.v13)
    ],
    ...
    dependencies: [
        .package(url: "https://github.com/m-housh/CombineValidations.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "MyProject",
            dependencies: ["CombineValidations", ...]
        ),
        ...
    ]
)

```

## Usage
-----------

### Top Level Publishers
------


There are two top level publishers that can be used to validate objects.

#### ValidatedPublisher

The `VaidatedPublisher` passes validated output or `nil` to downstream subscribers.

``` swift

_ = Publishers.ValidatedPublisher("foo-bar", !.empty && .count(3...))
    .replaceNil(with: "failed")
    .sink { print($0) }
// "foo-bar"   
    
_ = Publishers.ValidatedPublisher("foo-bar", !.empty && .count(3...))
    .replaceNil(with: "failed")
    .sink { print($0) }
// "failed"


```

#### TryValidatedPublisher

The `TryVaidatedPublisher` passes validated output or `BasicValidationError` to downstream subscribers.

``` swift

_ = Publishers.TryValidatedPublisher("foo-bar", !.empty && .count(3...))
    .replaceError(with: "failed")
    .sink { print($0) }
// "foo-bar"   
    
_ = Publishers.TryValidatedPublisher("foo-bar", !.empty && .count(3...))
    .replaceError(with: "failed")
    .sink { print($0) }
// "failed"


```

### Operators
--------

There are also three operators that can be applied to existing publishers.

#### Validate

The `Validate` operator, passes validated objects or `nil` to downstream subscribers.
``` swift

_ = Just("foo-bar")
    .validate { !.empty && .count(3...) }
    .replaceNil(with: "failed")
    .sink { print($0) }

// foo-bar

_ = Just("")
    .validate { !.empty && .count(3...) }
    .replaceNil(with: "failed")
    .sink { print($0) }

// failed
```

#### TryValidate

The `TryValidate` operator sends validated objects or `BasicValidatiionError` to downstream subscriibers.

``` swift

_ = Just("foo-bar")
    .tryValidate { !.empty && .count(3...) }
    .replaceError(with: "failed")
    .sink { print($0) }

// foo-bar

_ = Just("")
    .tryValidate { !.empty && .count(3...) }
    .replaceError(with: "failed")
    .sink { print($0) }

// failed
```

#### CompactValidate
The `CompactValidate` operater sends validated non-nil objects to downstream subscribers.
``` swift
_ = Just("foo-bar")
    .compactValidate { !.empty && .count(3...) }
    .sink { print($0) }
    
// foo-bar

_ = Just("foo")
    .compactValidate { !.empty && .count(3...) }
    .sink { print($0) }
    
// nothing get's printed or passed downstream.


```

### Subjects
-------

#### PassthroughValidatedSubject

A `PassthroughValidatedSubject` never fails and only sends values that pass validation
to downstream subscribers.

``` swift

let subject = PassthroughValidatedSubject<String> {
    !.empty && .count(3...)
}

let cancellable = subject.sink { print($0) }

subject.send("foo-bar")
// foo-bar

subject.send("")
// does not get sent to downstreams.

```

### Validatable Objects
--------------

All of the above also work with any type that implements the `Validatable` protocol.

``` swift

class MyValidatable: Codable, Reflectable, Validatable {

    let name: String?
    
    init(_ name: String? = nil) {
        self.name = name
    }
    
    static func validations() throws -> Validations<MyValidatable> {
        var validations = Validations(MyValidatable.self)
        try validations.add(\.name, !.nil && !.empty && .count(3...))
        return validations
    }
}

// Top-Level works the same for `ValidatePublisher` or `TryValidatedPublisher`
_ = Publishers.ValidatedPublisher(MyValidatable("foo-bar"))
    .replaceNil(with: MyValidatable("failed"))
    .sink { print($0.name) }
// foo-bar


// Validate
_ = Just(MyValidatable())
    .validate()
    .replaceNil(with: MyValidator("failed"))
    .sink { print($0!.name) }
    
// failed


// TryValidate
_ = Just(MyValidatable("foo-bar"))
    .tryValidate()
    .replaceError(with: MyValidator("failed"))
    .sink { print($0!.name) }
    
// foo-bar


// Subject
let subject = PassthroughValidatedSubject(MyValidatable.self)
let cancellable = subject.sink { print($0.name) }

subject.send(MyValidatable())
// Not sent

subject.send(MyValidatable("foo-bar"))
// foo-bar


```
