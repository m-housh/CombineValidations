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
     
     */
    public struct ValidatedPublisher<T>: Publisher {
        
        public typealias Output = T?
        public typealias Failure = Never
        
        public let output: T
        public let validator: Validator<T>
        
        public init(_ output: T, _ validator: Validator<T>) {
            self.output = output
            self.validator = validator
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            //
            let subscription = _ValidatedSubscription(downstream: subscriber, output: validated())
            subscriber.receive(subscription: subscription)
        }
        
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
    
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
    }
}


extension Publishers.ValidatedPublisher {
    
    final class _ValidatedSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        
        var downstream: Downstream? = nil
        let output: T?
        
        init(downstream: Downstream, output: T?) {
            self.downstream = downstream
            self.output = output
        }
        
        func cancel() {
            downstream = nil
        }
        

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
