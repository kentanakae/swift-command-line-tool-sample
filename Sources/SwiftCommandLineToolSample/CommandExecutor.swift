import Foundation

/// コマンドの実行とその結果を管理するクラス
///
/// このクラスは各種コマンド実行処理のコアロジックを提供し、テスト可能な形式に分離する。
///
/// - Note: このクラスは主にテスト容易性のために設計されている。
public final class CommandExecutor: Sendable {
    /// コマンド実行の結果
    public struct ExecutionResult: Sendable, Equatable {
        /// コマンドの標準出力
        public let output: String
        /// コマンドの標準エラー出力
        public let error: String
        /// コマンドの終了コード
        public let exitCode: Int32

        public init(output: String, error: String, exitCode: Int32) {
            self.output = output
            self.error = error
            self.exitCode = exitCode
        }
    }

    /// シェルコマンドを実行し、その結果を返す
    /// - Parameters:
    ///   - command: 実行するシェルコマンド
    ///   - shell: 使用するシェル（デフォルトは `/bin/zsh`）
    /// - Returns: コマンド実行の結果
    /// - Throws: コマンドの実行に失敗した場合にエラーをスロー
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

        // Swift 6.1 では新しいAPIを使用
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

    /// シェルコマンドを非同期で実行し、その結果を返す
    /// - Parameters:
    ///   - command: 実行するシェルコマンド
    ///   - shell: 使用するシェル（デフォルトは `/bin/zsh`）
    /// - Returns: コマンド実行の結果
    /// - Throws: コマンドの実行に失敗した場合にエラーをスロー
    public func executeCommandAsync(_ command: String, shell: String = "/bin/zsh") async throws -> ExecutionResult {
        // バックグラウンドタスクとして実行
        return try await Task.detached {
            try self.executeCommand(command, shell: shell)
        }.value
    }

    /// 文字列を指定された回数繰り返し、必要に応じて大文字に変換する
    /// - Parameters:
    ///   - text: 処理する文字列
    ///   - count: 繰り返し回数
    ///   - uppercase: 大文字変換の有無
    /// - Returns: 処理された文字列
    public func processText(_ text: String, count: Int, uppercase: Bool) -> String {
        let fixedText = uppercase ? text.uppercased() : text
        return Array(repeating: fixedText, count: count).joined(separator: " ")
    }

    /// テキスト処理コマンドを構築し実行する
    /// - Parameters:
    ///   - text: 処理する文字列
    ///   - count: 繰り返し回数
    ///   - uppercase: 大文字変換の有無
    /// - Returns: コマンド実行の結果
    /// - Throws: コマンドの実行に失敗した場合にエラーをスロー
    public func executeTextProcessing(_ text: String, count: Int, uppercase: Bool) throws -> ExecutionResult {
        let fixedText = uppercase ? text.uppercased() : text

        var command = "echo"
        for _ in 0..<count {
            command += " \"\(fixedText)\""
        }

        return try executeCommand(command)
    }
}
