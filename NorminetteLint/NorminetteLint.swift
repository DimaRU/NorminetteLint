/////
////  NorminetteLint.swift
///   Copyright © 2021 Dmitriy Borovikov. All rights reserved.
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

    func execute(command: Norminette.Command, paths: [String]) throws {
        switch command {
        case .version:
            let request = NorminetteActionRequest(action: "version")
            try showInfo(request)
        case .rules:
            let request = NorminetteActionRequest(action: "help")
            try showInfo(request)
        case .check:
            try check(paths)
        }
        if foundErrors, !(config.warnings ?? false) {
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
    
    private func check(_ paths: [String]) throws {
        rmqChannel.basicConsume(rmwQueue.name, acknowledgementMode: .auto, handler: checkReplyHandler(_:))
        let manager = FileManager.default
        for path in paths {
            var isDirectory: ObjCBool = false
            if !manager.fileExists(atPath: path, isDirectory: &isDirectory) {
                print("File not found \(path)")
                continue
            }
            let url = URL(fileURLWithPath: path)
            if isDirectory.boolValue {
                let enumerator = manager.enumerator(at: url,
                                                    includingPropertiesForKeys: Array(resourceKeys),
                                                    options: [.skipsHiddenFiles, .skipsPackageDescendants]) { (url, error) -> Bool in
                    print(url.path, error.localizedDescription)
                    return true
                }
                if let enumerator = enumerator {
                    processDirectory(enumerator)
                }
            } else {
                processFile(url: url)
            }
        }
    }
    
    private func processDirectory(_ enumerator: FileManager.DirectoryEnumerator?) {
        guard let enumerator = enumerator else { return }
        while let file = enumerator.nextObject() {
            if let url = file as? URL,
               let resourceValues = try? url.resourceValues(forKeys: resourceKeys),
               let isRegularFile = resourceValues.isRegularFile,
               isRegularFile,
               enabledExtensions.contains(url.pathExtension) {
                processFile(url: url)
            }
        }
    }

    private func processFile(url: URL) {
        do {
            let content = try String(contentsOf: url)
            let path = url.path
            let request = NorminetteCheckRequest(filename: path, content: content, rules: config.specialRules ?? [])
            let encoder = JSONEncoder()
            let body = try! encoder.encode(request)
            publish(body)
            print("Check file:", url.lastPathComponent)
            if semaphore.wait(timeout: .now() + 30) == .timedOut {
                print("Server reply timeout")
            }
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
            parseReply(reply)
        } catch {
            print(error)
        }
        semaphore.signal()
    }
    
    private func parseReply(_ reply: NorminetteReply) {
        let fileName = reply.filename
        if reply.errors.count != 0 {
            foundErrors = true
        }
        for error in reply.errors {
            let line = error.line ?? 1
            let col = error.col ?? 0
            if config.warnings ?? false {
                print("\(fileName):\(line):\(col): warning:", error.reason)
            } else {
                print("\(fileName):\(line):\(col): error:", error.reason)
            }
        }
    }
}
