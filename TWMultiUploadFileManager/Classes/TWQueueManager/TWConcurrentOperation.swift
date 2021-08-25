//
//  ConcurrentOperation.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2019 Fabrizio Brancati
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import Queuer
/// It allows asynchronous tasks, has a pause and resume states,
/// can be easily added to a queue and can be created with a block.
class TWConcurrentOperation: ConcurrentOperation {
    /// Set if the `Operation` is executing.
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    /// Set if the `Operation` is executing.
    override open var isExecuting: Bool {
        return _executing
    }
    
    /// Set if the `Operation` is finished.
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    /// Set if the `Operation` is finished.
    override open var isFinished: Bool {
        return _finished
    }
    
    /// Current retry attempt.
    private(set) var currentAttemptCount = 1
    
    /// Specify if the `Operation` should retry another time.
    private var shouldRetry = true
    
    /// Start the `Operation`.
    override open func start() {
        _executing = true
        execute()
    }
    
    /// Retry function.
    /// It only works if `manualRetry` property has been set to `true`.
    open override func retry() {
        if shouldRetry, let executionBlock = executionBlock {
            executionBlock(self)
        }
    }
    
    /// Execute the `Operation`.
    /// If `executionBlock` is set, it will be executed and also `finish()` will be called.
    open override func execute() {
        if let executionBlock = executionBlock {
            executionBlock(self)
        }
    }
        
    /// Notify the completion of asynchronous task and hence the completion of the `Operation`.
    /// Must be called when the `Operation` is finished.
    ///
    /// - Parameter success: Set it to `false` if the `Operation` has failed, otherwise `true`.
    ///                      Default is `true`.
    open override func finish(success: Bool = true) {
        if success || currentAttemptCount >= maximumRetries {
            _executing = false
            _finished = true
            shouldRetry = false
        } else {
            currentAttemptCount += 1
            shouldRetry = true
            if !manualRetry {
                retry()
            }
        }
    }
}

