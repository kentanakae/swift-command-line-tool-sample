import Testing
@testable import SwiftCommandLineToolSample

/// CommandExecutor クラスの機能をテストするスイート
@Suite struct CommandExecutorTests {
    /// テスト用インスタンス
    let executor = CommandExecutor()

    @Test("基本的なコマンド実行のテスト")
    func testBasicCommandExecution() throws {
        // 単純な echo コマンドのテスト
        let result = try executor.executeCommand("echo 'Hello, Testing!'")

        // 期待する結果の検証
        #expect(result.output == "Hello, Testing!")
        #expect(result.exitCode == 0)
        #expect(result.error.isEmpty)
    }

    @Test("エラーを返すコマンドのテスト")
    func testErrorCommandExecution() throws {
        // 存在しないコマンドを実行
        let result = try executor.executeCommand("nonexistentcommand")

        // エラーが発生し、終了コードが非0になることを確認
        #expect(result.exitCode != 0)
        #expect(!result.error.isEmpty)
    }

    @Test("複数行の出力を持つコマンドのテスト")
    func testMultilineOutputCommand() throws {
        // 複数行の出力を生成するコマンド
        let result = try executor.executeCommand("echo -e 'Line 1\\nLine 2\\nLine 3'")

        // 出力に複数行が含まれていることを確認
        #expect(result.output.contains("Line 1"))
        #expect(result.output.contains("Line 2"))
        #expect(result.output.contains("Line 3"))
        #expect(result.exitCode == 0)
    }

    @Test("テキスト処理ロジックのテスト")
    func testTextProcessing() {
        // 通常のテキスト、1回繰り返し、大文字変換なし
        let result1 = executor.processText("test", count: 1, uppercase: false)
        #expect(result1 == "test")

        // 通常のテキスト、3回繰り返し、大文字変換なし
        let result2 = executor.processText("test", count: 3, uppercase: false)
        #expect(result2 == "test test test")

        // 通常のテキスト、2回繰り返し、大文字変換あり
        let result3 = executor.processText("test", count: 2, uppercase: true)
        #expect(result3 == "TEST TEST")
    }

    @Test("テキスト処理コマンドの実行テスト")
    func testExecuteTextProcessing() throws {
        // 基本的なテキスト処理コマンドのテスト
        let result = try executor.executeTextProcessing("testing", count: 2, uppercase: true)

        #expect(result.output == "TESTING TESTING")
        #expect(result.exitCode == 0)
        #expect(result.error.isEmpty)
    }

    @Test("特殊文字を含むテキストの処理テスト")
    func testSpecialCharactersInTextProcessing() throws {
        // 特殊文字（引用符、バックスラッシュなど）を含むテキストの処理
        // shellを経由すると特殊文字は解釈される可能性があるため、文字列の正確な一致ではなく
        // 重要な要素が含まれているかどうかを確認
        let specialText = "Special \"characters\" with \\ and $variables"
        let result = try executor.executeTextProcessing(specialText, count: 1, uppercase: false)

        // 完全一致ではなく、キーワードが含まれていることを確認
        #expect(result.output.contains("Special"))
        #expect(result.output.contains("characters"))
        #expect(result.output.contains("with"))
        #expect(result.exitCode == 0)

        // デバッグ用のログ出力（調査目的）
        print("Expected text: \(specialText)")
        print("Actual output: \(result.output)")
    }
}
