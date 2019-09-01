//
//  Publishers+ValidatedPublisher.swift
//  
//
//  Created by Michael Housh on 8/31/19.
//

import Combine
import Validations


extension Publishers {

    /**
     # ValidationPublisher
        
        A top level publisher that passes validated values or `nil` to downstream subscribers.
     
            ```
                _ = ValidatedPublisher("foo-bar", !.empty && .count(3...))
                    .replaceNil(with: "Failed"
                    .sink { print($0) }
     
                // "foo-bar"
            ```
     
     */
    public struct ValidatedPublisher<T>: Publisher {
       
        /// The output type of this publisher.
        public typealias Output = T?
        
        /// The failure type of this publisher.
        public typealias Failure = Never
        
        /// The output that will be validated before passed to downstream subscribers.
        public let output: T
        
        /// The validator we will use to validate objects before sending them downstream.
        public let validator: Validator<T>
        
        /// Initializes a new `ValidatedPublisher` with the provided output and validator.
        ///
        /// - parameter output: The output to validate before sending downstreaam
        /// - parameter validator: The validator to use to validate the output.
        ///
        public init(_ output: T, _ validator: Validator<T>) {
            self.output = output
            self.validator = validator
        }
        
        /// Attaches a downstreaam `Subscriber` that will receive validated values or `Failure`'s
        ///
        /// - parameter subscriber:  The downstream subscriber to attach.
        ///
        /// - SeeAlso: `Publisher`
        ///
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            //
            let subscription = _ValidatedSubscription(downstream: subscriber, output: validated())
            subscriber.receive(subscription: subscription)
        }
        
        /// Validates the output and returns validated output or `nil`.
        private func validated() -> T? {
            do {
                try validator.validate(output)
                return output
            } catch {
                return nil
            }
        }
    }
}

extension Publishers.ValidatedPublisher where T: Validatable {
    
    /// Initializes a new `ValidatedPublisher` with the provided output when the output is also `Validatable`
    ///
    /// - parameter output: The output to validate before sending downstreaam
    ///
    ///  - SeeAlso: `Validatable`
    ///
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
    }
}


extension Publishers.ValidatedPublisher {
    
    /// Represents our subscriptionn that get's attached when a subscriber get's received.
    private final class _ValidatedSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        
        /// The downstream subscriber.
        var downstream: Downstream? = nil
        
        /// The output that has been pre-validated.
        let output: T?
        
         /// Initializes a new subscription with the downstream subscriber and pre-validated output.
        init(downstream: Downstream, output: T?) {
            self.downstream = downstream
            self.output = output
        }
        
        /// Called when a subscription is cancelled.
        func cancel() {
            downstream = nil
        }
        
        /// The logic on passing values downstream.
        func request(_ demand: Subscribers.Demand) {
            guard let downstream = self.downstream, demand > 0 else {
                return
            }
            
            _ = downstream.receive(output)
            downstream.receive(completion: .finished)
            cancel()
        }
    }
}
