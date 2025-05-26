import ArgumentParser
import Foundation

/// # SwiftCommandLineToolSample
///
/// シェルコマンドを実行するための高機能サンプルコマンドラインツール。
///
/// このツールはSwift言語でのコマンドラインアプリケーション開発の参照実装として設計されており、
/// ArgumentParserを活用した洗練されたCLIインターフェースを実装する方法を示す。
/// 基本的なシェルコマンド実行から、複雑なデータ処理、Swift Concurrencyを用いた並列処理まで
/// 幅広いユースケースをカバーする。
///
/// ## 主な機能
///
/// - 基本的なシェルコマンドの実行
/// - 複数のコマンドの連続実行
/// - パイプラインを使用した複雑なコマンドの実行
/// - コマンド出力の処理と加工
/// - 豊富なコマンドライン引数受け取りのパターン
/// - Swift Concurrencyを活用した非同期・並列処理
/// - ファイル操作と変換処理
///
/// > Tip: 各サブコマンドは単独で使用することも、組み合わせて複雑な処理を構築することも可能。
/// > `--help`フラグを使用すると、各コマンドの詳細な使用方法が表示される。
///
/// ## 使用例
///
/// ```swift
/// // 基本的なコマンド実行
/// $ smp simple
///
/// // データ処理と並列実行
/// $ smp dataprocess parallel -t 10 -d 0.5
/// ```
@main
struct SwiftCommandLineToolSample: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "smp",
        abstract: "Swiftで書かれたコマンドラインツールサンプル。",
        subcommands: [SimpleCommand.self, ComplexCommand.self, PipeCommand.self, OutputCommand.self, ArgsCommand.self, DataProcessCommand.self]
    )

    /// サブコマンドなしで実行された場合の処理。
    /// ヘルプメッセージを表示する。
    func run() throws {
        // サブコマンドなしで実行された場合は、ヘルプを表示して終了
        // printは不要、ArgumentParserの機能でヘルプを表示
        throw CleanExit.helpRequest()
    }

    /// 単純なコマンドを実行するサブコマンド。
    /// 基本的なシェルコマンド実行の例を示す。
    struct SimpleCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "simple",
            abstract: "単純なコマンドの実行例"
        )

        func run() throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "echo \"Hello, world\""]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// 複数のコマンドを連結して実行するサブコマンド。
    /// セミコロンを使用して複数のシェルコマンドを順番に実行する例を示す。
    struct ComplexCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "complex",
            abstract: "複数のコマンドを連結して実行する例"
        )

        func run() throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            // 複数コマンドをセミコロンで連結
            process.arguments = ["-c", "date '+%Y-%m-%d %H:%M:%S'; echo '現在のディレクトリ:'; pwd; echo '現在のユーザー:'; whoami"]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// パイプを使用した複雑なコマンドを実行するサブコマンド。
    /// Unixパイプライン処理を使用した複雑なコマンド実行の例を示す。
    struct PipeCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "pipe",
            abstract: "パイプを使った複雑なコマンドの例"
        )

        func run() throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            // パイプ、グレップ、ソートを使用した複雑なコマンド
            process.arguments = ["-c", "ls -la | grep '^d' | sort -r | head -3"]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// コマンド出力を取得して処理するサブコマンド。
    /// パイプを使ってコマンド出力を取得し、Swiftで加工する例を示す。
    struct OutputCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "output",
            abstract: "コマンド出力を取得する例"
        )

        func run() throws {
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "echo 'このテキストはSwiftで処理されます' | wc -w"]
            process.standardOutput = pipe

            try process.run()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("コマンド出力: \(output.trimmingCharacters(in: .whitespacesAndNewlines)) 単語")
                print("Swiftで出力を処理して加工できます")
            }

            process.waitUntilExit()
        }
    }

    /// コマンドライン引数を処理するサブコマンド。
    /// さまざまな種類の引数（位置引数、オプション、フラグ）の使用例を示す。
    struct ArgsCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "args",
            abstract: "引数を受け取るコマンドの例"
        )

        /// 処理する文字列の位置引数。
        /// このパラメータは必須で、コマンド実行時に必ず指定する必要がある。
        @Argument(help: "処理する文字列")
        var text: String

        /// 繰り返し回数を指定するオプション引数。
        /// `-c`または`--count`のいずれかで指定可能。デフォルト値は1。
        @Option(name: .shortAndLong, help: "繰り返し回数")
        var count: Int = 1

        /// テキストを大文字に変換するかどうかのフラグ。
        /// `-u`または`--uppercase`で有効化される。
        @Flag(name: .shortAndLong, help: "大文字に変換する")
        var uppercase: Bool = false

        func run() throws {
            let fixedText = uppercase ? text.uppercased() : text

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")

            var command = "echo"
            for _ in 0..<count {
                command += " \"\(fixedText)\""
            }

            process.arguments = ["-c", command]

            try process.run()
            process.waitUntilExit()
        }
    }

    /// データ処理を行うサブコマンド。
    /// Swift Concurrencyを活用した並行処理と高度なデータ操作の例を示す。
    struct DataProcessCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "dataprocess",
            abstract: "Swift Concurrency活用データ処理の例",
            subcommands: [
                APIFetchCommand.self,
                JSONProcessingCommand.self,
                ParallelProcessingCommand.self,
                FileTransformCommand.self
            ]
        )

        /// サブコマンドなしで実行された場合のヘルプを表示。
        func run() throws {
            throw CleanExit.helpRequest()
        }

        /// API呼び出しを行うサブコマンド。
        /// Swift Concurrencyを使用した非同期API呼び出しとデータ取得の例。
        struct APIFetchCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "fetch",
                abstract: "非同期APIデータ取得の例"
            )

            /// 取得するAPIのURLオプション引数。
            /// `-u`または`--url`で指定されたURLからデータを取得。
            @Option(name: .shortAndLong, help: "データを取得するAPIのURL")
            var url: String = "https://jsonplaceholder.typicode.com/todos/1"

            /// 出力データを保存するオプション引数。
            /// `-o`または`--output`で指定されたファイルに結果を保存。
            @Option(name: .shortAndLong, help: "出力データファイル")
            var outputFile: String?

            /// 詳細表示フラグ。
            /// `-v`または`--verbose`で詳細なログを表示。
            @Flag(name: .shortAndLong, help: "詳細出力を表示")
            var verbose: Bool = false

            func run() throws {
                // Swift Concurrencyをブロッキングで実行
                let runLoop = RunLoop.current
                let semaphore = DispatchSemaphore(value: 0)

                Task { @MainActor in
                    await fetchAPIData()
                    semaphore.signal()
                }

                // ブロッキング待機（非推奨だが、ParsableCommandの制約内で必要）
                while semaphore.wait(timeout: .now()) == .timedOut {
                    runLoop.run(until: Date(timeIntervalSinceNow: 0.1))
                }
            }

            /// 非同期でAPIデータを取得し処理する。
            @MainActor
            func fetchAPIData() async {
                if verbose {
                    print("URLからデータ取得を開始：\(url)")
                }

                guard let apiURL = URL(string: url) else {
                    print("エラー: 無効なURL")
                    return
                }

                do {
                    if verbose {
                        print("リクエスト開始...")
                    }

                    // Swift Concurrencyを使った非同期ネットワークリクエスト
                    let (data, response) = try await URLSession.shared.data(from: apiURL)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("エラー: HTTPレスポンスを取得できませんでした")
                        return
                    }

                    if verbose {
                        print("ステータスコード: \(httpResponse.statusCode)")
                    }

                    guard httpResponse.statusCode == 200 else {
                        print("エラー: APIリクエスト失敗 (ステータスコード: \(httpResponse.statusCode))")
                        return
                    }

                    // レスポンスデータをJSON形式に変換
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyJsonString = String(data: jsonData, encoding: .utf8) {

                        // 結果の出力
                        if let outputFile = outputFile {
                            let fileURL = URL(fileURLWithPath: outputFile)
                            try prettyJsonString.write(to: fileURL, atomically: true, encoding: .utf8)
                            print("結果をファイル '\(outputFile)' に保存しました")
                        } else {
                            print("APIレスポンス:")
                            print(prettyJsonString)
                        }
                    } else {
                        print("エラー: JSONデータの処理に失敗しました")
                    }
                } catch {
                    print("エラー: \(error.localizedDescription)")
                }
            }
        }

        /// JSONデータ処理を行うサブコマンド。
        /// JSONデータの処理、変換、検索機能を提供する。
        struct JSONProcessingCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "json",
                abstract: "JSONデータ処理の例"
            )

            /// 入力JSONファイルのパスオプション引数。
            @Option(name: .shortAndLong, help: "処理するJSONファイルパス")
            var inputFile: String?

            /// クエリキーオプション引数。
            /// `-k`または`--key`で指定されたキーの値を抽出。
            @Option(name: .shortAndLong, help: "抽出するJSONキーパス（例: user.name）")
            var keyPath: String?

            /// フィルターのオプション引数。
            /// `-f`または`--filter`で指定された条件でフィルタリング。
            @Option(name: .shortAndLong, help: "特定の条件でフィルタリング（例: id=1）")
            var filter: String?

            func run() throws {
                // JSONデータを取得
                var jsonData: Data

                if let inputFile = inputFile {
                    let fileURL = URL(fileURLWithPath: inputFile)
                    jsonData = try Data(contentsOf: fileURL)
                } else {
                    // サンプルJSONを使用
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

                // JSONデータをパース
                guard let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                    print("エラー: 有効なJSON配列ではありません")
                    return
                }

                // キーパスが指定されている場合は抽出
                if let keyPath = keyPath {
                    let keys = keyPath.split(separator: ".")

                    print("キー '\(keyPath)' での抽出結果:")
                    for (index, item) in jsonArray.enumerated() {
                        var currentValue: Any? = item

                        // ネストされたキーをたどる
                        for key in keys {
                            if let dict = currentValue as? [String: Any] {
                                currentValue = dict[String(key)]
                            } else {
                                currentValue = nil
                                break
                            }
                        }

                        if let value = currentValue {
                            print("項目[\(index)]: \(value)")
                        }
                    }
                }

                // フィルターが指定されている場合はフィルタリング
                if let filter = filter, filter.contains("=") {
                    let components = filter.split(separator: "=")
                    if components.count == 2 {
                        let key = String(components[0])
                        let value = String(components[1])

                        print("フィルター '\(key)=\(value)' での結果:")

                        // 条件に合致する項目をフィルタリング
                        let filteredItems = jsonArray.filter { item in
                            if let itemValue = item[key] {
                                // 特殊な型のケースを処理
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

                        // フィルタリングされた結果を表示
                        if filteredItems.isEmpty {
                            print("条件に一致する項目はありません")
                        } else {
                            for (index, item) in filteredItems.enumerated() {
                                if let itemData = try? JSONSerialization.data(withJSONObject: item, options: .prettyPrinted),
                                   let prettyString = String(data: itemData, encoding: .utf8) {
                                    print("結果[\(index)]:")
                                    print(prettyString)
                                }
                            }
                        }
                    }
                }

                // キーパスもフィルターも指定されていない場合は全データ表示
                if keyPath == nil && filter == nil {
                    if let prettyData = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print("JSONデータ:")
                        print(prettyString)
                    }
                }
            }
        }

        /// 並列処理を実行するサブコマンド。
        /// Swift Concurrencyを使用した並列処理の例を示す。
        struct ParallelProcessingCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "parallel",
                abstract: "Swift Concurrency並列処理の例"
            )

            /// 処理するタスク数オプション引数。
            @Option(name: .shortAndLong, help: "処理するタスク数")
            var tasks: Int = 5

            /// 各タスクの処理時間オプション引数（秒）。
            @Option(name: .shortAndLong, help: "各タスクの処理時間（秒）")
            var duration: Double = 1.0

            /// シーケンシャル実行フラグ。
            /// `-s`または`--sequential`で並列ではなく逐次実行する。
            @Flag(name: .shortAndLong, help: "並列ではなく逐次実行")
            var sequential: Bool = false

            func run() throws {
                // Swift Concurrencyをブロッキングで実行
                let runLoop = RunLoop.current
                let semaphore = DispatchSemaphore(value: 0)

                Task { @MainActor in
                    await executeParallelTasks()
                    semaphore.signal()
                }

                // ブロッキング待機（非推奨だが、ParsableCommandの制約内で必要）
                while semaphore.wait(timeout: .now()) == .timedOut {
                    runLoop.run(until: Date(timeIntervalSinceNow: 0.1))
                }
            }

            /// 非同期でタスクを実行する。
            @MainActor
            func executeParallelTasks() async {
                print("タスク処理を開始: \(tasks)個のタスク（各\(duration)秒）を\(sequential ? "逐次" : "並列")で実行")

                let startTime = Date()

                if sequential {
                    // 逐次実行の場合
                    for i in 1...tasks {
                        print("タスク \(i) 開始")
                        // タスク実行を疑似再現
                        try? await Task.sleep(for: .seconds(duration))
                        print("タスク \(i) 完了")
                    }
                } else {
                    // 並列実行の場合（Swift Concurrencyを活用）
                    await withTaskGroup(of: String.self) { group in
                        for i in 1...tasks {
                            group.addTask {
                                print("タスク \(i) 開始")
                                // タスク実行を疑似再現
                                try? await Task.sleep(for: .seconds(duration))
                                print("タスク \(i) 完了")
                                return "タスク \(i) の結果"
                            }
                        }

                        // 全タスクの結果を収集
                        for await _ in group {
                            // 実際の処理ではここで結果を集約する
                        }
                    }
                }

                let endTime = Date()
                let elapsedTime = endTime.timeIntervalSince(startTime)

                print("全タスク処理完了")
                print("経過時間: \(String(format: "%.2f", elapsedTime))秒")

                // 理論的な経過時間と比較
                let theoreticalTime = sequential ? Double(tasks) * duration : duration
                print("理論的な処理時間: \(String(format: "%.2f", theoreticalTime))秒")
                print("効率: \(String(format: "%.2f", theoreticalTime / elapsedTime * 100))%")
            }
        }

        /// ファイル変換処理を行うサブコマンド。
        /// ファイルの読み込み、変換、保存処理を非同期で実行する例を示す。
        struct FileTransformCommand: ParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "transform",
                abstract: "ファイル変換処理の例"
            )

            /// 入力ファイルオプション引数。
            @Option(name: .shortAndLong, help: "処理する入力ファイル")
            var inputFile: String

            /// 出力ファイルオプション引数。
            @Option(name: .shortAndLong, help: "結果を保存する出力ファイル")
            var outputFile: String?

            /// 変換タイプオプション引数。
            @Option(name: .shortAndLong, help: "実行する変換タイプ（uppercase, lowercase, count, reverse）")
            var transformType: String = "uppercase"

            /// バックアップ作成フラグ。
            @Flag(name: .shortAndLong, help: "元ファイルのバックアップを作成")
            var backup: Bool = false

            func run() throws {
                // ファイル変換処理
                let inputURL = URL(fileURLWithPath: inputFile)

                // 入力ファイルの存在確認
                guard FileManager.default.fileExists(atPath: inputFile) else {
                    print("エラー: 入力ファイル '\(inputFile)' が見つかりません")
                    return
                }

                // バックアップ作成
                if backup {
                    let backupURL = inputURL.deletingPathExtension().appendingPathExtension("backup" + inputURL.pathExtension)
                    try FileManager.default.copyItem(at: inputURL, to: backupURL)
                    print("バックアップ作成: \(backupURL.path)")
                }

                // ファイル内容を読み込む
                do {
                    let inputData = try String(contentsOf: inputURL, encoding: .utf8)

                    // 変換処理
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
                        集計結果:
                        行数: \(lines.count)
                        単語数: \(words.count)
                        文字数: \(characters.count)
                        """
                    case "reverse":
                        transformedData = String(inputData.reversed())
                    default:
                        print("エラー: 未知の変換タイプ '\(transformType)'")
                        print("使用可能なタイプ: uppercase, lowercase, count, reverse")
                        return
                    }

                    // 結果の出力
                    let outputURL: URL
                    if let outputPath = outputFile {
                        outputURL = URL(fileURLWithPath: outputPath)
                    } else {
                        let filename = inputURL.deletingPathExtension().lastPathComponent
                        let ext = inputURL.pathExtension
                        outputURL = inputURL.deletingLastPathComponent().appendingPathComponent("\(filename)_transformed.\(ext)")
                    }

                    try transformedData.write(to: outputURL, atomically: true, encoding: .utf8)
                    print("変換結果を保存: \(outputURL.path)")

                    // プレビュー表示
                    let previewLimit = 200
                    let preview = transformedData.prefix(previewLimit)
                    print("\n処理結果プレビュー（最初の\(previewLimit)文字）:")
                    print("--------------------------")
                    print(preview)
                    if transformedData.count > previewLimit {
                        print("...")
                    }
                    print("--------------------------")

                } catch {
                    print("エラー: ファイル処理中に問題が発生しました - \(error.localizedDescription)")
                }
            }
        }
    }
}
