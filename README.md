# Swift Command Line Tool Sample

A sample project of a feature-rich command-line tool created with Swift. It implements various features including argument parsing, shell command execution, asynchronous processing, and more.

## Sample Implementations

- Basic shell command execution
- Sequential execution of multiple commands
- Complex command execution using pipelines
- Processing and transformation of command output
- Various patterns for accepting command-line arguments
- Asynchronous and parallel processing using Swift Concurrency
- File operations and transformation processing

## Build and Run

```bash
# Build the project
swift build

# Run the command
swift run smp [subcommand] [options]

# Or run the executable directly
.build/debug/smp [subcommand] [options]
```

## Testing

Tests are implemented using the Swift Testing framework. How to run tests:

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter SwiftCommandLineToolSampleTests/CommandExecutorTests

# See the test directory README for more details
```

For more details, see the [Test Guide](Tests/SwiftCommandLineToolSampleTests/README.md).
