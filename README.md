# ao-dinosaur-excavation-survey
碧和の恐竜発掘ゲーム

## iOSネイティブ版（最初のマイルストーン）

`ios-native-v1` に SwiftUI + SpriteKit 版を追加しました。

- Xcodeで `ios/DinosaurDig.xcodeproj` を開き、`DinosaurDig` scheme を実行します。
- iOS 17.0以降、iPhone縦画面。外部パッケージ・ネットワーク接続は不要です。
- ブラシで発掘 → ハンマーで岩を割る → 拡大して骨をみがく → 8個収集 → 骨格完成。
- 詳しいシミュレータ・実機手順は [ios/README.md](ios/README.md)。
- 設計とWeb版からの対応は [ios/ARCHITECTURE.md](ios/ARCHITECTURE.md)。

既存のWeb版 `index.html` は保持しています。iOS版はWebViewを使用していません。
