import Foundation

/// A class that manages command execution and its results
///
/// This class provides the core logic for various command execution processes and separates them in a testable format.
///
/// - Note: This class is primarily designed for testability.
public final class CommandExecutor: Sendable {
    /// Result of command execution
    public struct ExecutionResult: Sendable, Equatable {
        /// Standard output of the command
        public let output: String
        /// Standard error output of the command
        public let error: String
        /// Exit code of the command
        public let exitCode: Int32

        public init(output: String, error: String, exitCode: Int32) {
            self.output = output
            self.error = error
            self.exitCode = exitCode
        }
    }

    /// Execute a shell command and return its result
    /// - Parameters:
    ///   - command: Shell command to execute
    ///   - shell: Shell to use (default is `/bin/zsh`)
    /// - Returns: Result of command execution
    /// - Throws: Error if command execution fails
    public func executeCommand(_ command: String, shell: String = "/bin/zsh") throws -> ExecutionResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-c", command]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        // Using new API in Swift 6.1
        let outputData = try outputPipe.fileHandleForReading.readToEnd() ?? Data()
        let errorData = try errorPipe.fileHandleForReading.readToEnd() ?? Data()

        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let error = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return ExecutionResult(
            output: output,
            error: error,
            exitCode: process.terminationStatus
        )
    }

    /// Execute a shell command asynchronously and return its result
    /// - Parameters:
    ///   - command: Shell command to execute
    ///   - shell: Shell to use (default is `/bin/zsh`)
    /// - Returns: Result of command execution
    /// - Throws: Error if command execution fails
    public func executeCommandAsync(_ command: String, shell: String = "/bin/zsh") async throws -> ExecutionResult {
        // Execute as a background task
        return try await Task.detached {
            try self.executeCommand(command, shell: shell)
        }.value
    }

    /// Repeat a string a specified number of times and convert to uppercase if needed
    /// - Parameters:
    ///   - text: String to process
    ///   - count: Number of repetitions
    ///   - uppercase: Whether to convert to uppercase
    /// - Returns: Processed string
    public func processText(_ text: String, count: Int, uppercase: Bool) -> String {
        let fixedText = uppercase ? text.uppercased() : text
        return Array(repeating: fixedText, count: count).joined(separator: " ")
    }

    /// Build and execute a text processing command
    /// - Parameters:
    ///   - text: String to process
    ///   - count: Number of repetitions
    ///   - uppercase: Whether to convert to uppercase
    /// - Returns: Result of command execution
    /// - Throws: Error if command execution fails
    public func executeTextProcessing(_ text: String, count: Int, uppercase: Bool) throws -> ExecutionResult {
        let fixedText = uppercase ? text.uppercased() : text

        var command = "echo"
        for _ in 0..<count {
            command += " \"\(fixedText)\""
        }

        return try executeCommand(command)
    }
}
