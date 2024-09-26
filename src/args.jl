using ArgParse

function create_settings()
    s = ArgParseSettings()::ArgParseSettings
    @add_arg_table! s begin
        "videos"
        action = :command
        help = "チャンネルのビデオを取得する"
        "playlists"
        action = :command
        help = "プレイリストを取得する"
        "filter"
        action = :command
        help = "ビデオリストをフィルターする"
        "add"
        action = :command
        help = "プレイリストに動画を追加する"
        "delete"
        action = :command
        help = "プレイリストから動画を削除する"
    end
    @add_arg_table! s["videos"] begin
        "--secret", "-s"
        default = "client_secret.json"
        help = "クライアントシークレットJSONパス"
        "--token"
        help = "トークンJSONパス"
        "--channels", "-c"
        help = "チャンネルIDを指定"
        "--playlists", "-p"
        help = "プレイリストIDを指定"
        "--write", "-w"
        default = "videos.csv"
        help = "ビデオ一覧CSVファイルパス"
        "--nresults", "-n"
        arg_type = Int
        help = "取得数"
    end
    @add_arg_table! s["playlists"] begin
        "--secret", "-s"
        default = "client_secret.json"
        help = "クライアントシークレットJSONパス"
        "--token"
        help = "トークンJSONパス"
        "--channels", "-c"
        help = "チャンネルIDを指定"
        "--write", "-w"
        default = "playlists.csv"
        help = "プレイリスト一覧CSVファイルパス"
        "--nresults", "-n"
        arg_type = Int
        help = "取得数"
    end
    @add_arg_table! s["filter"] begin
        "--read", "-r"
        default = "videos.csv"
        help = "フィルター前のビデオリスト"
        "--write", "-w"
        default = "fvideos.csv"
        help = "フィルターしたビデオリスト"
        "--include", "-i"
        help = "含めるタイトル"
        "--exclude", "-e"
        help = "除外するタイトル"
    end
    @add_arg_table! s["add"] begin
        "--secret", "-s"
        default = "client_secret.json"
        help = "クライアントシークレットJSONパス"
        "--token"
        help = "トークンJSONパス"
        "--read", "-r"
        default = "fvideos.csv"
        help = "追加するビデオリスト"
        "--title"
        required = true
        help = "プレイリストのタイトル"
    end
    @add_arg_table! s["delete"] begin
        "--secret", "-s"
        default = "client_secret.json"
        help = "クライアントシークレットJSONパス"
        "--token"
        help = "トークンJSONパス"
        "--read", "-r"
        default = "delete.csv"
        help = "削除するビデオリスト"
    end
    s
end