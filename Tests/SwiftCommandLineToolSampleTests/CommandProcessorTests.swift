import Testing
import Foundation
@testable import SwiftCommandLineToolSample

/// CommandExecutable のモック実装
///
/// テスト用のモッククラスはSendableに手動で準拠する
final class MockCommandExecutor: @unchecked Sendable, CommandExecutable {
    // テスト用に変更可能なプロパティを使用
    var executedCommands: [String] = []
    var returnResults: [CommandExecutor.ExecutionResult] = []

    func executeCommand(_ command: String, shell: String = "/bin/zsh") throws -> CommandExecutor.ExecutionResult {
        // テスト環境では単一スレッドで実行されると想定
        executedCommands.append(command)

        // モックの戻り値がセットされていればそれを返し、そうでなければデフォルト値を返す
        if !returnResults.isEmpty {
            return returnResults.removeFirst()
        }

        // デフォルト値
        return CommandExecutor.ExecutionResult(output: "Mock output for: \(command)", error: "", exitCode: 0)
    }

    func executeCommandAsync(_ command: String, shell: String = "/bin/zsh") async throws -> CommandExecutor.ExecutionResult {
        try executeCommand(command, shell: shell)
    }

    // 指定した結果をモックに設定するヘルパーメソッド
    func setNextResult(output: String, error: String = "", exitCode: Int32 = 0) {
        returnResults.append(CommandExecutor.ExecutionResult(output: output, error: error, exitCode: exitCode))
    }
}

/// コマンド処理機能のテスト（モック使用）
@Suite struct CommandProcessorTests {

    @Test("モックを使ったコマンド実行のテスト")
    func testCommandExecutionWithMock() throws {
        let mockExecutor = MockCommandExecutor()

        // テストケース1: 成功するケース
        mockExecutor.setNextResult(output: "Success!")

        let result1 = try mockExecutor.executeCommand("echo test")

        #expect(result1.output == "Success!")
        #expect(result1.exitCode == 0)
        #expect(mockExecutor.executedCommands.last == "echo test")

        // テストケース2: 失敗するケース
        mockExecutor.setNextResult(output: "", error: "Command failed", exitCode: 1)

        let result2 = try mockExecutor.executeCommand("invalid command")

        #expect(result2.error == "Command failed")
        #expect(result2.exitCode == 1)
        #expect(mockExecutor.executedCommands.last == "invalid command")
    }

    /// 特定のビジネスロジックをテストするクラス
    /// - Note: このクラスはテスト環境でのみ使用され、スレッド間での共有は想定されていない
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
                    // 非0の終了コードでリトライ
                    lastError = NSError(domain: "CommandError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.error])
                } catch {
                    lastError = error
                }

                attempts += 1
                // 実際のアプリケーションでは適切な待機処理を入れる
            }

            throw lastError ?? NSError(domain: "CommandError", code: -1, userInfo: [NSLocalizedDescriptionKey: "最大リトライ回数に到達"])
        }
    }

    @Test("リトライ機能のテスト")
    func testRetryFunctionality() throws {
        let mockExecutor = MockCommandExecutor()
        let processor = CommandProcessor(executor: mockExecutor)

        // 最初の2回は失敗、3回目に成功するシナリオ
        mockExecutor.setNextResult(output: "", error: "Temporary failure", exitCode: 1)
        mockExecutor.setNextResult(output: "", error: "Temporary failure", exitCode: 1)
        mockExecutor.setNextResult(output: "Finally succeeded", error: "", exitCode: 0)

        let result = try processor.processWithRetry(command: "some-flaky-command", maxRetries: 3)

        #expect(result == "Finally succeeded")
        #expect(mockExecutor.executedCommands.count == 3)
    }

    @Test("最大リトライ回数超過時の動作テスト")
    func testMaximumRetryExceeded() {
        let mockExecutor = MockCommandExecutor()
        let processor = CommandProcessor(executor: mockExecutor)

        // すべての試行が失敗するシナリオ
        mockExecutor.setNextResult(output: "", error: "Failure 1", exitCode: 1)
        mockExecutor.setNextResult(output: "", error: "Failure 2", exitCode: 1)
        mockExecutor.setNextResult(output: "", error: "Failure 3", exitCode: 1)

        // エラーがスローされることを期待
        #expect(throws: Error.self) {
            _ = try processor.processWithRetry(command: "always-failing-command", maxRetries: 3)
        }

        #expect(mockExecutor.executedCommands.count == 3)
    }
}
