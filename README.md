# PriceCompare

商品の単価を即時計算・比較できる Android アプリです。複数商品の価格をまとめて入力し、セール値引きやポイント還元を考慮した実質単価を算出して最安値を強調表示します。購入履歴は SQLite に保存され、過去の価格推移をいつでも確認できます。

## 主な機能

- **価格比較** — 複数行で商品を並べて即時比較。実質価格・単価を自動計算し、最安値の行をハイライト表示
- **履歴保存** — 比較結果を商品ごとに保存。最安単価・最新記録日を一覧で確認
- **商品詳細** — 商品ごとの価格推移一覧と最安単価・最新単価の集計ヘッダー
- **履歴詳細** — 各記録の全フィールド（店舗名・メモ含む）を確認・削除
- **日英対応** — 日本語 / 英語を設定から切り替え可能
- **ダークモード対応** — システム設定・手動設定に対応

## 計算式

```
実質価格 = 販売価格 − セール値引き − ポイント
単価     = 実質価格 ÷ 数量
```

## 動作環境

- Android 6.0 (API 23) 以上
- Flutter 3.x

## セットアップ

```bash
flutter pub get
flutter run
```

## アーキテクチャ

Domain-Driven Design (DDD) + レイヤードアーキテクチャ

```
lib/
  app/             # DI・起動処理
  presentation/    # Pages・ViewModels
  application/     # UseCases・DTO
  domain/          # エンティティ・リポジトリインターフェース
  infrastructure/  # SQLite実装・マッパー
  shared/          # テーマ・l10n・ユーティリティ
```

依存の向き: `Presentation → Application → Domain ← Infrastructure`

## 技術スタック

| 用途 | パッケージ |
|------|-----------|
| 状態管理 | `ChangeNotifier` + `ListenableBuilder` |
| DI | `get_it` |
| DB | `sqflite` |
| 数値・日付フォーマット | `intl` |
| 値オブジェクト等値比較 | `equatable` |
