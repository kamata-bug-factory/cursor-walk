# CursorWalk 作業ガイド

## プロジェクト概要

- ポインタの移動距離、マウスのクリック回数、推定スクロール回転数を計測するmacOSメニューバーアプリ
- UI：SwiftUI、Swift Charts
- マウス追跡：AppKitのイベントモニターで移動、クリック、スクロールを取得
- 保存先：Application Support内の`daily-distances.json`、`daily-clicks.json`、`daily-scroll-inputs.json`

## 作業ルール

- 変更はユーザーの依頼範囲に限定し、無関係なリファクタリングや依存関係の更新を行わない。
- 既存の`ObservableObject`実装は、モダナイズが依頼内容に含まれない限り維持する。
- マウス追跡を変更する場合は、イベントモニターの登録と解除を維持し、ローカルイベントとグローバルイベントの二重計上を避ける。
- 永続化を変更する場合は、原子的な書き込みと既存の`daily-distances.json`、`daily-clicks.json`、`daily-scroll-inputs.json`との後方互換性を維持する。
- 明示的に依頼されない限り、コミット、プッシュ、ブランチ作成、デプロイを行わない。

## 検証

- コードまたはプロジェクト設定の変更後は、Xcodeで`cursor-walk`ターゲットをビルドし、結果を報告する。
