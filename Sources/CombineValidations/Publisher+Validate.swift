//
//  Publisher+Validate.swift
//  
//
//  Created by Michael Housh on 8/27/19.
//

import Combine
import Validations


extension Publisher {
    
    ///  A `Combine` operator that validates upstream output and sends valid or `nil` objects downstream.
    ///
    ///  - parameter validator:  The validator to use to validate the upstream output.
    ///  - Returns: A new `ValidationPublisher`  that sends valid objects or `nil` donwstream.
    ///
    ///```
    ///     _ = Just("")
    ///         .validate(!.empty && .count(3...))
    ///         .replaceNil(with: "Failed")
    ///         .sink { print($0) }
    ///     // "Failed"
    /// ```
    ///
    public func validate<T>(_ validator: Validator<T>) -> ValidationPublisher<Self> where T == Output {
        return ValidationPublisher(upstream: self, validator: validator)
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid or `nil` objects downstream.
    ///
    ///  - parameter validator:  A closure that returns a validator to use to validate the upstream output.
    ///  - Returns: A new `ValidationPublisher`  that sends valid objects or `nil` donwstream.
    ///
    ///```
    ///     _ = Just("")
    ///         .validate { !.empty && .count(3...) }
    ///         .replaceNil(with: "Failed")
    ///         .sink { print($0) }
    ///     // "Failed"
    /// ```
    ///
    public func validate<T>(_ validator: @escaping () -> Validator<T>) -> ValidationPublisher<Self> where T == Output {
        return ValidationPublisher(upstream: self, validator: validator())
    }
    
    ///  A `Combine` operator that validates upstream output that is `Validatable` and sends valid  or `nil` objects downstream.
    ///
    ///  - Returns: A new `ValidationPublisher`  that sends valid objects or `nil` donwstream.
    ///
    ///  - SeeAlso: `Validatable`
    ///
    ///```
    ///     _ = Just(MyValidatable())
    ///         .validate()
    ///         .replaceNil(with: MyValidatable("Failed"))
    ///         .sink { print($0.name) }
    ///     // "Failed"
    /// ```
    ///
    public func validate<T: Validatable>() -> ValidationPublisher<Self> where T == Output {
        return ValidationPublisher(upstream: self, validator: Validator<T>.valid)
    }
    
    ///  A `Combine` operator that creates a custom validator to validate upstream output and sends valid  or `nil` objects downstream.
    ///
    /// - parameter name:  The name for the custom validator.
    /// - parameter closure: Closure that takes an instance and returns the instance if valid or `nil` if not valid.
    ///
    /// - seealso: `Validator`
    ///```
    ///     _ = Just("")
    ///         .validate(name: "only foo-bar") { string in
    ///             guard string.lowercased() == "foo-bar" else {
    ///                 return nil
    ///             }
    ///             return string
    ///         }
    ///         .replaceNil(with: "Failed")
    ///         .sink { print($0.name) }
    ///     // "Failed"
    /// ```
    ///
    public func validate<T>(name: String, _ closure: @escaping (T) -> T?) -> ValidationPublisher<Self> where T == Output {
        return validate {
            // Create a custom validator to be used to validate upstream output.
            return Validator<T>(name) { possibleObject in
                guard let _ = closure(possibleObject) else {
                    throw BasicValidationError("\(name) invalid.")
                }
            }
        }
    }
}

/**
 # ValidationPublisher
 
 A `Combine` operator that validates upstream output and sends valid objects or `nil` downstream.
 
 - SeeAlso: `Publisher.validate(_:)`
 
 ### Usage:
 ```swift
 _ = Just("foo-bar")
    .validate { !.empty && .count(3...) }
    .replaceNil(with: "failed")
    .sink { print($0) }
 
 // "foo-bar"
 
 _ = Just("fo")
    .validate { !.empty && .count(3...) }
    .replaceNil(with: "failed")
    .sink { print($0) }
 
 // "failed"
 
 ```
 */
public struct ValidationPublisher<Upstream: Publisher>: Publisher {
    
    /// The output type of this publisher.
    public typealias Output = Upstream.Output?
    
    
    /// The failure type of this publisher.
    public typealias Failure = Upstream.Failure
    
    /// The upstream publisher that we willl receive values from.
    public let upstream: Upstream
    
    /// The validator we will use to validate objects before sending them downstream.
    public let validator: Validator<Upstream.Output>
    
    /// Attaches a downstreaam `Subscriber` that will receive validated values or `Failure`'s
    ///
    /// - parameter subscriber:  The downstream subscriber to attach.
    ///
    /// - SeeAlso: `Publisher`
    ///
    public func receive<Downstream>(subscriber: Downstream) where Downstream: Subscriber, Failure == Downstream.Failure, Output == Downstream.Input {
        
        let downstream = _ValidationSubscription<Upstream, Downstream>(downstream: subscriber, validator: validator)
        upstream.subscribe(downstream)
    }
    
    /**
    Represents our subscription to pass to the `Upstream` publisher.
    
    */
    private final class _ValidationSubscription<Upstream: Publisher, Downstream: Subscriber>: ValidationSubscription<Upstream, Downstream>, ValidatorOperatorSubscription, Subscriber where Downstream.Input == Upstream.Output?, Upstream.Failure == Downstream.Failure {
        
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            
            guard let validated = try? validate(input) else {
                return .none
            }
            
            switch validated.result {
            case .success(let value):
                return validated.downstream.receive(value)
            case .failure(_):
                validator = nil
                return .none
            }
        }
        
    }

}
