//
//  PassthroughValidatedSubject.swift
//  
//
//  Created by Michael Housh on 8/27/19.
//

import Combine
import Validations


/**
 # PassthroughValidatedSubject
 
 A `Combine` `Subject` that you send values to and it will send validated objects only to downstream subscribers.
 
 ```
     let subject = PassthroughValidatedSubject(String.self) {
         !.empty && .count(3...)
     }

     let cancellable = subject.sink { print($0) }

     subject.send("foo-bar")
     // foo-bar

     subject.send("")
     // does not get sent to downstreams.
```
 
 */
public final class PassthroughValidatedSubject<T>: ValidatedSubject<T, PassthroughSubject<T, Never>> {
    
    /// Initializes a new instance.
    ///
    ///  - parameter type: Our output type
    ///  - parameter validator: The validator used to validate input before sending downstream.
    ///
    ///  ```
    ///  let subject = PassthroughValidatedSubject(String.self, !.empty && .count(3...))
    ///  ```
    ///
    public init(_ type: T.Type, _ validator: Validator<T>) {
        super.init(validator: validator, subject: PassthroughSubject<T, Never>())
    }
    
    /// Initializes a new instance.
    ///
    ///  - parameter type: Our output type
    ///  - parameter validator: A closure that returns a validator used to validate input before sending downstream.
    ///
    ///  ```
    ///  let subject = PassthroughValidatedSubject(String.self) { !.empty && .count(3...) }
    ///  ```
    ///
    public init(_ type: T.Type, _ validator: @escaping () -> Validator<T>) {
        super.init(validator: validator(), subject: PassthroughSubject<T, Never>())
    }
    
    /// Initializes a new instance.
    ///
    ///  - parameter validator: The validator used to validate input before sending downstream.
    ///
    ///  ```
    ///  let subject = PassthroughValidatedSubject<String>(!.empty && .count(3...))
    ///  ```
    ///
    public init(_ validator: Validator<T>) {
        super.init(validator: validator, subject: PassthroughSubject<T, Never>())
    }
    
    /// Initializes a new instance.
    ///
    ///  - parameter validator: A closure that returns a validator used to validate input before sending downstream.
    ///
    ///  ```
    ///  let subject = PassthroughValidatedSubject<String> { !.empty && .count(3...) }
    ///  ```
    ///
    public init(_ validator: @escaping () -> Validator<T>) {
        super.init(validator: validator(), subject: PassthroughSubject<T, Never>())
    }
}


extension PassthroughValidatedSubject where T: Validatable {
    
    /// Initializes a new instance when our output is `Validatable`
    ///
    ///  - parameter type: The `Validatable` type that is our output.
    ///
    ///  ```
    ///  let subject = PassthroughValidatedSubject<MyValidatable>()
    ///  // or
    ///  let subject = PassthroughValidatedSubject(MyValidatable.self)
    ///  ```
    ///
    public convenience init(_ type: T.Type? = nil) {
        self.init(Validator<T>.valid)
    }
}

/**
 # ValidatedSubject
 
 A base class that can be used to wrap any `Subject` type and sends validated objects to downstream subscribers.
 
 */
public class ValidatedSubject<T, S>: Subject where S: Subject, S.Output == T, S.Failure == Never {
    
    /// The output type.
    public typealias Output = T
    
    /// The failure type.
    public typealias Failure = Never
    
    /// The validator used to validate objects before sending them to downstream subscribers.
    public let validator: Validator<T>
    
    /// The `Subject` type we are wrapping.
    private let subject: S
    
    /// Initializes a new instance.
    ///
    /// - parameter validator: The validator to use to validate objects.
    /// - parameter subject: The `Subject` type we are wrapping.
    ///
    public init(validator: Validator<T>, subject: S) {
        self.validator = validator
        self.subject = subject
    }
    
    /// Validates the value before sending it to downstream subscribers.
    ///
    /// - parameter value: The value to validate before sendiing downstream.
    ///
    /// - SeeAlso: `Subject`
    public func send(_ value: T) {
        if let _ = try? validator.validate(value) {
            subject.send(value)
        }
    }
    
    /// Signals a completion.
    /// - SeeAlso: `Subject`
    public func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }
    
    
    ///  Attaches a new subscription.
    /// - SeeAlso: `Subject`
    public func send(subscription: Subscription) {
        subject.send(subscription: subscription)
    }
    
    /// Attaches a new subscriber.
    /// - SeeAlso: `Subject`
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
}
