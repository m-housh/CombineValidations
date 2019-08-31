//
//  PassthroughValidatedSubject.swift
//  
//
//  Created by Michael Housh on 8/27/19.
//

import Combine
import Validations



public final class PassthroughValidatedSubject<T>: ValidatedSubject<T, PassthroughSubject<T, Never>> {
    
    public init(_ validator: Validator<T>) {
        super.init(validator: validator, subject: PassthroughSubject<T, Never>())
    }
    
    public init(_ validator: @escaping () -> Validator<T>) {
        super.init(validator: validator(), subject: PassthroughSubject<T, Never>())
    }
}


extension PassthroughValidatedSubject where T: Validatable {
    
    public convenience init(_ type: T.Type? = nil) {
        self.init(Validator<T>.valid)
    }
}


public class ValidatedSubject<T, S>: Subject where S: Subject, S.Output == T, S.Failure == Never {
    
    public typealias Output = T
    public typealias Failure = Never
    
    public let validator: Validator<T>
    private let subject: S
    
    public init(validator: Validator<T>, subject: S) {
        self.validator = validator
        self.subject = subject
    }
    
    public func send(_ value: PassthroughValidatedSubject<T>.Output) {
        if let _ = try? validator.validate(value) {
            subject.send(value)
        }
    }
    
    public func send(completion: Subscribers.Completion<PassthroughValidatedSubject<T>.Failure>) {
        subject.send(completion: completion)
    }
    
    public func send(subscription: Subscription) {
        subject.send(subscription: subscription)
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
}
