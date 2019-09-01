//
//  ValidationSubscription.swift
//  
//
//  Created by Michael Housh on 8/27/19.
//

import Validations
import Combine


// MARK: - ValidationSubscription
/**
 A base class for our `Combine` operator subscriptions.  Classes still need to inherit from `ValidatorOperatorSubscription`.
 
 */
internal class ValidationSubscription<Upstream: Publisher, Downstream: Subscriber> {
    
    /// The upstream `Publisher` type.
    typealias Upstream = Upstream
    
    /// The downstream `Subscriber` type.
    typealias Downstream = Downstream
    
    /// The `Validator` to use to validate objects before sending downstream.
    /// This should never be `nil` unless we have failed or completed.
    var validator: Validator<Upstream.Output>? = nil
    
    /// The downstream `Subscriber` to send validated values to.
    /// This should never be `nil` unless we have failed or completed.
    var downstream: Downstream?
    
    /// The upstream `Subscription` that we receive values from.
    /// This should never be `nil` unless we have failed or completed.
    var upstreamSubscription: Subscription? = nil
    
    /// Let's us know if we've completed or failed.
    var isComplete: Bool {
        return downstream == nil || validator == nil
    }
    
    /// Initializes a new instance wiith the appropriate downstream `Subscriber` and `Validator`
    ///
    /// - parameter downstream: The downstream `Subscriber` to send validated values to.
    /// - parameter validator: The `Validatoor` used to validate objects before sending downstream.
    ///
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
/**
# ValidatorOperatorSubscription

A generic representation of a `Subscription` used for an operator type publisher.  That can validate values before
 sending to downstream `Subscribers`.  `Subscription`'s are class constrained.

*/
protocol ValidatorOperatorSubscription: OperatorSubscription {
    
    /// The `Validator` to use to validate objects before sending downstream.
    /// This should never be `nil` unless we have failed or completed.
    var validator: Validator<Upstream.Output>? { get set }
    
    
    /// Validates upstream output.
    ///
    /// - parameter input: The upstream output to validate before passing downstream.
    ///
    /// - Throws: `ValidationPublisherError` if we have already failed or completed.
    ///
    /// - Returns: `ValidationResult`
    ///
    func validate(_ input: Upstream.Output) throws -> ValidationResult<Self>
    
    
    /// Initializes a new instance wiith the appropriate downstream `Subscriber` and `Validator`
    ///
    /// - parameter downstream: The downstream `Subscriber` to send validated values to.
    /// - parameter validator: The `Validatoor` used to validate objects before sending downstream.
    ///
    init(downstream: Downstream, validator: Validator<Upstream.Output>)
}

extension ValidatorOperatorSubscription {
    
    /// Called when complete.
    /// - SeeAlso: `Cancellable`
    func cancel() {
        upstreamSubscription?.cancel()
        downstream = nil
        upstreamSubscription = nil
        validator = nil
    }
    
    /// Validates upstream output.
    ///
    /// - parameter input: The upstream output to validate before passing downstream.
    ///
    /// - Throws: `ValidationPublisherError` if we have already failed or completed.
    ///
    /// - Returns: `ValidationResult`
    ///
    func validate(_ input: Upstream.Output) throws -> ValidationResult<Self> {
        return try ValidationResult(self, input)
    }
       
}


extension ValidatorOperatorSubscription where Self: Subscriber {
    
    /// The accepted input type.
    /// - SeeAlso: `Subscriber`
    typealias Input = Upstream.Output
    
    /// The failure type.
    /// - SeeAlso: `Subscriber`
    typealias Failure = Downstream.Failure
}


/**
 # ValidationResult
 
 An internal type that ensures a `ValidatorOperatorSubscription` has not completed or failed
 and validates  upstream output.
 
 */
internal struct ValidationResult<Subscription: ValidatorOperatorSubscription> {
    
    /// The `ValidatorOperatorSubscription`
    let instance: Subscription
    
    /// The downstream `Subscriber` that is attached to our `instance`
    let downstream: Subscription.Downstream
    
    /// The `Validator` used to validate the upstream output.
    let validator: Validator<Subscription.Upstream.Output>
    
    /// The validated `Result`.
    let result: Result<Subscription.Upstream.Output?, BasicValidationError>
    
    /// Initialiizes a new instance with the give `ValidatorOperatorSubscription` and `input` value to validate.
    ///
    /// - parameter subscription: The `ValidatorOperatorSubscription` for this result.
    /// - parameter input: The upstream output to validate.
    ///
    /// - Throws: `ValidationPublisherError` if the subscription has completed or failed already.
    /// - Returns: A new `ValidationResult` with all the strong values needed to pass validated input or failures to
    ///             downstream subscribers.
    ///
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
