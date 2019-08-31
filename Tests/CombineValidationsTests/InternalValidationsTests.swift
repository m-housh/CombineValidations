//
//  InternalValidationsTests.swift
//  
//
//  Created by Michael Housh on 8/28/19.
//

import XCTest
import Combine
@testable import CombineValidations


class InternalValidationsTests: XCTestCase {
    
    
    func testCancel() {
        
        let downstream = Just("foo-bar")
            //.validate { !.empty && .count(3...) }
        
        let subscription = InternalValidationSubscription<Just<String>, Just<String>>(downstream: downstream, validator: Validator<String>.empty)
        
        subscription.cancel()
        XCTAssertThrowsError(try subscription.validate("bar-foo"))
        
        
    }
    
    func testSubject() {
        
        class MyObject {
            let subject : PassthroughValidatedSubject<String>
            var _name: String? = nil
            
            //let validator: Validator<String>
            var cancellable: AnyCancellable? = nil
            
            var name: String? {
                get { _name }
                set {
                    guard let value = newValue else { return }
                    subject.send(value)
                }
            }
            
            init(_ validator: Validator<String>) {
                self.subject = PassthroughValidatedSubject(validator)
                self.cancellable = subject.sink { self._name = $0 }
            }
            
        }
        
        let m = MyObject(!.empty && .count(3...))
        XCTAssertNil(m.name)
        
        m.name = "fo"
        XCTAssertNil(m.name)
        
        m.name = "foo-bar"
        XCTAssertEqual(m.name, "foo-bar")
    }
    
    
    static var allTests = [
        ("testCancel", testCancel),
    ]
    
}

final class InternalValidationSubscription<Upstream: Publisher, Downstream: Subscriber>: ValidationSubscription<Upstream, Downstream>, ValidatorOperatorSubscription, Subscriber where Upstream.Output == Downstream.Input, Upstream.Failure == Downstream.Failure {
    
    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        return .none
    }
}
