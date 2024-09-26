# コマンドライン

```bash
julia --project=~/Youtube ~/Youtube/src/cmd.jl -h
```
でコマンド一覧を表示する。

```bash
julia --project=~/Youtube ~/Youtube/src/cmd.jl videos -h
```
でさらにvideosコマンドのオプション引数の説明を確認できる。

`--channels`等でファイルパスを指定する場合、各行にチャンネルIDを羅列したテキストファイルを指定する。