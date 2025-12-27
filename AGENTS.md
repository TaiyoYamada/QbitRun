//
//  AGENTS.md
//  QuantumGateGame
//
//  Created by 山田大陽 on 2025/12/27.
//

```markdown
# AGENTS.md — Quantum Gate Game (Swift Student Challenge)

> AI coding assistants向けのプロジェクトガイドラインです。
> 本プロジェクトは **UIKitベース**で **Swift 6** を積極採用し、**体験（UX）最優先**で開発します。
> 低レイヤーAPI（Core Animation / Core Graphics / Metal など）は **歓迎**します。
> ただし、すべての実装は **公式ドキュメントを根拠**にし、推測で仕様を決めないでください。

---

## 🎯 Purpose

- 量子ゲートによる状態変換（ブロッホ球）を、**触って理解できるゲーム体験**として提供する
- Student Challenge向けに、**短時間で価値が伝わる（3分以内）**設計を徹底する
- 実装は **Swift 6** の言語機能・並行性（Concurrency）を適切に活用する
- アーキテクチャは既存の定番に乗せ、**読みやすく、拡張に耐える**構造にする

---

## ✅ 重要制約（Swift Student Challenge 想定）

- **完全オフライン**（ネットワーク依存なし）
- **サインイン禁止**
- 体験は **3分以内**で成立（ゲームは1分チャレンジ想定）
- リポジトリは軽量に保つ（重いアセット・巨大依存を避ける）
- 端末性能差を考慮（描画更新頻度・メモリ・電力）

---

## 🧱 Architecture（指定：必ず従う）

### 採用方針
- **Layered Architecture（DDD寄り）**
- **Presentation層は UIKit MVC**
- Clean Architecture という呼称は前面に出さない（思想として依存方向は守る）

### 依存方向（厳守）
```

Presentation  →  Application  →  Domain  →  Infrastructure

