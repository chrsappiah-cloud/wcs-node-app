#!/usr/bin/env swift

import Foundation

struct Config {
    let projectPath: String
    let sourcePath: String
    let targetRoot: String
    let folders: [String]
    let rootFiles: [String]
    let dryRun: Bool
}

enum ImportError: Error {
    case invalidProject(String)
    case invalidTargetRoot(String)
}

func parseArguments() -> Config {
    let args = CommandLine.arguments
    let env = ProcessInfo.processInfo.environment

    var projectPath = env["PROJECT_PATH"] ?? "/Applications/GeoWCS/GeoWCS.xcodeproj"
    var sourcePath = env["SRC_PATH"] ?? FileManager.default.currentDirectoryPath
    var targetRoot = ""
    var dryRun = false

    var index = 1
    while index < args.count {
        let arg = args[index]
        switch arg {
        case "--project":
            if index + 1 < args.count {
                projectPath = args[index + 1]
                index += 1
            }
        case "--source":
            if index + 1 < args.count {
                sourcePath = args[index + 1]
                index += 1
            }
        case "--target-root":
            if index + 1 < args.count {
                targetRoot = args[index + 1]
                index += 1
            }
        case "--dry-run":
            dryRun = true
        default:
            break
        }
        index += 1
    }

    if targetRoot.isEmpty {
        let projectParent = URL(fileURLWithPath: projectPath).deletingLastPathComponent().path
        targetRoot = (projectParent as NSString).appendingPathComponent("GeoWCS")
    }

    return Config(
        projectPath: projectPath,
        sourcePath: sourcePath,
        targetRoot: targetRoot,
        folders: [
            "Audio",
            "Auth",
            "CloudKit",
            "CoreData",
            "CoreLocation",
            "MapKit",
            "Notifications",
            "Subscription",
            "RokMaxCreative"
        ],
        rootFiles: ["ContentView.swift", "GeoWCSApp.swift", "Item.swift"],
        dryRun: dryRun
    )
}

func collectSwiftFiles(sourcePath: String, folders: [String], rootFiles: [String]) -> [String] {
    let fm = FileManager.default
    var files: [String] = []

    for file in rootFiles {
        let rootFilePath = (sourcePath as NSString).appendingPathComponent(file)
        if fm.fileExists(atPath: rootFilePath) {
            files.append(rootFilePath)
        }
    }

    for folder in folders {
        let root = (sourcePath as NSString).appendingPathComponent(folder)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: root, isDirectory: &isDir), isDir.boolValue else {
            continue
        }

        guard let enumerator = fm.enumerator(atPath: root) else { continue }
        while let item = enumerator.nextObject() as? String {
            guard item.hasSuffix(".swift") else { continue }
            let fullPath = (root as NSString).appendingPathComponent(item)
            files.append(fullPath)
        }
    }

    return files.sorted()
}

func validatePaths(projectPath: String, targetRoot: String) throws {
    let fm = FileManager.default
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: projectPath, isDirectory: &isDir), isDir.boolValue else {
        throw ImportError.invalidProject("Xcode project not found: \(projectPath)")
    }
    guard fm.fileExists(atPath: targetRoot, isDirectory: &isDir), isDir.boolValue else {
        throw ImportError.invalidTargetRoot("Target root folder not found: \(targetRoot)")
    }
}

func relativePath(from root: String, to file: String) -> String {
    let rootURL = URL(fileURLWithPath: root)
    let fileURL = URL(fileURLWithPath: file)
    return fileURL.path.replacingOccurrences(of: rootURL.path + "/", with: "")
}

func main() {
    let config = parseArguments()
    print("Project: \(config.projectPath)")
    print("Source: \(config.sourcePath)")
    print("Target: \(config.targetRoot)")

    do {
        try validatePaths(projectPath: config.projectPath, targetRoot: config.targetRoot)
        let swiftFiles = collectSwiftFiles(
            sourcePath: config.sourcePath,
            folders: config.folders,
            rootFiles: config.rootFiles
        )

        if swiftFiles.isEmpty {
            print("No Swift files found in configured folders.")
            return
        }

        let fm = FileManager.default
        var toCopy: [(src: String, dst: String)] = []
        var unchanged = 0

        for file in swiftFiles {
            let rel = relativePath(from: config.sourcePath, to: file)
            let dst = (config.targetRoot as NSString).appendingPathComponent(rel)

            if fm.fileExists(atPath: dst) {
                let srcData = try Data(contentsOf: URL(fileURLWithPath: file))
                let dstData = try Data(contentsOf: URL(fileURLWithPath: dst))
                if srcData == dstData {
                    unchanged += 1
                    continue
                }
            }

            toCopy.append((src: file, dst: dst))
        }

        print("Discovered \(swiftFiles.count) Swift files.")
        print("Unchanged: \(unchanged)")
        print("To sync: \(toCopy.count)")

        if toCopy.isEmpty {
            print("Sync complete: project is already up to date.")
            return
        }

        if config.dryRun {
            print("Dry run mode. Files to sync:")
            for pair in toCopy {
                print("- \(pair.src) -> \(pair.dst)")
            }
            return
        }

        var synced = 0
        var failed: [(src: String, err: String)] = []

        for pair in toCopy {
            print("Syncing \(pair.src) -> \(pair.dst)")
            do {
                let parent = URL(fileURLWithPath: pair.dst).deletingLastPathComponent().path
                try fm.createDirectory(atPath: parent, withIntermediateDirectories: true)

                if fm.fileExists(atPath: pair.dst) {
                    try fm.removeItem(atPath: pair.dst)
                }
                try fm.copyItem(atPath: pair.src, toPath: pair.dst)
                synced += 1
            } catch {
                failed.append((src: pair.src, err: String(describing: error)))
                print("Sync failed for \(pair.src): \(error)")
            }
        }

        if failed.isEmpty {
            print("Sync complete: \(synced) file(s) copied/updated.")
            print("If Xcode is open, refresh project navigator if needed.")
        } else {
            print("Sync finished with \(failed.count) failure(s).")
            for failure in failed {
                print("- \(failure.src): \(failure.err)")
            }
            exit(2)
        }
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

main()
