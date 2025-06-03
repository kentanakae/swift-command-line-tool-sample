import ArgumentParser
import Foundation

/// # SwiftCommandLineToolSample
///
/// A high-functionality sample command-line tool for executing shell commands.
///
/// This tool is designed as a reference implementation for command-line application development in Swift,
/// demonstrating how to implement a sophisticated CLI interface using ArgumentParser.
/// It covers a wide range of use cases, from basic shell command execution to complex data processing and parallel processing using Swift Concurrency.
///
/// ## Main Features
///
/// - Basic shell command execution
/// - Sequential execution of multiple commands
/// - Complex command execution using pipelines
/// - Processing and transformation of command output
/// - Rich patterns for receiving command-line arguments
/// - Asynchronous and parallel processing using Swift Concurrency
/// - File operations and transformation processing
///
/// > Tip: Each subcommand can be used independently or combined to build complex processing flows.
/// > Use the `--help` flag to display detailed usage for each command.
///
/// ## Usage Examples
///
/// ```swift
/// // Basic command execution
/// $ smp simple
///
/// // Data processing and parallel execution
/// $ smp dataprocess parallel -t 10 -d 0.5
/// ```
@main
struct SwiftCommandLineToolSample: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "smp",
        abstract: "Sample command-line tool written in Swift.",
        subcommands: [SimpleCommand.self, ComplexCommand.self, PipeCommand.self, OutputCommand.self, ArgsCommand.self, DataProcessCommand.self]
    )

    /// Handler when executed without subcommands.
    /// Displays the help message.
    func run() throws {
        // When executed without subcommands, display help and exit
        // No need to print, ArgumentParser will display help
        throw CleanExit.helpRequest()
    }

    /// Subcommand for executing a simple command.
    /// Example of basic shell command execution.
    struct SimpleCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "simple",
            abstract: "Example of executing a simple command"
        )

        func run() throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "echo \"Hello, world\""]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// Subcommand for executing multiple commands in sequence.
    /// Example of executing multiple shell commands in order using semicolons.
    struct ComplexCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "complex",
            abstract: "Example of executing multiple commands in sequence"
        )

        func run() throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            // Concatenate multiple commands with semicolons
            process.arguments = ["-c", "date '+%Y-%m-%d %H:%M:%S'; echo 'Current directory:'; pwd; echo 'Current user:'; whoami"]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// Subcommand for executing complex commands using pipes.
    /// Example of complex command execution using Unix pipeline processing.
    struct PipeCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "pipe",
            abstract: "Example of complex command using pipes"
        )

        func run() throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            // Complex command using pipes, grep, and sort
            process.arguments = ["-c", "ls -la | grep '^d' | sort -r | head -3"]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// Subcommand for obtaining and processing command output.
    /// Example of obtaining command output using a pipe and processing it in Swift.
    struct OutputCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "output",
            abstract: "Example of obtaining command output"
        )

        func run() throws {
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "echo 'This text will be processed in Swift' | wc -w"]
            process.standardOutput = pipe

            try process.run()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("Command output: \(output.trimmingCharacters(in: .whitespacesAndNewlines)) words")
                print("You can process and transform output in Swift")
            }

            process.waitUntilExit()
        }
    }

    /// Subcommand for processing command-line arguments.
    /// Example usage of various types of arguments (positional, options, flags).
    struct ArgsCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "args",
            abstract: "Example of a command that receives arguments"
        )

        /// Positional argument for the string to process.
        /// This parameter is required and must be specified when running the command.
        @Argument(help: "String to process")
        var text: String

        /// Option argument to specify the number of repetitions.
        /// Can be specified with either `-c` or `--count`. Default is 1.
        @Option(name: .shortAndLong, help: "Number of repetitions")
        var count: Int = 1

        /// Flag to indicate whether to convert text to uppercase.
        /// Enabled with `-u` or `--uppercase`.
        @Flag(name: .shortAndLong, help: "Convert to uppercase")
        var uppercase: Bool = false

        func run() throws {
            let executor = CommandExecutor()
            let result = try executor.executeTextProcessing(text, count: count, uppercase: uppercase)

            // 実行結果が成功（終了コード0）でなければエラーを投げる
            if result.exitCode != 0 {
                print(result.error)
                throw ExitCode(result.exitCode)
            }

            // 標準出力があれば表示
            if !result.output.isEmpty {
                print(result.output)
            }
        }
    }

    /// Subcommand for data processing.
    /// Example of advanced data operations and parallel processing using Swift Concurrency.
    struct DataProcessCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "dataprocess",
            abstract: "Example of data processing using Swift Concurrency",
            subcommands: [
                APIFetchCommand.self,
                JSONProcessingCommand.self,
                ParallelProcessingCommand.self,
                FileTransformCommand.self
            ]
        )

        /// Display help when executed without subcommands.
        func run() throws {
            throw CleanExit.helpRequest()
        }

        /// Subcommand for API calls.
        /// Example of asynchronous API calls and data retrieval using Swift Concurrency.
        struct APIFetchCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "fetch",
                abstract: "Example of asynchronous API data retrieval"
            )

            /// Option argument for the API URL to fetch.
            /// Fetches data from the URL specified with `-u` or `--url`.
            @Option(name: .shortAndLong, help: "API URL to fetch data from")
            var url: String = "https://jsonplaceholder.typicode.com/todos/1"

            /// Option argument to specify the output file for the data.
            /// Saves the result to the file specified with `-o` or `--output`.
            @Option(name: .shortAndLong, help: "Output data file")
            var outputFile: String?

            /// Verbose flag.
            /// Displays detailed logs with `-v` or `--verbose`.
            @Flag(name: .shortAndLong, help: "Show verbose output")
            var verbose: Bool = false

            func run() throws {
                // Run Swift Concurrency in a blocking manner
                let runLoop = RunLoop.current
                let semaphore = DispatchSemaphore(value: 0)

                Task { @MainActor in
                    await fetchAPIData()
                    semaphore.signal()
                }

                // Blocking wait (not recommended, but necessary within ParsableCommand constraints)
                while semaphore.wait(timeout: .now()) == .timedOut {
                    runLoop.run(until: Date(timeIntervalSinceNow: 0.1))
                }
            }

            /// Asynchronously fetch and process API data.
            @MainActor
            func fetchAPIData() async {
                if verbose {
                    print("Starting data fetch from URL: \(url)")
                }

                guard let apiURL = URL(string: url) else {
                    print("Error: Invalid URL")
                    return
                }

                do {
                    if verbose {
                        print("Starting request...")
                    }

                    // Asynchronous network request using Swift Concurrency
                    let (data, response) = try await URLSession.shared.data(from: apiURL)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("Error: Could not get HTTP response")
                        return
                    }

                    if verbose {
                        print("Status code: \(httpResponse.statusCode)")
                    }

                    guard httpResponse.statusCode == 200 else {
                        print("Error: API request failed (status code: \(httpResponse.statusCode))")
                        return
                    }

                    // Convert response data to JSON format
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyJsonString = String(data: jsonData, encoding: .utf8) {

                        // Output the result
                        if let outputFile = outputFile {
                            let fileURL = URL(fileURLWithPath: outputFile)
                            try prettyJsonString.write(to: fileURL, atomically: true, encoding: .utf8)
                            print("Result saved to file '\(outputFile)'")
                        } else {
                            print("API response:")
                            print(prettyJsonString)
                        }
                    } else {
                        print("Error: Failed to process JSON data")
                    }
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }

        /// Subcommand for JSON data processing.
        /// Provides JSON data processing, transformation, and search functionality.
        struct JSONProcessingCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "json",
                abstract: "Example of JSON data processing"
            )

            /// Option argument for the input JSON file path.
            @Option(name: .shortAndLong, help: "Path to the JSON file to process")
            var inputFile: String?

            /// Option argument for the query key.
            /// Extracts the value for the key specified with `-k` or `--key` (e.g., user.name).
            @Option(name: .shortAndLong, help: "JSON key path to extract (e.g., user.name)")
            var keyPath: String?

            /// Option argument for filtering.
            /// Filters by the condition specified with `-f` or `--filter` (e.g., id=1).
            @Option(name: .shortAndLong, help: "Filter by specific condition (e.g., id=1)")
            var filter: String?

            func run() throws {
                // Obtain JSON data
                var jsonData: Data

                if let inputFile = inputFile {
                    let fileURL = URL(fileURLWithPath: inputFile)
                    jsonData = try Data(contentsOf: fileURL)
                } else {
                    // Use sample JSON
                    let sampleJson = """
                    [
                      {
                        "id": 1,
                        "name": "田中太郎",
                        "email": "taro@example.com",
                        "active": true
                      },
                      {
                        "id": 2,
                        "name": "鈴木花子",
                        "email": "hanako@example.com",
                        "active": false
                      },
                      {
                        "id": 3,
                        "name": "佐藤次郎",
                        "email": "jiro@example.com",
                        "active": true
                      }
                    ]
                    """
                    jsonData = sampleJson.data(using: .utf8)!
                }

                // Parse JSON data
                guard let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                    print("Error: Not a valid JSON array")
                    return
                }

                // Extract if key path is specified
                if let keyPath = keyPath {
                    let keys = keyPath.split(separator: ".")

                    print("Extraction result for key '\(keyPath)':")
                    for (index, item) in jsonArray.enumerated() {
                        var currentValue: Any? = item

                        // Traverse nested keys
                        for key in keys {
                            if let dict = currentValue as? [String: Any] {
                                currentValue = dict[String(key)]
                            } else {
                                currentValue = nil
                                break
                            }
                        }

                        if let value = currentValue {
                            print("Item[\(index)]: \(value)")
                        }
                    }
                }

                // Filter if filter is specified
                if let filter = filter, filter.contains("=") {
                    let components = filter.split(separator: "=")
                    if components.count == 2 {
                        let key = String(components[0])
                        let value = String(components[1])

                        print("Results for filter '\(key)=\(value)':")

                        // Filter items matching the condition
                        let filteredItems = jsonArray.filter { item in
                            if let itemValue = item[key] {
                                // Handle special types
                                switch itemValue {
                                case let boolValue as Bool:
                                    return (value.lowercased() == "true" && boolValue) ||
                                           (value.lowercased() == "false" && !boolValue)
                                case let intValue as Int:
                                    return String(intValue) == value
                                case let stringValue as String:
                                    return stringValue == value
                                default:
                                    let stringValue = String(describing: itemValue)
                                    return stringValue == value
                                }
                            }
                            return false
                        }

                        // Display filtered results
                        if filteredItems.isEmpty {
                            print("No items match the condition")
                        } else {
                            for (index, item) in filteredItems.enumerated() {
                                if let itemData = try? JSONSerialization.data(withJSONObject: item, options: .prettyPrinted),
                                   let prettyString = String(data: itemData, encoding: .utf8) {
                                    print("Result[\(index)]:")
                                    print(prettyString)
                                }
                            }
                        }
                    }
                }

                // If neither key path nor filter is specified, display all data
                if keyPath == nil && filter == nil {
                    if let prettyData = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print("JSON data:")
                        print(prettyString)
                    }
                }
            }
        }

        /// Subcommand for parallel processing.
        /// Example of parallel processing using Swift Concurrency.
        struct ParallelProcessingCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "parallel",
                abstract: "Example of parallel processing using Swift Concurrency"
            )

            /// Option argument for the number of tasks to process.
            @Option(name: .shortAndLong, help: "Number of tasks to process")
            var tasks: Int = 5

            /// Option argument for the processing time of each task (seconds).
            @Option(name: .shortAndLong, help: "Processing time for each task (seconds)")
            var duration: Double = 1.0

            /// Sequential execution flag.
            /// Executes sequentially instead of in parallel with `-s` or `--sequential`.
            @Flag(name: .shortAndLong, help: "Execute sequentially instead of in parallel")
            var sequential: Bool = false

            func run() throws {
                // Run Swift Concurrency in a blocking manner
                let runLoop = RunLoop.current
                let semaphore = DispatchSemaphore(value: 0)

                Task { @MainActor in
                    await executeParallelTasks()
                    semaphore.signal()
                }

                // Blocking wait (not recommended, but necessary within ParsableCommand constraints)
                while semaphore.wait(timeout: .now()) == .timedOut {
                    runLoop.run(until: Date(timeIntervalSinceNow: 0.1))
                }
            }

            /// Execute tasks asynchronously.
            @MainActor
            func executeParallelTasks() async {
                print("Starting task processing: executing \(tasks) tasks (\(duration) seconds each) \(sequential ? "sequentially" : "in parallel")")

                let startTime = Date()

                if sequential {
                    // Sequential execution
                    for i in 1...tasks {
                        print("Task \(i) started")
                        // Simulate task execution
                        try? await Task.sleep(for: .seconds(duration))
                        print("Task \(i) completed")
                    }
                } else {
                    // Parallel execution using Swift Concurrency
                    await withTaskGroup(of: String.self) { group in
                        for i in 1...tasks {
                            group.addTask {
                                print("Task \(i) started")
                                // Simulate task execution
                                try? await Task.sleep(for: .seconds(duration))
                                print("Task \(i) completed")
                                return "Result of task \(i)"
                            }
                        }

                        // Collect results from all tasks
                        for await _ in group {
                            // In actual processing, aggregate results here
                        }
                    }
                }

                let endTime = Date()
                let elapsedTime = endTime.timeIntervalSince(startTime)

                print("All tasks completed")
                print("Elapsed time: \(String(format: "%.2f", elapsedTime)) seconds")

                // Compare with theoretical elapsed time
                let theoreticalTime = sequential ? Double(tasks) * duration : duration
                print("Theoretical processing time: \(String(format: "%.2f", theoreticalTime)) seconds")
                print("Efficiency: \(String(format: "%.2f", theoreticalTime / elapsedTime * 100))%")
            }
        }

        /// Subcommand for file transformation processing.
        /// Example of asynchronously reading, transforming, and saving files.
        struct FileTransformCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "transform",
                abstract: "Example of file transformation processing"
            )

            /// Option argument for the input file.
            @Option(name: .shortAndLong, help: "Input file to process")
            var inputFile: String

            /// Option argument for the output file.
            @Option(name: .shortAndLong, help: "Output file to save the result")
            var outputFile: String?

            /// Option argument for the transformation type.
            @Option(name: .shortAndLong, help: "Transformation type to execute (uppercase, lowercase, count, reverse)")
            var transformType: String = "uppercase"

            /// Flag to create a backup.
            @Flag(name: .shortAndLong, help: "Create a backup of the original file")
            var backup: Bool = false

            func run() throws {
                // File transformation processing
                let inputURL = URL(fileURLWithPath: inputFile)

                // Check if input file exists
                guard FileManager.default.fileExists(atPath: inputFile) else {
                    print("Error: Input file '\(inputFile)' not found")
                    return
                }

                // Create backup
                if backup {
                    let backupURL = inputURL.deletingPathExtension().appendingPathExtension("backup" + inputURL.pathExtension)
                    try FileManager.default.copyItem(at: inputURL, to: backupURL)
                    print("Backup created: \(backupURL.path)")
                }

                // Read file contents
                do {
                    let inputData = try String(contentsOf: inputURL, encoding: .utf8)

                    // Transformation processing
                    let transformedData: String
                    switch transformType {
                    case "uppercase":
                        transformedData = inputData.uppercased()
                    case "lowercase":
                        transformedData = inputData.lowercased()
                    case "count":
                        let lines = inputData.components(separatedBy: .newlines)
                        let words = inputData.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                        let characters = inputData.filter { !$0.isWhitespace }
                        transformedData = """
                        Aggregation result:
                        Lines: \(lines.count)
                        Words: \(words.count)
                        Characters: \(characters.count)
                        """
                    case "reverse":
                        transformedData = String(inputData.reversed())
                    default:
                        print("Error: Unknown transformation type '\(transformType)'")
                        print("Available types: uppercase, lowercase, count, reverse")
                        return
                    }

                    // Output the result
                    let outputURL: URL
                    if let outputPath = outputFile {
                        outputURL = URL(fileURLWithPath: outputPath)
                    } else {
                        let filename = inputURL.deletingPathExtension().lastPathComponent
                        let ext = inputURL.pathExtension
                        outputURL = inputURL.deletingLastPathComponent().appendingPathComponent("\(filename)_transformed.\(ext)")
                    }

                    try transformedData.write(to: outputURL, atomically: true, encoding: .utf8)
                    print("Transformation result saved: \(outputURL.path)")

                    // Preview display
                    let previewLimit = 200
                    let preview = transformedData.prefix(previewLimit)
                    print("\nProcessing result preview (first \(previewLimit) characters):")
                    print("--------------------------")
                    print(preview)
                    if transformedData.count > previewLimit {
                        print("...")
                    }
                    print("--------------------------")

                } catch {
                    print("Error: Problem occurred during file processing - \(error.localizedDescription)")
                }
            }
        }
    }
}
