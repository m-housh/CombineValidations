//
//  ValidationSubscription.swift
//  
//
//  Created by Michael Housh on 8/27/19.
//

import Validations
import Combine



/**
 A base class for our `Combine` operator subscriptions.  Classes still need to inherit from `ValidatorOperatorSubscription`.
 
 */
internal class ValidationSubscription<Upstream: Publisher, Downstream: Subscriber> {
    
    typealias Upstream = Upstream
    typealias Downstream = Downstream
    
    var validator: Validator<Upstream.Output>? = nil
    var downstream: Downstream?
    var upstreamSubscription: Subscription? = nil
    
    var isComplete: Bool {
        return downstream == nil || validator == nil
    }
    
    required init(downstream: Downstream, validator: Validator<Upstream.Output>) {
        self.validator = validator
        self.downstream = downstream
    }
    
}


// MARK: - OperatorSubscription
/**
 # OperatorSubscription
 
 A generic representation of a `Subscription` used for an operator type publisher.  `Subscription`'s are class constrained.
 
 */
protocol OperatorSubscription: AnyObject, Subscription {
    
    /// The upstream publisher.
    associatedtype Upstream: Publisher
    
    /// The downstream subscriber
    associatedtype Downstream: Subscriber
    
    /// The actual downstream  `Subscriber` instance.
    var downstream: Downstream? { get set }
    
    /// The actual upstream subscription.
    var upstreamSubscription: Subscription? { get set }
    
    /// Let's us know when / if we've completed or been canceled.
    var isComplete: Bool { get }
    
}

extension OperatorSubscription {
    
    /// - seealso: `Subscription`
    func request(_ demand: Subscribers.Demand) {
        guard !isComplete else { return }
        upstreamSubscription?.request(demand)
    }
}

extension OperatorSubscription where Self: Subscriber, Self.Failure == Downstream.Failure {
    
    /// - seealso: `Subscriber`
   func receive(subscription: Subscription) {
       upstreamSubscription = subscription
       downstream?.receive(subscription: self)
   }
    
    /// - seealso: `Subscriber`
    func receive(completion: Subscribers.Completion<Downstream.Failure>) {
        downstream?.receive(completion: completion)
    }
}


// MARK: - ValidatorOperatorSubscription
protocol ValidatorOperatorSubscription: OperatorSubscription {
    
    var validator: Validator<Upstream.Output>? { get set }
    
    func validate(_ input: Upstream.Output) throws -> ValidationResult<Self>
    
    init(downstream: Downstream, validator: Validator<Upstream.Output>)
}

extension ValidatorOperatorSubscription {
    func cancel() {
        upstreamSubscription?.cancel()
        downstream = nil
        upstreamSubscription = nil
        validator = nil
    }
}


extension ValidatorOperatorSubscription where Self: Subscriber {
    typealias Input = Upstream.Output
    typealias Failure = Downstream.Failure
}


extension ValidatorOperatorSubscription {
    
    func validate(_ input: Upstream.Output) throws -> ValidationResult<Self> {
        return try ValidationResult(self, input)
    }
    
}


struct ValidationResult<Subscription: ValidatorOperatorSubscription> {
    
    let instance: Subscription
    let downstream: Subscription.Downstream
    let validator: Validator<Subscription.Upstream.Output>
    let result: Result<Subscription.Upstream.Output?, BasicValidationError>
    
    init(_ subscription: Subscription, _ input: Subscription.Upstream.Output) throws {
        
        guard !subscription.isComplete, let validator = subscription.validator,
            let downstream = subscription.downstream else {
                throw ValidationPublisherError.hasCompleted
        }
        
        self.instance = subscription
        self.downstream = downstream
        self.validator = validator
        
        do {
            try validator.validate(input)
            self.result = .success(input)
        } catch let error {
            self.result = .failure(BasicValidationError(error.localizedDescription))
        }
    }
}
