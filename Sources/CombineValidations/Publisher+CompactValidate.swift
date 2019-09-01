//
//  Publisher+CompactValidate.swift
//  
//
//  Created by Michael Housh on 8/28/19.
//

import Combine
import Validations




extension Publisher {
    
    ///  A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.
    ///
    ///  - parameter validator:  The validator to use to validate the upstream output.
    ///  - Returns: A new `CompactValidatePublisher`  that sends valid non-nil objects donwstream.
    ///
    ///```
    ///     _ = Just("Foo-bar")
    ///         .validate(!.empty && .count(3...))
    ///         .sink { print($0) }
    ///     // "Foo-bar"
    /// ```
    ///
    public func compactValidate<T>(_ validator: Validator<T>) -> CompactValidatePublisher<Self> where T == Output {
        return CompactValidatePublisher(upstream: self, validator: validator)
    }
    
    /// A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.
    ///
    /// - parameter validator:  A closure that returns validator to use to validate the upstream output.
    ///
    ///  - Returns: A new `CompactValidatePublisher`  that sends valid non-nil objects donwstream.
    ///
    ///```
    ///     _ = Just("Foo-bar")
    ///         .validate { !.empty && .count(3...) }
    ///         .sink { print($0) }
    ///     // "Foo-bar"
    /// ```
    public func compactValidate<T>(_ validator: @escaping () -> Validator<T>) -> CompactValidatePublisher<Self> where T == Output {
        return CompactValidatePublisher(upstream: self, validator: validator())
    }
    
    ///  A `Combine` operator that validates upstream output that is `Validatable` and sends valid non-nil objects downstream.
    ///
    ///  - Returns: A new `CompactValidatePublisher`  that sends valid non-nil objects donwstream.
    ///  - SeeAlso: `Validatable`
    ///
    ///```
    ///     _ = Just(MyValidatable("foo-bar"))
    ///         .validate()
    ///         .sink { print($0.name) }
    ///     // "foo-bar"
    /// ```
    public func compactValidate<T>() -> CompactValidatePublisher<Self> where T == Output, T: Validatable {
        return CompactValidatePublisher(upstream: self, validator: Validator<T>.valid)
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.  This allows you
    ///  to create a custom `Validator` on the fly.
    ///
    /// - parameter name:  The name for the custom validator.
    /// - parameter closure: Closure that takes an instance and returns the instance if valid or `nil` if not valid.
    ///
    /// - SeeAlso: `Validator`
    ///
    /// ```
    ///     _ = Just("foo-bar")
    ///         .compactValidate(name: "only foo-bar") { string in
    ///             guard string.lowercased() == "foo-bar" else {
    ///                 return nil
    ///             }
    ///             return string
    ///         }
    ///         .sink { print($0) }
    ///
    ///     // "foo-bar"
    ///```
    ///
    public func compactValidate<T>(name: String, _ closure: @escaping (T) -> T?) -> CompactValidatePublisher<Self> where T == Output {
        return compactValidate {
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
 # CompactValidatePublisher
 
 A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.

 */
public struct CompactValidatePublisher<Upstream: Publisher>: Publisher {
    
    /// The output type of this publisher.
    public typealias Output = Upstream.Output
    
    /// The failure type of this publisher.
    public typealias Failure = Upstream.Failure
    
    /// The upstream publisher that we willl receive values from.
    let upstream: Upstream
    
    /// The validator we will use to validate objects before sending them downstream.
    let validator: Validator<Output>
    
    
    /// Attaches a downstreaam `Subscriber` that will receive validated values.
    ///
    /// - parameter subscriber:  The downstream subscriber to attach.
    ///
    /// - SeeAlso: `Publisher`
    ///
    public func receive<Downstream>(subscriber: Downstream) where Downstream: Subscriber, Failure == Downstream.Failure, Output == Downstream.Input {
        let downstream = _ValidationSubscription<Upstream, Downstream>(downstream: subscriber, validator: validator)
        upstream.subscribe(downstream)
    }
}

extension CompactValidatePublisher {
    
    /// The subscription created for our `CompactValidatePublisher` when we receive a subscriber.
    private final class _ValidationSubscription<Upstream: Publisher, Downstream: Subscriber>:
        ValidationSubscription<Upstream, Downstream>, ValidatorOperatorSubscription, Subscriber, CustomStringConvertible
        where Upstream.Failure == Downstream.Failure, Downstream.Input == Upstream.Output {
    
        
        var description: String { return "CompactValidate" }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard !isComplete, let validator = self.validator else { return .none }
            
            var demand: Subscribers.Demand = .none
            
            let cancellable = Just(input)
                .validate(validator)
                .sink { possibleValue in
                    guard let value = possibleValue, let downstream = self.downstream else {
                        return
                    }
                    
                    demand = downstream.receive(value)
                }
            
            cancellable.cancel()
            
            return demand
        }
        
    }
}
