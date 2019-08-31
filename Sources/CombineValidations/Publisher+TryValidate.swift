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
    public func tryValidate<T>(_ validator: Validator<T>) -> TryValidationPublisher<Self> where T == Output {
        return TryValidationPublisher(upstream: self, validator: validator)
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid objects or a `BasicValidationError` downstream.
    public func tryValidate<T>(_ validator: @escaping () -> Validator<T>) -> TryValidationPublisher<Self> where T == Output {
        return TryValidationPublisher(upstream: self, validator: validator())
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid objects or a `BasicValidationError` downstream.
    public func tryValidate<T>() -> TryValidationPublisher<Self> where T: Validatable, T == Output {
        return TryValidationPublisher(upstream: self, validator: Validator<T>.valid)
    }
    
    ///  A `Combine` operator that validates upstream output and sends valid objects or an `Error` downstream.
    public func tryValidate<T>(name: String, _ closure: @escaping (T) throws -> ()) -> TryValidationPublisher<Self> where T == Output {
        return TryValidationPublisher(upstream: self, validator: Validator<T>(name, closure))
    }
    
}

/**
 # TryValidationPublisher
 
 A `Combine` operator that validates upstream output and sends valid objects or a `BasicValidationError` downstream.
 
 
 ```
 */
public struct TryValidationPublisher<Upstream: Publisher>: Publisher where Upstream.Failure == BasicValidationError {
    
    public typealias Output = Upstream.Output
    public typealias Failure = BasicValidationError
    
    
    public let upstream: Upstream
    public let validator: Validator<Upstream.Output>
    
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
