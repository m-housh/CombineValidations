import XCTest
import Combine
import CombineValidations



final class CombineValidationsTests: XCTestCase {
    
    func testValidate() {
        
        _ = Just("foo-bar")
            .validate(!.empty && .count(3...))
            .sink { XCTAssertEqual($0, "foo-bar") }
        
        _ = Just("fo")
            .validate { !.empty && .count(3...) }
            .sink { XCTAssertNil($0) }
        
        _ = Just(MyValidatable("foo-bar"))
            .validate()
            .sink { XCTAssertEqual($0!.name, "foo-bar") }
        
        let cancellable = Just(MyValidatable("fo"))
            .validate()
            .sink { XCTAssertNil($0) }
        cancellable.cancel()
        
        let custom = Just("foo")
            .validate(name: "foo-bar only") { string in
                guard let strongString = string as? String, strongString == "foo-bar" else {
                    return nil
                }
                return string
            }
            .sink { XCTAssertNil($0) }
        custom.cancel()
        
        let custom2 = Just("foo-bar")
            .validate(name: "foo-bar only") { string in
                guard string == "foo-bar" else {
                    return nil
                }
                return string
            }
            .sink { XCTAssertEqual($0, "foo-bar") }
        custom2.cancel()
    }
    
    func testTryValidate() {
        
        _ = TestPublisher<String?>("foo-bar")
            .tryValidate(!.nil && !.empty && .count(3...))
            .replaceError(with: nil)
            .sink { XCTAssertEqual($0!, "foo-bar") }
        
        _ = TestPublisher<String?>("fo")
            .tryValidate { !.nil && !.empty && .count(3...) }
           .replaceError(with: nil)
           .sink { XCTAssertNil($0) }
    
        _ = TestPublisher<MyValidatable?>(MyValidatable("foo-bar"))
            .tryValidate { !.nil && .valid }
            .replaceError(with: nil)
            .sink { XCTAssertEqual($0!.name, "foo-bar") }
        
        _ = TestPublisher<MyValidatable>(MyValidatable("foo-bar"))
            .tryValidate()
            .replaceError(with: MyValidatable("failed"))
            .sink { XCTAssertEqual($0.name, "foo-bar") }

        _ = TestPublisher<MyValidatable?>(MyValidatable("fo"))
            .tryValidate { !.nil && .valid }
            .replaceError(with: nil)
            .sink { XCTAssertNil($0) }
        
        let custom = TestPublisher<String?>("foo")
            .tryValidate(name: "foo-bar only") { maybeString in
                guard let string = maybeString, string == "foo-bar" else {
                    //throw BasicValidationError("invalid")
                    throw ValidationPublisherError.hasCompleted
                }
            }
            .replaceError(with: nil)
            .sink { XCTAssertNil($0) }
        custom.cancel()
        
        
        let custom2 = TestPublisher<String?>("foo-bar")
            .tryValidate(name: "foo-bar only") { maybeString in
                guard let string = maybeString, string == "foo-bar" else {
                    throw BasicValidationError("invalid")
                }
            }
            .replaceError(with: nil)
            .sink { XCTAssertEqual($0!, "foo-bar") }
        custom2.cancel()
        

    }
    
    
    
    func testValidatedSubject() {
        let subject = PassthroughValidatedSubject<String>(!.empty && .count(3...))
        
        let cancellable = subject.sink { XCTAssertEqual($0, "foo-bar") }
        
        subject.send("foo-bar")
        cancellable.cancel()
        
        
        subject.send(subscription: Subscriptions.empty)
        subject.send(completion: .finished)
    }
    
    func testValidatedSubjectWithValidatable() {
        let subject = PassthroughValidatedSubject<MyValidatable>()
        
        let cancellable = subject.sink { XCTAssertEqual($0.name, "foo-bar")}
        
        subject.send(MyValidatable("foo-bar"))
        cancellable.cancel()
    }
    
    func testValidatedSubjectDoesNotPassInvalidValues() {
        let subject = PassthroughValidatedSubject<String> { !.empty && .count(3...) }
        
        let cancellable = subject.sink { _ in XCTFail() }
        
        subject.send("fo")
        cancellable.cancel()
    }
    
    func testCompactValidate() {
        
        _ = Just<String?>("foo-bar")
            .compactValidate(.nil || !.empty && .count(3...))
            .sink { XCTAssertEqual($0, "foo-bar") }
        
        _ = Just<String?>(nil)
            .compactValidate(!.nil && !.empty && .count(3...))
            .sink { _ in XCTFail() }
        
        
        _ = Just<String?>("fo")
            .compactValidate { !.nil && !.empty && .count(3...) }
           .sink { _ in XCTFail() }
        
        _ = Just<String?>(nil)
          .compactValidate(!.nil && !.empty && .count(3...))
          .sink { _ in XCTFail() }
        
        _ = Just<MyValidatable>(MyValidatable(""))
            .compactValidate()
            .sink { _ in XCTFail() }
        
        _ = Just<MyValidatable>(MyValidatable("foo-bar"))
            .compactValidate()
            .sink { XCTAssertEqual($0.name, "foo-bar") }
        
        _ = Just<String>("foo-bar")
            .compactValidate(name: "foo-bar only") { string -> String? in
                guard string == "foo-bar" else { return nil }
                return string
            }
            .sink { XCTAssertEqual($0, "foo-bar") }
        
        Just<String?>(nil)
            .compactValidate(name: "foo-bar only") { optionalString -> String? in
                return nil
            }
            .sink { _ in XCTFail() }
            .cancel()
        
        _ = Just<String?>("foo-bar")
            .compactValidate(name: "foo-bar only") { optionalString -> String? in
                return nil
            }
            .sink { _ in XCTFail() }
    }
    
<<<<<<< HEAD
    
