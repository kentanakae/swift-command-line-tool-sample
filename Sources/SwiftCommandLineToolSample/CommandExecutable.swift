import Foundation

/// Protocol for command execution
/// Abstracted for mocking during tests
public protocol CommandExecutable: Sendable {
    /// Execute a shell command
    /// - Parameters:
    ///   - command: Command to execute
    ///   - shell: Shell to use
    /// - Returns: Result of command execution
    /// - Throws: Execution error
    func executeCommand(_ command: String, shell: String) throws -> CommandExecutor.ExecutionResult

    /// Execute a shell command asynchronously
    /// - Parameters:
    ///   - command: Command to execute
    ///   - shell: Shell to use
    /// - Returns: Result of command execution
    /// - Throws: Execution error
    func executeCommandAsync(_ command: String, shell: String) async throws -> CommandExecutor.ExecutionResult
}

/// Provides default implementation (for backward compatibility)
public extension CommandExecutable {
    func executeCommandAsync(_ command: String, shell: String) async throws -> CommandExecutor.ExecutionResult {
        // Default implementation using synchronous method
        try executeCommand(command, shell: shell)
    }
}

/// Standard implementation of CommandExecutable protocol
extension CommandExecutor: CommandExecutable {
    // Protocol conformance is already implemented
}
