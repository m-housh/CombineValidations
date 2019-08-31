//
<<<<<<< HEAD
//  File.swift
=======
//  Publishers+TryValidatedPublisher.swift
>>>>>>> master
//  
//
//  Created by Michael Housh on 8/31/19.
//

import Combine
import Validations



extension Publishers {
    
    
<<<<<<< HEAD
    public struct TryValidatedPublisher<T>: Publisher {
        public typealias Output = T
        public typealias Failure = BasicValidationError
        
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
        
        private var validated: Result<T, BasicValidationError> {
=======
    /**
     # TryValidatedPublisher
     
        A top level publisher that passes validated values or `BasicValidationError` to downstream subscribers.
     
     */
    public struct TryValidatedPublisher<T>: Publisher {
        
        public typealias Output = T
        public typealias Failure = BasicValidationError
        
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
        
        private func validated() -> Result<T, BasicValidationError> {
>>>>>>> master
            do {
                try validator.validate(output)
                return .success(output)
            } catch {
                return .failure(BasicValidationError(error.localizedDescription))
            }
        }
    }
}

<<<<<<< HEAD
extension Publishers.TryValidatedPublisher where T: Validatable {
    
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
    }
}

extension Publishers.TryValidatedPublisher {
    
    final class _ValidationSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        
        var downstream: Downstream?
=======
extension Publishers.TryValidatedPublisher {
    
    final class _ValidatedSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        
        var downstream: Downstream? = nil
>>>>>>> master
        let output: Result<T, BasicValidationError>
        
        init(downstream: Downstream, output: Result<T, BasicValidationError>) {
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
            
            switch output {
            case .success(let output):
                _ = downstream.receive(output)
                downstream.receive(completion: .finished)
<<<<<<< HEAD
            case .failure(let error):
                downstream.receive(completion: .failure(error))
            }
            cancel()
        }
        
=======
                cancel()

            case .failure(let error):
                downstream.receive(completion: .failure(error))
            }
            
        }
        
        func cancel() {
            downstream = nil
        }
    }
}


extension Publishers.TryValidatedPublisher where T: Validatable {
    
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
>>>>>>> master
    }
}

