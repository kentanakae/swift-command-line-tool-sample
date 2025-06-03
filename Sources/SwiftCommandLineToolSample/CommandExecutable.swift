import Foundation

/// コマンド実行用のプロトコル
/// テスト時のモック化のために抽象化
public protocol CommandExecutable: Sendable {
    /// シェルコマンドを実行する
    /// - Parameters:
    ///   - command: 実行するコマンド
    ///   - shell: 使用するシェル
    /// - Returns: コマンド実行の結果
    /// - Throws: 実行エラー
    func executeCommand(_ command: String, shell: String) throws -> CommandExecutor.ExecutionResult

    /// シェルコマンドを非同期で実行する
    /// - Parameters:
    ///   - command: 実行するコマンド
    ///   - shell: 使用するシェル
    /// - Returns: コマンド実行の結果
    /// - Throws: 実行エラー
    func executeCommandAsync(_ command: String, shell: String) async throws -> CommandExecutor.ExecutionResult
}

/// デフォルト実装を提供（下位互換性のため）
public extension CommandExecutable {
    func executeCommandAsync(_ command: String, shell: String) async throws -> CommandExecutor.ExecutionResult {
        // 同期メソッドでのデフォルト実装
        try executeCommand(command, shell: shell)
    }
}

/// CommandExecutable プロトコルの標準実装
extension CommandExecutor: CommandExecutable {
    // プロトコル準拠はすでに実装済み
}
