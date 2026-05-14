# 舟読み

競艇予想アプリのMVPです。仮データで動きます。

## 入っている機能

- 今日のレース一覧
- レース詳細
- ルールベース予想
- 本命、対抗、穴
- 3連単候補
- 予想根拠
- 結果登録
- 的中率、回収率の集計

## 開き方

Macでこのフォルダを開きます。

```sh
cd ios/BoatRacePredictor
xcodegen generate
open BoatRacePredictor.xcodeproj
```

XcodeGenがない場合:

```sh
brew install xcodegen
```

## TestFlightに上げる

Macがない場合は、GitHub Actionsで進めます。このフォルダをGitHubリポジトリにpushしたあと、Actionsから実行します。

### 必要なGitHub Secrets

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_API_KEY_CONTENT`
- `DIST_CERT_BASE64`
- `DIST_CERT_PASSWORD`
- `KEYCHAIN_PASSWORD`

`ASC_API_KEY_CONTENT` は `.p8` をbase64化した値です。

```sh
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

### 1. Bundle ID登録

GitHubのActions画面で `Register Bundle ID` を手動実行します。

登録するBundle ID:

```text
com.tokyonasu.boatracepredictor
```

### 2. App Store Connectでアプリ作成

Bundle ID登録後、App Store Connectで新規アプリを作ります。

- 名前: 舟読み
- Bundle ID: `com.tokyonasu.boatracepredictor`
- SKU: `boatracepredictor`
- プラットフォーム: iOS

### 3. TestFlightアップロード

GitHubのActions画面で `Build and Upload to TestFlight` を手動実行します。

アップロード後、App Store ConnectのTestFlight画面で処理完了を待ちます。最初の外部テストはAppleのベータ審査が入ります。内部テストだけなら、処理完了後に配布できます。

## Macで上げる場合

先にBundle IDを登録します。

```sh
cd ios/BoatRacePredictor
ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx python3 scripts/register_bundle_id.py
```

登録するBundle ID:

```text
com.tokyonasu.boatracepredictor
```

そのあと、App Store Connectで新規アプリを作ります。

- 名前: 舟読み
- Bundle ID: `com.tokyonasu.boatracepredictor`
- SKU: `boatracepredictor`
- プラットフォーム: iOS

次に、App Store Connect APIキーをMacに置きます。

```sh
mkdir -p ~/.appstoreconnect/private_keys
cp AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
```

アップロードします。

```sh
cd ios/BoatRacePredictor
chmod +x scripts/build_testflight.sh
ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ./scripts/build_testflight.sh
```

ビルド番号を指定したい場合:

```sh
APP_VERSION=0.1 BUILD_NUMBER=2 ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ./scripts/build_testflight.sh
```

アップロード後、App Store ConnectのTestFlight画面で処理完了を待ちます。

## 次にやること

- 公式データや許可されたデータ元との接続
- レース結果の自動取得
- オッズ表示
- App Store用の正式アイコン作成
- 予想ロジックの検証と重み調整

## 注意

このアプリの予想は参考情報です。的中や利益を保証するものではありません。
