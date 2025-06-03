import Testing
import Foundation
@testable import SwiftCommandLineToolSample

/// Mock implementation of CommandExecutable
///
/// Mock classes for testing manually conform to Sendable
final class MockCommandExecutor: @unchecked Sendable, CommandExecutable {
    // Using mutable properties for testing
    var executedCommands: [String] = []
    var returnResults: [CommandExecutor.ExecutionResult] = []

    func executeCommand(_ command: String, shell: String = "/bin/zsh") throws -> CommandExecutor.ExecutionResult {
        // Assume single-threaded execution in test environment
        executedCommands.append(command)

        // Return preset mock values if available, otherwise return default values
        if !returnResults.isEmpty {
            return returnResults.removeFirst()
        }

        // Default value
        return CommandExecutor.ExecutionResult(output: "Mock output for: \(command)", error: "", exitCode: 0)
    }

    func executeCommandAsync(_ command: String, shell: String = "/bin/zsh") async throws -> CommandExecutor.ExecutionResult {
        try executeCommand(command, shell: shell)
    }

    // Helper method to set specified results in the mock
    func setNextResult(output: String, error: String = "", exitCode: Int32 = 0) {
        returnResults.append(CommandExecutor.ExecutionResult(output: output, error: error, exitCode: exitCode))
    }
}

/// Tests for command processing functionality (using mocks)
@Suite struct CommandProcessorTests {

    @Test("Test command execution with mock")
    func testCommandExecutionWithMock() throws {
        let mockExecutor = MockCommandExecutor()

        // Test case 1: Successful case
        mockExecutor.setNextResult(output: "Success!")

        let result1 = try mockExecutor.executeCommand("echo test")

        #expect(result1.output == "Success!")
        #expect(result1.exitCode == 0)
        #expect(mockExecutor.executedCommands.last == "echo test")

        // Test case 2: Failure case
        mockExecutor.setNextResult(output: "", error: "Command failed", exitCode: 1)

        let result2 = try mockExecutor.executeCommand("invalid command")

        #expect(result2.error == "Command failed")
        #expect(result2.exitCode == 1)
        #expect(mockExecutor.executedCommands.last == "invalid command")
    }

    /// Class to test specific business logic
    /// - Note: This class is used only in the test environment and is not expected to be shared between threads
    final class CommandProcessor {
        let executor: CommandExecutable

        init(executor: CommandExecutable) {
            self.executor = executor
        }

        func processWithRetry(command: String, maxRetries: Int = 3) throws -> String {
            var lastError: Error? = nil
            var attempts = 0

            while attempts < maxRetries {
                do {
                    let result = try executor.executeCommand(command, shell: "/bin/zsh")
                    if result.exitCode == 0 {
                        return result.output
                    }
                    // Retry on non-zero exit code
                    lastError = NSError(domain: "CommandError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.error])
                } catch {
                    lastError = error
                }

                attempts += 1
                // In a real application, appropriate wait logic would be inserted here
            }

            throw lastError ?? NSError(domain: "CommandError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Maximum retry count reached"])
        }
    }

    @Test("Test retry functionality")
    func testRetryFunctionality() throws {
        let mockExecutor = MockCommandExecutor()
        let processor = CommandProcessor(executor: mockExecutor)

        // Scenario: fail first 2 times, succeed on 3rd attempt
        mockExecutor.setNextResult(output: "", error: "Temporary failure", exitCode: 1)
        mockExecutor.setNextResult(output: "", error: "Temporary failure", exitCode: 1)
        mockExecutor.setNextResult(output: "Finally succeeded", error: "", exitCode: 0)

        let result = try processor.processWithRetry(command: "some-flaky-command", maxRetries: 3)

        #expect(result == "Finally succeeded")
        #expect(mockExecutor.executedCommands.count == 3)
    }

    @Test("Test behavior when maximum retries are exceeded")
    func testMaximumRetryExceeded() {
        let mockExecutor = MockCommandExecutor()
        let processor = CommandProcessor(executor: mockExecutor)

        // Scenario where all attempts fail
        mockExecutor.setNextResult(output: "", error: "Failure 1", exitCode: 1)
        mockExecutor.setNextResult(output: "", error: "Failure 2", exitCode: 1)
        mockExecutor.setNextResult(output: "", error: "Failure 3", exitCode: 1)

        // Expect an error to be thrown
        #expect(throws: Error.self) {
            _ = try processor.processWithRetry(command: "always-failing-command", maxRetries: 3)
        }

        #expect(mockExecutor.executedCommands.count == 3)
    }
}
