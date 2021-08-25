//
//  TWQueueManager.swift
//  house591
//
//  Created by zhengzeqin on 2021/7/9.
//

import UIKit
import Queuer
@objcMembers public class TWQueueManager: NSObject {
    // MARK: - Priavte Property
    fileprivate var queue: Queuer?
    public struct Marco {
        /// 默认无限大的次数
        public static let infinitemReTryNum: Int = 999999
        /// 默认并发数
        public static let maxConcurrentOperationCount: Int = 3
        /// 默认重试次数
        public static let maximumRetries: Int = 1
    }
    
    // MARK: - Public Method
    /// 初始化
    public init(
        name: String,
        maxConcurrentOperationCount: Int = Marco.maxConcurrentOperationCount,
        qualityOfService: QualityOfService = .default
    ) {
        // 创建队列
        queue = Queuer(name: name, maxConcurrentOperationCount: maxConcurrentOperationCount, qualityOfService: qualityOfService)
    }
    
    /// 添加任务
    public func addConcurrentOperation(
        name: String?,
        maximumRetries: Int = Marco.maximumRetries,
        executionBlock: ((_ operation: ConcurrentOperation) -> Void)?
    ) {
        let concurrentOperation = TWConcurrentOperation(executionBlock: executionBlock)
        concurrentOperation.maximumRetries = maximumRetries
        queue?.addOperation(concurrentOperation)
    }
    
    /// 取消队列
    public func cancleAll() {
        queue?.cancelAll()
    }
    
    /// 暂停队列
    public func pause() {
        queue?.pause()
    }
    
    /// 继续队列
    public func resume() {
        queue?.resume()
    }
    
    /// 操作, 任务执行完毕后必须调用一次，确保能队列移除已完毕操作
    /// - Parameters:
    ///   - operation: 队列操作
    ///   - success: 设置 yes 则是立即结束掉队列操作， no 会根据重试次数进行重试
    public func finish(
        operation: ConcurrentOperation,
        success: Bool = true
    ) {
        guard let operation = operation as? TWConcurrentOperation else { return }
        operation.finish(success: success)
    }
    
    ///  当前的尝试次数
    public func getCurrentAttempt(operation: ConcurrentOperation) -> Int {
        guard let operation = operation as? TWConcurrentOperation else { return Marco.infinitemReTryNum }
        return operation.currentAttemptCount;
    }
    
    ///  操作添加到队列中
    public func addToQueue(operation: ConcurrentOperation) {
        guard let queue = queue else { return }
        operation.addToQueue(queue)
    }
}
