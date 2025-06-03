import Testing
import Foundation
@testable import SwiftCommandLineToolSample

/// Helper function to get the path to the built executable
func getProductsDirectory() -> URL {
    #if os(macOS)
    // First, try the normal XCTest bundle path
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }

    // If not found above, search based on the current directory
    // This is effective when running with Swift Testing framework
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    // Look for .build/debug
    let debugPath = currentDirectoryURL.appendingPathComponent(".build").appendingPathComponent("debug")
    if FileManager.default.fileExists(atPath: debugPath.path) {
        return debugPath
    }

    print("Warning: Normal build directory not found, using current directory.")
    return currentDirectoryURL
    #else
    // Proper path resolution needed for other platforms like Linux
    return Bundle.main.bundleURL
    #endif
}

/// Helper function to run the command-line tool and get results
func runExecutable(arguments: [String]) throws -> (output: String, error: String, status: Int32) {
    let executableName = "smp"
    let productsDirectory = getProductsDirectory()
    let executableURL = productsDirectory.appendingPathComponent(executableName)

    // Check if the executable exists
    guard FileManager.default.fileExists(atPath: executableURL.path) else {
        print("Warning: Executable not found: \(executableURL.path)")
        print("Execution directory: \(FileManager.default.currentDirectoryPath)")
        print("Products directory: \(productsDirectory.path)")

        // Check actual build results
        let fm = FileManager.default
        if fm.fileExists(atPath: productsDirectory.path) {
            print("Contents of products directory:")
            do {
                let contents = try fm.contentsOfDirectory(atPath: productsDirectory.path)
                for item in contents {
                    print("- \(item)")
                }
            } catch {
                print("Failed to retrieve directory contents: \(error)")
            }
        }

        // Throw an error instead of skipping command-line tests
        struct ExecutableNotFoundError: Error, CustomStringConvertible {
            let message: String
            var description: String { return message }
        }
        throw ExecutableNotFoundError(message: "Command-line tool tests are skipped because the executable was not found")
    }

    let task = Process()
    task.executableURL = executableURL
    task.arguments = arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    try task.run()
    task.waitUntilExit()

    let outputData = try outputPipe.fileHandleForReading.readToEnd() ?? Data()
    let errorData = try errorPipe.fileHandleForReading.readToEnd() ?? Data()

    let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let errorString = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    return (outputString, errorString, task.terminationStatus)
}

/// Command-line tool execution tests
///
/// This test suite directly executes the built executable (binary) and
/// verifies that its command-line argument processing and output are as expected
@Suite struct CommandLineToolTests {

    @Test("CLI: Running without a subcommand should display help")
    func testNoSubcommandShowsHelp() throws {
        do {
            let result = try runExecutable(arguments: [])

            // Check that help content is included
            #expect(result.output.contains("USAGE:") || result.error.contains("USAGE:"))
            #expect(result.output.contains("smp") || result.error.contains("smp"))
        } catch {
            throw error
        }
    }

    @Test("CLI: simple command should execute successfully")
    func testSimpleCommand() throws {
        do {
            let result = try runExecutable(arguments: ["simple"])

            #expect(result.output.contains("Hello, world"))
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: args command should correctly process basic arguments")
    func testArgsCommandBasic() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing"])

            #expect(result.output == "testing")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: args command should correctly process the count option")
    func testArgsCommandWithCount() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing", "--count", "3"])

            #expect(result.output == "testing testing testing")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: args command should correctly process the uppercase flag")
    func testArgsCommandWithUppercase() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing", "--uppercase"])

            #expect(result.output == "TESTING")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: args command should correctly process multiple options")
    func testArgsCommandWithMultipleOptions() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing", "-c", "2", "-u"])

            #expect(result.output == "TESTING TESTING")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }
}
