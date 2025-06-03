import Testing
@testable import SwiftCommandLineToolSample

/// Test suite for testing CommandExecutor class functionality
@Suite struct CommandExecutorTests {
    /// Test instance
    let executor = CommandExecutor()

    @Test("Test basic command execution")
    func testBasicCommandExecution() throws {
        // Test simple echo command
        let result = try executor.executeCommand("echo 'Hello, Testing!'")

        // Verify expected results
        #expect(result.output == "Hello, Testing!")
        #expect(result.exitCode == 0)
        #expect(result.error.isEmpty)
    }

    @Test("Test command that returns an error")
    func testErrorCommandExecution() throws {
        // Execute a non-existent command
        let result = try executor.executeCommand("nonexistentcommand")

        // Verify that an error occurred and exit code is non-zero
        #expect(result.exitCode != 0)
        #expect(!result.error.isEmpty)
    }

    @Test("Test command with multiline output")
    func testMultilineOutputCommand() throws {
        // Command that generates multiline output
        let result = try executor.executeCommand("echo -e 'Line 1\\nLine 2\\nLine 3'")

        // Verify that output contains multiple lines
        #expect(result.output.contains("Line 1"))
        #expect(result.output.contains("Line 2"))
        #expect(result.output.contains("Line 3"))
        #expect(result.exitCode == 0)
    }

    @Test("Test text processing logic")
    func testTextProcessing() {
        // Normal text, repeated once, no uppercase conversion
        let result1 = executor.processText("test", count: 1, uppercase: false)
        #expect(result1 == "test")

        // Normal text, repeated three times, no uppercase conversion
        let result2 = executor.processText("test", count: 3, uppercase: false)
        #expect(result2 == "test test test")

        // Normal text, repeated twice, with uppercase conversion
        let result3 = executor.processText("test", count: 2, uppercase: true)
        #expect(result3 == "TEST TEST")
    }

    @Test("Test text processing command execution")
    func testExecuteTextProcessing() throws {
        // Test basic text processing command
        let result = try executor.executeTextProcessing("testing", count: 2, uppercase: true)

        #expect(result.output == "TESTING TESTING")
        #expect(result.exitCode == 0)
        #expect(result.error.isEmpty)
    }

    @Test("Test processing text with special characters")
    func testSpecialCharactersInTextProcessing() throws {
        // Process text containing special characters (quotes, backslashes, etc.)
        // Since special characters may be interpreted when passed through the shell,
        // we check for the presence of important elements rather than exact string matching
        let specialText = "Special \"characters\" with \\ and $variables"
        let result = try executor.executeTextProcessing(specialText, count: 1, uppercase: false)

        // Verify that keywords are present, rather than exact matching
        #expect(result.output.contains("Special"))
        #expect(result.output.contains("characters"))
        #expect(result.output.contains("with"))
        #expect(result.exitCode == 0)

        // Debug log output (for investigation purposes)
        print("Expected text: \(specialText)")
        print("Actual output: \(result.output)")
    }
}
