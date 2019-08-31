//
//  Publishers+ValidatedPublisher.swift
//  
//
//  Created by Michael Housh on 8/31/19.
//

<<<<<<< HEAD
import Combine
import Validations

=======
import Validations
import Combine
>>>>>>> master


extension Publishers {
    
<<<<<<< HEAD
    
    public struct ValidatedPublisher<T>: Publisher {
        public typealias Output = T?
        public typealias Failure = Never
        
        let output: T
        let validator: Validator<T>
        
        public init(_ output: T, _ validator: Validator<T>) {
            self.validator = validator
            self.output = output
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = _ValidationSubscription(downstream: subscriber, output: validated)
            subscriber.receive(subscription: subscription)
        }
        
        private var validated: T? {
=======
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
>>>>>>> master
            do {
                try validator.validate(output)
                return output
            } catch {
                return nil
            }
        }
    }
}

<<<<<<< HEAD
extension Publishers.ValidatedPublisher where T: Validatable {
    
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
    }
}

extension Publishers.ValidatedPublisher {
    
    final class _ValidationSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output {
        
        var downstream: Downstream?
=======
extension Publishers.ValidatedPublisher {
    
    final class _ValidatedSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        
        var downstream: Downstream? = nil
>>>>>>> master
        let output: T?
        
        init(downstream: Downstream, output: T?) {
            self.downstream = downstream
            self.output = output
        }
        
<<<<<<< HEAD
        func cancel() {
            downstream = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            guard let downstream = self.downstream, demand > 0 else { return }
=======
        func request(_ demand: Subscribers.Demand) {
            guard let downstream = self.downstream, demand > 0 else {
                return
            }
>>>>>>> master
            
            _ = downstream.receive(output)
            downstream.receive(completion: .finished)
            cancel()
        }
        
<<<<<<< HEAD
=======
        func cancel() {
            downstream = nil
        }
    }
}

extension Publishers.ValidatedPublisher where T: Validatable {
    
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
>>>>>>> master
    }
}
