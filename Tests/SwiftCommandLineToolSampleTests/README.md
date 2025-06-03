# SwiftCommandLineToolSample Test Guide

This project implements tests using the Swift Testing framework and covers various features and scenarios of the command-line tool.

## Test Hierarchy

Tests are structured in the following hierarchy:

1. **Unit Tests**: Testing individual components independently
   - `CommandExecutorTests`: Tests for command execution class functionality
   - `CommandProcessorTests`: Dependency injection tests using mocks

2. **Command-line Tests**: Verifying behavior by executing the actual built executable
   - `CommandLineToolTests`: Tests for overall command-line tool behavior

## How to Run Tests

### Run All Tests

```bash
swift test
```

### Run Specific Test Suites

```bash
# Run only unit tests
swift test --filter SwiftCommandLineToolSampleTests.CommandExecutorTests

# Run only command-line tests
swift test --filter SwiftCommandLineToolSampleTests.CommandLineToolTests

# Run only a specific test case
swift test --filter SwiftCommandLineToolSampleTests.CommandExecutorTests/testBasicCommandExecution
```

## How to Add Tests

When adding new tests:

1. Choose or create an appropriate test suite file
2. Define a new test suite with `@Suite` or add to an existing suite
3. Define test cases using `@Test("Test description")`
4. Validate expected values using the `#expect` macro

```swift
@Test("Test new feature")
func testNewFeature() {
    let result = someFunction()
    #expect(result == expectedValue)
}
```

## Using Mocks

When testing external dependencies (shell commands, file system, etc.), use mock objects following the pattern in `CommandProcessorTests.swift`.