    func testValidatedPublisher() {
        _ = Publishers.ValidatedPublisher("foo-bar", !.empty && .count(3...))
            .sink { XCTAssertEqual($0, "foo-bar")}
=======
    func testValidatedPublisher() {
        _ = Publishers.ValidatedPublisher("foo-bar", !.empty && .count(3...))
            .sink { XCTAssertEqual($0, "foo-bar") }
>>>>>>> master
        
        _ = Publishers.ValidatedPublisher("fo", !.empty && .count(3...))
            .sink { XCTAssertNil($0) }
        
        _ = Publishers.ValidatedPublisher(MyValidatable("foo-bar"))
<<<<<<< HEAD
            .sink { XCTAssertEqual($0!.name, "foo-bar")}
        
        _ = Publishers.ValidatedPublisher(MyValidatable())
            .sink { XCTAssertNil($0) }
=======
            .sink { XCTAssertEqual($0!.name, "foo-bar") }
               
        _ = Publishers.ValidatedPublisher(MyValidatable())
            .sink { XCTAssertNil($0) }
        
        
>>>>>>> master
    }
    
    func testTryValidatedPublisher() {
        _ = Publishers.TryValidatedPublisher("foo-bar", !.empty && .count(3...))
            .replaceError(with: "failed")
<<<<<<< HEAD
            .sink { XCTAssertEqual($0, "foo-bar")}
=======
            .sink { XCTAssertEqual($0, "foo-bar") }
>>>>>>> master
        
        _ = Publishers.TryValidatedPublisher("fo", !.empty && .count(3...))
            .replaceError(with: "failed")
            .sink { XCTAssertEqual($0, "failed") }
        
<<<<<<< HEAD
        
        _ = Publishers.TryValidatedPublisher(MyValidatable("foo-bar"))
            .replaceError(with: MyValidatable("failed"))
            .sink { XCTAssertEqual($0.name, "foo-bar")}
        
        _ = Publishers.TryValidatedPublisher(MyValidatable())
            .replaceError(with: MyValidatable("failed"))
            .sink { XCTAssertEqual($0.name, "failed")}
=======
        _ = Publishers.TryValidatedPublisher(MyValidatable("foo-bar"))
            .replaceError(with: MyValidatable("failed"))
            .sink { XCTAssertEqual($0.name, "foo-bar") }
               
        _ = Publishers.TryValidatedPublisher(MyValidatable())
            .replaceError(with: MyValidatable("failed"))
            .sink { XCTAssertEqual($0.name, "failed") }
        
>>>>>>> master
        
    }
    

    static var allTests = [
        ("testValidate", testValidate),
        ("testTryValidate", testTryValidate),
        ("testValidatedSubject", testValidatedSubject),
        ("testValidatedSubjectWithValidatable", testValidatedSubjectWithValidatable),
        ("testValidatedSubjectDoesNotPassInvalidValues", testValidatedSubjectDoesNotPassInvalidValues),
        ("testCompactValidate", testCompactValidate),
        ("testValidatedPublisher", testValidatedPublisher),
        ("testTryValidatedPublisher", testTryValidatedPublisher),

    ]
}


// MARK: - Helpers
final class MyValidatable: Codable, Validatable, Reflectable {
    
    let name: String
    
    init(_ name: String = "") {
        self.name = name
    }
    
    static func validations() throws -> Validations<MyValidatable> {
        var validations = Validations(MyValidatable.self)
        try validations.add(\.name, !.empty && .count(3...))
        return validations
    }
}


struct TestPublisher<T>: Publisher {
    
    
    
    typealias Output = T
    typealias Failure = BasicValidationError
    
    let output: T
    
    init(_ output: T) {
        self.output = output
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        //subscribe(subscriber)
        let subscription = Inner(value: output, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }

    class Inner<Downstream: Subscriber>: Subscription where Downstream.Failure == BasicValidationError {
        
        var downstream: Downstream?
        let output: Downstream.Input
        
        init(value: Downstream.Input, downstream: Downstream) {
            self.downstream = downstream
            self.output = value
        }
        
        
        func request(_ demand: Subscribers.Demand) {
            if let downstream = self.downstream, demand > 0 {
                _ = downstream.receive(output)
                downstream.receive(completion: .finished)
                self.downstream = nil
            }
        }
        
        func cancel() {
            downstream = nil
        }
    }
}

extension Just: Subscriber {
    
    public func receive(completion: Subscribers.Completion<Never>) {
        //
    }
    
    
    
    public func receive(_ input: Output) -> Subscribers.Demand {
        return .none
    }
    
    public func receive(subscription: Subscription) {
        //print("JUST SUBSCRIPTION: \(subscription)")
    }
    
    public typealias Input = Output
    public var combineIdentifier: CombineIdentifier { return CombineIdentifier() }
}

