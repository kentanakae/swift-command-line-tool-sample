# SwiftCommandLineToolSample テストガイド

このプロジェクトは Swift Testing フレームワークを使用してテストを実装しており、コマンドラインツールのさまざまな機能やシナリオをカバーしています。

## テスト階層

テストは以下の階層で構成されています：

1. **単体テスト**：個々のコンポーネントを独立してテスト
   - `CommandExecutorTests`: コマンド実行クラスの機能テスト
   - `CommandProcessorTests`: モックを使用した依存性注入テスト

2. **コマンドラインテスト**：実際のビルド済み実行ファイルを実行して動作を検証
   - `CommandLineToolTests`: コマンドラインツール全体の動作テスト

## テストの実行方法

### すべてのテストを実行

```bash
swift test
```

### 特定のテストスイートを実行

```bash
# 単体テストのみ実行
swift test --filter SwiftCommandLineToolSampleTests.CommandExecutorTests

# コマンドラインテストのみ実行
swift test --filter SwiftCommandLineToolSampleTests.CommandLineToolTests

# 特定のテストケースのみ実行
swift test --filter SwiftCommandLineToolSampleTests.CommandExecutorTests/testBasicCommandExecution
```

## テストの追加方法

新しいテストを追加する場合：

1. 適切なテストスイートファイルを選択または新規作成
2. `@Suite` で新しいテストスイートを定義、または既存のスイートに追加
3. `@Test("テスト説明")` でテストケースを定義
4. `#expect` マクロで期待値を検証

```swift
@Test("新機能のテスト")
func testNewFeature() {
    let result = someFunction()
    #expect(result == expectedValue)
}
```

## モックの使用

外部依存性（シェルコマンド、ファイルシステムなど）をテストする場合は、`CommandProcessorTests.swift` のパターンを参考にモックオブジェクトを使用してください。
