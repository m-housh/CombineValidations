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
    public func compactValidate<T>(_ validator: Validator<T>) -> CompactValidatePublisher<Self> where T == Output {
        return CompactValidatePublisher(upstream: self, validator: validator)
    }
    
    /// A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.
    public func compactValidate<T>(_ validator: @escaping () -> Validator<T>) -> CompactValidatePublisher<Self> where T == Output {
        return CompactValidatePublisher(upstream: self, validator: validator())
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.
    public func compactValidate<T>() -> CompactValidatePublisher<Self> where T == Output, T: Validatable {
        return CompactValidatePublisher(upstream: self, validator: Validator<T>.valid)
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid non-nil objects downstream.
    ///
    /// - parameter name:  The name for the custom validator.
    /// - parameter closure: Closure that takes an instance and returns the instance if valid or `nil` if not valid.
    ///
    /// - seealso: `Validator`
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
    
    
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure
    
    let upstream: Upstream
    let validator: Validator<Output>
    
    public func receive<Downstream>(subscriber: Downstream) where Downstream: Subscriber, Failure == Downstream.Failure, Output == Downstream.Input {
        let downstream = _ValidationSubscription<Upstream, Downstream>(downstream: subscriber, validator: validator)
        upstream.subscribe(downstream)
    }
}

extension CompactValidatePublisher {
    
    // The subscription created for our publisher when we receive a subscriber.
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
