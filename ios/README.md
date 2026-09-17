# あおの恐竜発掘 — iOS native v1

最初のマイルストーンはティラノサウルス1体です。図形とSF Symbolsだけで遊べます。画像生成、外部画像取得、WebView、外部パッケージは使っていません。

## Xcodeで起動

1. このブランチを取得します。
   ```sh
   git clone --branch ios-native-v1 https://github.com/soan4/ao-dinosaur-excavation-survey.git
   cd ao-dinosaur-excavation-survey
   open ios/DinosaurDig.xcodeproj
   ```
2. Schemeを **DinosaurDig** にします。
3. 実行先に **iPhone 15** などのiOS 17以降のシミュレータを選びます。
4. **⌘R** で起動します。シミュレータでは署名チームの設定は不要です。

開発環境の初回確認はXcode 15.2 / iOS 17.2です。新しいOSの実機を使う場合は、そのOSに対応するXcodeを使用してください。プロジェクトの最低対応OSはiOS 17.0です。iPhone専用・縦画面固定です。

シミュレータが見つからない場合は、Xcodeの Settings → Platforms からiOS Simulatorを導入してください。

## 遊び方

1. **ブラシ**を選び、砂のかたまりを指でなぞります。
2. 岩には**ハンマー**を選び、4回タップします。長押しやドラッグでは連打になりません。
3. 岩を割った後はブラシに持ち替え、砂をはらいます。
4. 見えた骨をブラシでさわると、中央に大きく表示するみがき室に入ります。
5. 骨の茶色い点をなぞります。きれいさが100%になると **ほねをしまう** が押せます。
6. 8個すべて集めると、骨格を順に表示する完成画面になります。

- **ヒント**は未収集の場所を光らせ、必要な道具に切り替えます。
- **ぜんたいを見る**で、収集済みの部位と骨格を確認できます。
- みがき途中でも**発掘にもどる**で退出でき、同じ骨をさわると続きから再開できます。
- 進捗は操作後とアプリが非アクティブになる時に端末内へ保存します。
- 右上メニューから振動を切り替え、または確認後に調査をリセットできます。
- シミュレータでは振動を体感できません。実機で確認してください。

## 実機で起動

1. Xcode → Settings → Accounts で自分のApple Accountを追加します。
2. プロジェクトの **TARGETS → DinosaurDig → Signing & Capabilities** を開きます。
3. **Automatically manage signing** を有効にして、自分の **Team** を選びます。
4. Bundle Identifier `com.soan4.aodinosaur.native` が利用できなければ、自分専用の一意な値に変更します。
5. iPhoneをMacに接続して「このコンピュータを信頼」を許可します。
6. iPhoneの設定 → プライバシーとセキュリティ → **デベロッパモード** を有効にし、端末の案内に従います。
7. Xcodeの実行先で接続したiPhoneを選び、**⌘R** を押します。
8. 必要な場合はiPhoneの設定 → 一般 → VPNとデバイス管理で開発者を信頼します。

このリポジトリにはTeam ID・証明書・Provisioning Profileを含めていません。実機署名と実機へのインストールは利用者のTeam設定が必要です。配布用のApp Storeアイコン、ストア情報、配布設定は本マイルストーンの対象外です。

## ビルドとテスト

リポジトリのルートから実行します。

```sh
# 署名不要のシミュレータ用ビルド
xcodebuild -project ios/DinosaurDig.xcodeproj -scheme DinosaurDig \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/ao-dinosaur-build CODE_SIGNING_ALLOWED=NO build

# ロジック + 実際のタップ・スワイプによる8個収集のUIテスト
xcodebuild -project ios/DinosaurDig.xcodeproj -scheme DinosaurDig \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath /tmp/ao-dinosaur-build \
  -resultBundlePath /tmp/ao-dinosaur-tests.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test

# iPhone SEで縦画面レイアウト確認
xcodebuild -project ios/DinosaurDig.xcodeproj -scheme DinosaurDig \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' \
  -only-testing:DinosaurDigUITests/ExcavationUITests/testPortraitFieldAndCollection \
  CODE_SIGNING_ALLOWED=NO test

# 実機アーキテクチャ向けコンパイルのみ（インストール用署名は別途必要）
xcodebuild -project ios/DinosaurDig.xcodeproj -scheme DinosaurDig \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

実行先の名前は `xcrun simctl list devices available` にあるものへ置き換えます。結果保存先 `.xcresult` は既存のパスを上書きできないため、再実行時は新しいパスを指定してください。Xcodeの **⌘U** でもテストできます。UIテストのスクリーンショットはTest ReportのAttachmentsに残ります。

UIテストは `--ui-testing` を付けて専用の保存領域を使います。普段のプレイ記録は消しません。アプリ起動用Schemeにこの引数を設定しないでください。

## 実機確認チェック

- ノッチ・ホームインジケータとボタンや進捗表示が重ならない。
- 砂はブラシだけ、岩はハンマーのタップだけに反応する。
- 素早いブラシ移動でも移動経路の汚れが落ちる。
- みがき面の全ての汚れに指が届き、100%まで進む。
- 別アプリへ移動・再起動後に収集数とみがき具合が戻る。
- 8部位収集後に完成画面が開き、再プレイできる。
- 振動ON/OFFと持ちやすさ・操作感を確認する。

## 検証結果

ロジック6件・UI2件のテストに成功しています。その後の飾りラベル削除はビルド確認済みですが、追加UIテストはランナー起動時の終了により未確認です。実施内容とスクリーンショットは [VALIDATION.md](VALIDATION.md) を参照してください。

## 現段階の範囲

図形による骨格は動作確認用です。Web版にあった3種のランダム選択は、種別と骨格の不一致を避けるためv1ではティラノサウルスに固定しています。音楽・効果音、追加の恐竜、地図、正式アート、VoiceOverによる発掘ジェスチャーの代替操作は今後の作業です。UIラベルとボタンにはアクセシビリティ情報を付けていますが、発掘自体は視覚と直接タッチを前提とします。
