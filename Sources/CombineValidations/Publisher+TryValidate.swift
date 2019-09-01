//
//  Publisher+TryValidate.swift
//
//
//  Created by Michael Housh on 8/27/19.
//

import Combine
import Validations


extension Publisher {
    
    ///  A `Combine` operator that validates upstream output and sends valid objects or a `BasicValidationError` downstream.
    ///
    ///  - parameter validator:  The validator to use to validate the upstream output.
    ///  - Returns: A new `TryValidationPublisher`  that sends valid non-nil objects donwstream.
    ///
    ///```
    ///     _ = Just("")
    ///         .tryValidate(!.empty && .count(3...))
    ///         .replaceError(with: "Failed")
    ///         .sink { print($0) }
    ///     // "Failed"
    /// ```
    ///
    public func tryValidate<T>(_ validator: Validator<T>) -> TryValidationPublisher<Self> where T == Output {
        return TryValidationPublisher(upstream: self, validator: validator)
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid objects or a `BasicValidationError` downstream.
    ///  - parameter validator:  A closure that returns the validator to use to validate the upstream output.
    ///  - Returns: A new `TryValidationPublisher`  that sends valid non-nil objects donwstream.
    ///
    ///```
    ///     _ = Just("")
    ///         .tryValidate { !.empty && .count(3...) }
    ///         .replaceError(with: "Failed")
    ///         .sink { print($0) }
    ///     // "Failed"
    /// ```
    ///
    public func tryValidate<T>(_ validator: @escaping () -> Validator<T>) -> TryValidationPublisher<Self> where T == Output {
        return TryValidationPublisher(upstream: self, validator: validator())
    }
    
    ///  A `Combine` operator that validates upstream output that is `Validatable` and sends valid objects or a `BasicValidationError` downstream.
    ///  - Returns: A new `TryValidationPublisher`  that sends valid non-nil objects donwstream.
    ///
    ///```
    ///     _ = Just(MyValidatable())
    ///         .tryValidate()
    ///         .replaceError(with: MyValidatable("Failed"))
    ///         .sink { print($0.name) }
    ///     // "Failed"
    /// ```
    ///
    public func tryValidate<T>() -> TryValidationPublisher<Self> where T: Validatable, T == Output {
        return TryValidationPublisher(upstream: self, validator: Validator<T>.valid)
    }
    
    ///  A `Combine` operator that creates a custom `Validator` to validate upstream output and sends valid objects or an `Error` downstream.
    ///
    ///  - parameter name: The name for the custom validator
    ///  - parameter closure:  A closure used to validate the output from the upstream publisher.  This closure should throw an error on invalid
    ///             objects or return `Void` for valid objects.
    ///
    ///  - Returns: A new `TryValidationPublisher`  that sends valid non-nil objects donwstream.
    ///
    ///```
    ///     _ = Just("")
    ///         .tryValidate(name: "only foo-bar") { string in
    ///             guard string.lowercased() == "foo-bar" else {
    ///                 throw MyError()
    ///              }
    ///         }
    ///         .replaceError(with: "Failed")
    ///         .sink { print($0) }
    ///     // "Failed"
    /// ```
    ///
    public func tryValidate<T>(name: String, _ closure: @escaping (T) throws -> ()) -> TryValidationPublisher<Self> where T == Output {
        return TryValidationPublisher(upstream: self, validator: Validator<T>(name, closure))
    }
    
}

/**
 # TryValidationPublisher
 
 A `Combine` operator that validates upstream output and sends valid objects or a `BasicValidationError` downstream.
 
 - SeeAlso: `Publisher.tryValidate(_:)`
 
 */
public struct TryValidationPublisher<Upstream: Publisher>: Publisher where Upstream.Failure == BasicValidationError {
    
    /// The output type of this publisher.
    public typealias Output = Upstream.Output
    
    /// The failure type of this publisher.
    public typealias Failure = BasicValidationError
    
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
    public func receive<Downstream>(subscriber: Downstream) where Downstream: Subscriber,
        Failure == Downstream.Failure, Output == Downstream.Input {
        
        let downstream = _ValidationSubscription<Upstream, Downstream>(
            downstream: subscriber,
            validator: validator
        )
        upstream.subscribe(downstream)
    }
    

    /**
     Represents our subscription to pass to the `Upstream` publisher.
     
     */
    private final class _ValidationSubscription<Upstream: Publisher, Downstream: Subscriber>:
        ValidationSubscription<Upstream, Downstream>, ValidatorOperatorSubscription, Subscriber
        where Downstream.Failure == BasicValidationError, Downstream.Input == Upstream.Output,
        Downstream.Failure == Upstream.Failure {
        
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard let validated = try? validate(input) else {
                return .none
            }
            
            switch validated.result {
            case .success(let value):
                guard let value = value else { return .none }
                return validated.downstream.receive(value)
            case .failure(let error):
                let basicError = BasicValidationError(error.localizedDescription)
                validated.downstream.receive(completion: .failure(basicError))
                validator = nil
                return .none
            }
        }
        
    }
}