```

### レイヤー責務（概要）
- **Domain**: 量子の真実（ゲート/回路/状態/変換ルール）。UI・描画・時間・乱数を知らない
- **Application**: ゲーム進行（1分制・問題生成・判定・スコア）。Domainを「ゲーム」に翻訳
- **Presentation**: UIKit MVCで入力と表示を制御。ロジックはApplicationへ委譲
- **Rendering**（副作用/表現）: Core Animation / Core Graphics / Metal 等で描画と演出を担当（意味は持たない）
- **Infrastructure**: ローカル保存など技術的詳細（UserDefaultsなど）

> 注意：Rendering はレイヤーとしては「表現の隔離」。Domain/Application が Rendering に依存してはいけない。

---

## 📌 “ファイル名”について（重要）

- 本AGENTS.mdでは **ファイル名を指定しない**。
- ただし、**レイヤー分割・責務・依存方向**は必ず守る。
- 新規ファイル作成時は、以下のルールに従う：
  - **1ファイル1責務**
  - 型名とファイル名は一致推奨（慣例）
  - UI層とDomain層で命名が混ざらないこと（例：Domainに`View`/`Controller`を置かない）

---

## 🧠 Domain Rules（DDD Core）

### Domain の必須ルール
- UIKit / CoreAnimation / Metal / CoreGraphics を **importしない**
- 副作用ゼロ（時間参照・乱数生成・永続化を含めない）
- 値型（`struct`）中心、純粋関数中心
- Swift 6 の `Sendable` を意識（安全で明確なデータ構造）

### Domain が扱う概念（例）
- 量子ゲート（種類・合成・適用）
- 回路（ゲート列）
- 量子状態（内部表現：状態ベクトル等）
- 表示用のブロッホベクトル（UIへ渡す値）

---

## 🎮 Application Rules（Game / Use-case）

### Application の責務
- 1分チャレンジの開始/停止/次問題生成
- 正解判定（Domainの結果を用いる）
- スコア計算（解けた数、連続正解、短回路優遇など）
- ランキング（ローカルTop5）に渡すデータ整形

### 禁止事項
- UIKit（UIView/UIViewController）を直接操作しない
- Rendering の型に依存しない
- Domain の副作用を増やさない（乱数・時間はApplication側で扱う）

---

## 🖼 Presentation Rules（UIKit MVC）

### Controller（UIViewController）
- UIイベントの司会者（入力受付・画面更新）
- Application のAPIを呼び、結果を表示へ反映
- Massive View Controller を避ける（UI制御に集中）

### View（UIView / CALayer）
- 描画・レイアウト・アニメーション実行
- 受け取るのは「値」だけ（状態ベクトルやゲート列などの表示用データ）

### UI State（画面用の状態）
- 画面表示に必要な最小の状態だけを保持
- Domainの型をそのままUIへ曝露しない（必要なら変換する）

---

## 🎨 Rendering Strategy（低レイヤー歓迎）

本プロジェクトは **体験最優先**。低レイヤーAPIの活用を推奨する。

### 推奨技術（主軸）
- **Core Animation**: 状態遷移補間、成功演出（スライド/回転/フェード）、タイミング制御
- **Core Graphics**: ゲート記号アイコン、回路スロット、時間バー、2D説明要素
- **Metal**: ブロッホ球の3D表現（奥行き・ライティング・滑らかさ）
- **UIKit Dynamics**: 慣性など触感の演出（ルールに影響させない）

### Rendering の絶対ルール
- Rendering は「描く」だけ。**意味（ルール）は持たない**
- Domain の演算ロジックを Rendering に書かない
- 描画更新頻度を制御（電力/熱/フレーム落ちを避ける）

---

## ⚡ Swift 6 / Concurrency（積極採用）

### 基本原則
- UI更新は `@MainActor`（メインスレッド）
- 共有可変状態は `actor` または `@MainActor` に閉じ込める
- `Sendable` 警告を放置しない（`@unchecked Sendable` は最終手段）

### ゲームループ
- 可能なら structured concurrency（`Task` / `Task.sleep` 等）を優先
- フレーム同期が必要な場合のみ `CADisplayLink` を検討（最小限）

---

## 💾 Persistence（ローカルのみ）

- 保存は **UserDefaults** を基本とする（軽量・オフライン・確実）
- 保存対象：
  - 自己ベスト Top5（ローカルランキング）
  - 直近スコア（任意）
- 外部ランキング、共有、ネットワーク同期は行わない

---

## 🧪 Testing（推奨）

- Domain はユニットテストを優先（XCTest）
  - ゲート適用
  - 合成結果
  - 状態の正規化・不変条件
- Rendering のテストは必須ではない（負担が大きい）
- Application はスコア計算など重要部のみ必要に応じて

---

## 📚 Official Docs First（最重要）

AIは必ず以下を遵守すること：

1. **公式ドキュメントを優先して読む**
2. 仕様が不明確な場合、推測で決めず「公式の根拠に基づく実装」を選ぶ
3. 非公式ブログ・個人記事は補助扱い（根拠は公式に置く）

対象例（必ず公式を参照する領域）：
- Swift 6 / Concurrency / Sendable / MainActor
- UIKit Drag & Drop（UIDragInteraction / UIDropInteraction）
- Core Animation（CALayer / CAAnimation）
- Core Graphics（CGContext / Drawing）
- Metal（MTLDevice / CAMetalLayer / シェーダ）
- UIKit Dynamics

---

## 🧩 UX Priorities（体験の優先順位）

- 1分でテンポよく遊べる
- 成功時の快感（演出）を重視
  - 回路内ゲートが右にスライドして消える
  - 目標側のブロッホ球が回転し、新目標へ
- 「理解が速さに変わる」設計（反射神経だけで勝てない）
- 数式・説明文は最小限（体験が説明する）

---

## 🧹 Implementation Rules（実装の原則）

- 迷ったら **Domainの純粋性**を守る
- 迷ったら **依存方向**を守る
- “低レイヤー歓迎”だが、**無理に使って複雑化しない**
- コードは読みやすさ優先（審査員が短時間で理解できる）

---

## 🔒 Absolute DO / DON'T

### DO
- Swift 6 の安全性を活かす（Sendable/Actor/MainActor）
- レイヤー分離を厳守
- 体験を優先し、表現は低レイヤーで磨く
- 公式ドキュメントを根拠に実装する

### DON'T
- Domain に UIKit / Rendering を混ぜる
- ViewController に量子ロジックを押し込む
- 推測でAPIの仕様を断定する
- ネットワーク依存・サインイン追加
- 巨大アセット・外部ライブラリ増殖

---

## 🧭 Decision Guide（“どこに書く？”の判断）

- 量子の真実（ゲート/状態/回路/変換） → **Domain**
- ゲームのルール（時間制限/問題生成/判定/スコア） → **Application**
- 入力と画面更新（ドラッグ&ドロップ/画面遷移） → **Presentation**
- 見た目（描画/アニメ/演出/Metal） → **Rendering**
- 保存（Top5など） → **Infrastructure**
```

必要なら、このAGENTS.mdに「Notion貼り付け用の開発手順（チェックリスト形式）」も追加して、AIが迷わず順番通り実装できる形に整えられるよ。
