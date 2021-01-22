/////
////  SetupXcodeProj.swift
///   Copyright © 2021 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import XcodeProj
import PathKit

struct SetupXcodeProj {
    let norminettePhaseName = "Norminettelint run script"

    func addRunScript(path: String, runPath: String) throws {
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

        guard let target = pbxproj.nativeTargets.first else {
            throw NorminetteError.invalidXcodeProj
        }

        guard target.buildPhases.first(where: { ($0 as? PBXShellScriptBuildPhase)?.name == norminettePhaseName }) == nil else {
            throw NorminetteError.scriptAlreadyExist
        }

        let script = "# Norminette check script\n" + runPath + "\n"
        let phase = PBXShellScriptBuildPhase(name: norminettePhaseName,
                                             shellPath: "/bin/sh",
                                             shellScript: script)
        target.buildPhases.append(phase)
        pbxproj.add(object: phase)

        try pbxproj.write(path: XcodeProj.pbxprojPath(projectPath), override: true)
    }
}
