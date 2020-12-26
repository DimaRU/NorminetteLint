/////
////  Norminette.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import ArgumentParser
import Yams

fileprivate let configFileName = ".norminettelint.yml"

@main
struct Norminette: ParsableCommand {
    enum Command {
        case version, rules, check
    }

    static var configuration = CommandConfiguration(commandName: "norminettelint",
                                                    abstract: "norminette linter for Xcode.",
                                                    version: "0.0.1")
    @Argument(help: "Path to directory or file.")
    var path: [String] = []
    
    @Flag(name: .shortAndLong, help: "Display version of the remote nominette server.")
    var version = false
    
    @Flag(name: .long, help: "Display rules list.")
    var rulesList = false
    
    @Flag(name: .shortAndLong, help: "Downgrades errors to warnings.")
    var warnings = false

    @Option(name: .shortAndLong, help: ArgumentHelp("The path to the configuration file.",
                                                    discussion: "By default, .norminettelint.yml searched on current directory and then on home directory.",
                                                    valueName: "path"))
    var config: String?
    
    mutating func run() throws {
        var norminetteConfig: NorminetteConfig
        let command: Command

        let fileManager = FileManager.default
        if path.isEmpty {
            path.append(fileManager.currentDirectoryPath)
        }
        if version {
            command = .version
        } else if rulesList {
            command = .rules
        } else {
            command = .check
        }
        if config == nil {
            config = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(configFileName).path
            if !fileManager.fileExists(atPath: config!) {
                config = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(configFileName).path
                if !fileManager.fileExists(atPath: config!) {
                    throw NorminetteError.badConfig(message: "Config file \(configFileName) not found in current or home directory.")
                }
            }
        } else {
            if !fileManager.fileExists(atPath: config!) {
                throw NorminetteError.badConfig(message: "Config file \(config!) not found.")
            }
        }
        
        let configURL = URL(fileURLWithPath: config!)
        do {
            let configText = try String(contentsOf: configURL)
            let decoder = YAMLDecoder()
            norminetteConfig = try decoder.decode(NorminetteConfig.self, from: configText, userInfo: [:])
        } catch {
            throw NorminetteError.badConfig(message: "Invalid config file \(config!): \(error.localizedDescription)")
        }
        
        if warnings {
            norminetteConfig.warnings = true
        }
        
        let lint = NorminetteLint(config: norminetteConfig)
        try lint.execute(command: command, paths: path)
    }
}


