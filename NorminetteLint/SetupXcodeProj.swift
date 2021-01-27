/////
////  SetupXcodeProj.swift
///   Copyright © 2021 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import XcodeProj
import PathKit

struct SetupXcodeProj {
    let norminettePhaseName = "Norminettelint run script"

    func addRunScript(path: String) throws {
        let xcodeprojPath: String
        if path.hasSuffix(".xcodeproj") {
            xcodeprojPath = path
        } else if let content = try FileManager.default.subpathsOfDirectory(atPath: path).first(where: {
                $0.hasSuffix(".xcodeproj")
        }) {
            xcodeprojPath = path + "/" + content
        } else {
            throw NorminetteError.projectNotFound
        }

        let projectPath = Path(xcodeprojPath)
        let xcodeproj = try XcodeProj(path: projectPath)
        let pbxproj = xcodeproj.pbxproj

        var fileElement = pbxproj.fileReferences.first as PBXFileElement?
        while fileElement?.parent != nil {
            fileElement = fileElement?.parent
        }
        if let fileElement = fileElement {
            fileElement.usesTabs = true
            fileElement.tabWidth = 4
            fileElement.indentWidth = 4
        }
        for configuration in pbxproj.buildConfigurations where configuration.buildSettings["PRODUCT_NAME"] == nil {
            configuration.buildSettings["WARNING_CFLAGS"] = ["-Wall", "-Wextra"]
        }
        guard !pbxproj.nativeTargets.isEmpty else {
            throw NorminetteError.invalidXcodeProj
        }
        var path = (Bundle.main.executablePath ?? "norminettelint")
        if path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path) {
            path = path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
        }
        let script = "# Norminette check script\n" + path + "\n"

        for target in pbxproj.nativeTargets {
            guard target.buildPhases.first(where: { ($0 as? PBXShellScriptBuildPhase)?.name == norminettePhaseName }) == nil else {
                print("Norminette script already set for target", target.name)
                continue
            }
            let phase = PBXShellScriptBuildPhase(name: norminettePhaseName,
                                                 shellPath: "/bin/sh",
                                                 shellScript: script)
            target.buildPhases.append(phase)
            pbxproj.add(object: phase)
            print("Norminette script set for target", target.name)
        }

        try pbxproj.write(path: XcodeProj.pbxprojPath(projectPath), override: true)
    }
}
