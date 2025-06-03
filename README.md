# Swift Command Line Tool Sample

Swift で作成された高機能なコマンドラインツールのサンプルプロジェクト。引数パース、シェルコマンド実行、非同期処理など様々な機能を実装しています。

## サンプル実装

- 基本的なシェルコマンド実行
- 複数コマンドの連続実行
- パイプラインを使用した複雑なコマンド実行
- コマンド出力の処理・変換
- コマンドライン引数の多様なパターン受付
- Swift Concurrencyを使用した非同期・並列処理
- ファイル操作と変換処理

## ビルドと実行

```bash
# プロジェクトのビルド
swift build

# コマンドの実行
swift run smp [サブコマンド] [オプション]

# または直接実行ファイルを実行
.build/debug/smp [サブコマンド] [オプション]
```

## テスト

Swift Testing フレームワークを使用したテストを実装しています。テストの実行方法：

```bash
# すべてのテストを実行
swift test

# 特定のテストスイートを実行
swift test --filter SwiftCommandLineToolSampleTests/CommandExecutorTests

# テストに関する詳細はテストディレクトリのREADMEを参照
```

詳細は [テストガイド](Tests/SwiftCommandLineToolSampleTests/README.md) を参照してください。
