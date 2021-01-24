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
        guard let target = pbxproj.nativeTargets.first else {
            throw NorminetteError.invalidXcodeProj
        }

        guard target.buildPhases.first(where: { ($0 as? PBXShellScriptBuildPhase)?.name == norminettePhaseName }) == nil else {
            throw NorminetteError.scriptAlreadyExist
        }

        let script = "# Norminette check script\n" + (Bundle.main.executablePath ?? "norminettelint") + "\n"
        let phase = PBXShellScriptBuildPhase(name: norminettePhaseName,
                                             shellPath: "/bin/sh",
                                             shellScript: script)
        target.buildPhases.append(phase)
        pbxproj.add(object: phase)

        try pbxproj.write(path: XcodeProj.pbxprojPath(projectPath), override: true)
    }
}
