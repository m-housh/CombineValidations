//
//  
//
//  Created by Michael Housh on 8/31/19.
//

import Combine
import Validations



extension Publishers {
        
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
            do {
                try validator.validate(output)
                return .success(output)
            } catch {
                return .failure(BasicValidationError(error.localizedDescription))
            }
        }
    }
}

extension Publishers.TryValidatedPublisher where T: Validatable {
    
    public init(_ output: T) {
        self.output = output
        self.validator = Validator<T>.valid
    }
}


extension Publishers.TryValidatedPublisher {
    
    final class _ValidatedSubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output, Downstream.Failure == Failure {
        
        var downstream: Downstream? = nil
        let output: Result<T, BasicValidationError>
        
        init(downstream: Downstream, output: Result<T, BasicValidationError>) {
            self.downstream = downstream
            self.output = output
        }
        
        func cancel() {
            downstream = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            guard let downstream = self.downstream, demand > 0 else { return }
        
            switch output {
            case .success(let output):
                _ = downstream.receive(output)
                downstream.receive(completion: .finished)
            case .failure(let error):
                downstream.receive(completion: .failure(error))
            }
            cancel()
        }
        
    }
}
