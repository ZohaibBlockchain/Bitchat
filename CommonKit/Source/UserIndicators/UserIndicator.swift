import Foundation
import UIKit

public class UserIndicator {
    public enum State {
        case pending
        case executing
        case completed
    }
    
    private let request: UserIndicatorRequest
    private let completion: () -> Void

    public private(set) var state: State
    
    public init(request: UserIndicatorRequest, completion: @escaping () -> Void) {
        self.request = request
        self.completion = completion
        
        state = .pending
    }
    
    deinit {
        complete()
    }
    
    internal func start() {
        guard state == .pending else {
            return
        }
        
        state = .executing
        // Removed the call to present the UI
        
        switch request.dismissal {
        case .manual:
            // No action needed for manual dismissal
            break
        case .timeout(let interval):
            Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                self?.complete()
            }
        }
    }
    
    public func cancel() {
        complete()
    }
    
    private func complete() {
        guard state != .completed else {
            return
        }
        if state == .executing {
            // Removed the call to dismiss the UI
        }
        
        state = .completed
        completion()
    }
}

public extension UserIndicator {
    func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == UserIndicator {
        collection.append(self)
    }
}

public extension Collection where Element == UserIndicator {
    func cancelAll() {
        forEach {
            $0.cancel()
        }
    }
}
