/////
////  NorminetteLint.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import RMQClient

class NorminetteLint {
    var rmqConnection: RMQConnection
    var rmqChannel: RMQChannel
    var rmwQueue: RMQQueue
    var foundErrors = false
    var config: NorminetteConfig
    var semaphore = DispatchSemaphore(value: 0)
    
    var enumerator: FileManager.DirectoryEnumerator?
    let resourceKeys: Set<URLResourceKey> = [.nameKey, .pathKey, .isRegularFileKey]
    let enabledExtensions = Set<String>(["c", "h"])

    init(config: NorminetteConfig) {
        self.config = config
        let delegate = RMQConnectionDelegateLogger()
        rmqConnection = RMQConnection(uri: "amqp://\(config.user):\(config.password)@\(config.hostname)", delegate: delegate)
        rmqConnection.start()
        rmqChannel = rmqConnection.createChannel()
        rmwQueue = rmqChannel.queue("", options: [.exclusive])
    }
    
    deinit {
        rmqChannel.close()
        rmqConnection.close()
    }

    func execute(command: Norminette.Command, files: [String]) throws {
        switch command {
        case .version:
            let request = NorminetteActionRequest(action: "version")
            try showInfo(request)
        case .rules:
            let request = NorminetteActionRequest(action: "help")
            try showInfo(request)
        case .check:
            try check(args: files)
        }
        if foundErrors {
            throw NorminetteError.checkError
        }
    }
    
    private func showInfo(_ request: NorminetteActionRequest) throws {
        rmqChannel.basicConsume(rmwQueue.name, acknowledgementMode: .auto, handler: actionReplyHandler(_:))
        let encoder = JSONEncoder()
        let body = try! encoder.encode(request)
        publish(body)
        if semaphore.wait(timeout: .now() + 30) == .timedOut {
            throw NorminetteError.timeout
        }
    }
    
    private func check(args: [String]) throws {
        rmqChannel.basicConsume(rmwQueue.name, acknowledgementMode: .auto, handler: checkReplyHandler(_:))
        let manager = FileManager.default
        for arg in args {
            let url = URL(fileURLWithPath: arg)
            enumerator = manager.enumerator(at: url,
                                            includingPropertiesForKeys: Array(resourceKeys),
                                            options: [.skipsHiddenFiles, .skipsPackageDescendants]) { (url, error) -> Bool in
                print(url.path, error.localizedDescription)
                return true
            }
            processNextFile()
            semaphore.wait()
        }
    }
    
    private func processNextFile() {
        guard let enumerator = enumerator else { return }
        while let file = enumerator.nextObject() {
            if let url = file as? URL,
               let resourceValues = try? url.resourceValues(forKeys: resourceKeys),
               let isRegularFile = resourceValues.isRegularFile,
               isRegularFile,
               enabledExtensions.contains(url.pathExtension) {
                processFile(url: url)
                return
            }
        }
        // No more files, end of task
        semaphore.signal()
    }

    private func processFile(url: URL) {
        do {
            let content = try String(contentsOf: url)
            let path = url.path
            let request = NorminetteCheckRequest(filename: path, content: content, rules: config.disabledRules ?? [])
            let encoder = JSONEncoder()
            let body = try! encoder.encode(request)
            publish(body)
            print("Check file:", url.lastPathComponent)
        } catch {
            print(error)
        }
    }
    
    private func publish(_ body: Data) {
        var props: [RMQValue & RMQBasicValue] = []
        props.append(RMQBasicCorrelationId(UUID().uuidString))
        props.append(RMQBasicReplyTo(rmwQueue.name))
        rmqChannel.defaultExchange().publish(body,
                                             routingKey: "norminette",
                                             properties: props,
                                             options: RMQBasicPublishOptions())
    }

    private func actionReplyHandler(_ message: RMQMessage) {
        guard let body = message.body else {
            return
        }
        let decoder = JSONDecoder()
        do {
            let reply = try decoder.decode(NorminetteActionReply.self, from: body)
            print(reply.display)
        } catch {
            print(error)
        }
        semaphore.signal()
    }

    private func checkReplyHandler(_ message: RMQMessage) {
        guard let body = message.body else { return }
        let decoder = JSONDecoder()
        do {
            let reply = try decoder.decode(NorminetteReply.self, from: body)
            processReply(reply)
        } catch {
            print(error)
        }
        processNextFile()
    }
    
    private func processReply(_ reply: NorminetteReply) {
        let fileName = reply.filename
        if reply.errors.count != 0 {
            foundErrors = true
        }
        for error in reply.errors {
            let line = error.line ?? 1
            let col = error.col ?? 0
            print("\(fileName):\(line):\(col): error:", error.reason)
        }
    }
}
