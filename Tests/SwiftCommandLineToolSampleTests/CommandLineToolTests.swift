import Testing
import Foundation
@testable import SwiftCommandLineToolSample

/// ビルドされた実行可能ファイルのパスを取得するヘルパー関数
func getProductsDirectory() -> URL {
    #if os(macOS)
    // まず、通常のXCTestのバンドルパスを試みる
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }

    // 上記で見つからない場合、実行しているディレクトリを基準に探す
    // これはSwift Testingフレームワークで実行した場合に有効
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    // .build/debug を探す
    let debugPath = currentDirectoryURL.appendingPathComponent(".build").appendingPathComponent("debug")
    if FileManager.default.fileExists(atPath: debugPath.path) {
        return debugPath
    }

    print("警告: 通常のビルドディレクトリが見つからないため、現在のディレクトリを使用します。")
    return currentDirectoryURL
    #else
    // Linux など他のプラットフォームでは適切なパス解決が必要
    return Bundle.main.bundleURL
    #endif
}

/// コマンドラインツールを実行し、結果を取得するヘルパー関数
func runExecutable(arguments: [String]) throws -> (output: String, error: String, status: Int32) {
    let executableName = "smp"
    let productsDirectory = getProductsDirectory()
    let executableURL = productsDirectory.appendingPathComponent(executableName)

    // 実行可能ファイルが存在するか確認
    guard FileManager.default.fileExists(atPath: executableURL.path) else {
        print("警告: 実行可能ファイルが見つかりません: \(executableURL.path)")
        print("実行ディレクトリ: \(FileManager.default.currentDirectoryPath)")
        print("製品ディレクトリ: \(productsDirectory.path)")

        // 実際のビルド結果を確認
        let fm = FileManager.default
        if fm.fileExists(atPath: productsDirectory.path) {
            print("製品ディレクトリの内容:")
            do {
                let contents = try fm.contentsOfDirectory(atPath: productsDirectory.path)
                for item in contents {
                    print("- \(item)")
                }
            } catch {
                print("ディレクトリ内容の取得に失敗: \(error)")
            }
        }

        // コマンドラインテストをスキップする代わりにエラーをスロー
        struct ExecutableNotFoundError: Error, CustomStringConvertible {
            let message: String
            var description: String { return message }
        }
        throw ExecutableNotFoundError(message: "実行可能ファイルが見つからないため、コマンドラインツールのテストをスキップします")
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

/// コマンドラインツールの実行テスト
///
/// このテストスイートでは、ビルドされた実行可能ファイル（バイナリ）を直接実行し、
/// そのコマンドライン引数の処理や出力が期待通りであることを確認する
@Suite struct CommandLineToolTests {

    @Test("CLI: サブコマンドなしで実行すると、ヘルプが表示されること")
    func testNoSubcommandShowsHelp() throws {
        do {
            let result = try runExecutable(arguments: [])

            // ヘルプの一部が含まれていることを確認
            #expect(result.output.contains("USAGE:") || result.error.contains("USAGE:"))
            #expect(result.output.contains("smp") || result.error.contains("smp"))
        } catch {
            throw error
        }
    }

    @Test("CLI: simpleコマンドが正常に実行されること")
    func testSimpleCommand() throws {
        do {
            let result = try runExecutable(arguments: ["simple"])

            #expect(result.output.contains("Hello, world"))
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: argsコマンドが基本的な引数を正しく処理すること")
    func testArgsCommandBasic() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing"])

            #expect(result.output == "testing")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: argsコマンドがcountオプションを正しく処理すること")
    func testArgsCommandWithCount() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing", "--count", "3"])

            #expect(result.output == "testing testing testing")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: argsコマンドがuppercase フラグを正しく処理すること")
    func testArgsCommandWithUppercase() throws {
        do {
            let result = try runExecutable(arguments: ["args", "testing", "--uppercase"])

            #expect(result.output == "TESTING")
            #expect(result.status == 0)
        } catch {
            throw error
        }
    }

    @Test("CLI: argsコマンドが複数のオプションを正しく処理すること")
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
