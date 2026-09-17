import SwiftUI
import SpriteKit

private enum Palette {
    static let paper = Color(red:0.97,green:0.93,blue:0.83)
    static let ink = Color(red:0.23,green:0.26,blue:0.20)
    static let green = Color(red:0.23,green:0.36,blue:0.28)
    static let orange = Color(red:0.74,green:0.34,blue:0.18)
}

struct DigView: View {
    @ObservedObject var store: GameStore
    @State private var scene = ExcavationScene(size:CGSize(width:360,height:460))
    @State private var showCollection = false
    @State private var confirmRestart = false
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 700
            VStack(spacing:compact ? 8 : 12) {
                header
                HStack {
                    Label(store.active == nil ? "はっくつフィールド" : "ほねの みがき室",systemImage:store.active == nil ? "location.north.circle" : "sparkles")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(store.active?.reading ?? "ティラノサウルス").font(.caption.bold())
                }
                .padding(.horizontal,4)
                ZStack {
                    SpriteView(scene:scene, options:[.ignoresSiblingOrder])
                        .accessibilityIdentifier("digField")
                        .accessibilityLabel(store.active == nil ? "発掘フィールド。ブラシでなぞり、岩はハンマーでタップ" : "骨のみがき面。茶色のよごれをなぞる")
                }
                .clipShape(RoundedRectangle(cornerRadius:24))
                .overlay(RoundedRectangle(cornerRadius:24).strokeBorder(Color(red:0.43,green:0.30,blue:0.19),lineWidth:4))
                .frame(maxHeight:.infinity)
                .layoutPriority(1)
                Text(store.message)
                    .font(.system(size:compact ? 12 : 14,weight:.semibold,design:.rounded))
                    .multilineTextAlignment(.center).frame(maxWidth:.infinity,minHeight:compact ? 30 : 38)
                    .accessibilityIdentifier("instruction")
                if store.active != nil { polishControls } else { fieldControls }
                collectionStrip(compact:compact)
                HStack {
                    Button { showCollection = true } label: { Label("ぜんたいを見る",systemImage:"square.grid.2x2") }
                        .accessibilityIdentifier("collection")
                    Spacer()
                    Button { store.hint(); scene.render() } label: { Label("ヒント",systemImage:"lightbulb") }
                        .accessibilityIdentifier("hint")
                }.font(.subheadline.bold()).padding(.horizontal,8).frame(minHeight:40)
            }
            .padding(.horizontal,16).padding(.top,compact ? 8 : 12).padding(.bottom,4)
            .background(Palette.paper)
            .foregroundStyle(Palette.ink)
        }
        .tint(Palette.green)
        .onAppear { scene.store = store; scene.render() }
        .onChange(of:store.expedition) { _, _ in scene.render() }
        .sheet(isPresented:$showCollection) {
            CollectionView(store:store, completed:false)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented:Binding(get:{store.complete},set:{_ in})) {
            CollectionView(store:store,completed:true)
        }
        .confirmationDialog("調査をはじめからやり直しますか？",isPresented:$confirmRestart,titleVisibility:.visible) {
            Button("進捗を消して、はじめから",role:.destructive) { store.restart() }
            Button("キャンセル",role:.cancel) { }
        } message: { Text("いま集めたほねと、みがいた記録がリセットされます。") }
    }
    private var header: some View {
        HStack(alignment:.center) {
            VStack(alignment:.leading,spacing:3) {
                Text("AO'S FIELD NOTES").font(.system(size:10,weight:.heavy,design:.monospaced)).tracking(2).foregroundStyle(Palette.orange)
                Text("きょうりゅう はっくつたい").font(.system(size:20,weight:.heavy,design:.rounded)).minimumScaleFactor(0.7).lineLimit(1)
            }
            Spacer(minLength:4)
            Menu {
                Toggle("振動",isOn:$store.haptics)
                Button("はじめから",role:.destructive) { confirmRestart = true }
            } label: {
                Image(systemName:"ellipsis.circle").font(.title2).frame(width:44,height:44)
            }.accessibilityLabel("設定")
        }
    }
    private var fieldControls: some View {
        HStack(spacing:10) {
            toolButton(.brush,title:"ブラシ",subtitle:"砂をはらう",symbol:"paintbrush.pointed.fill")
            toolButton(.hammer,title:"ハンマー",subtitle:"岩をわる",symbol:"hammer.fill")
        }
    }
    private func toolButton(_ tool: DigTool,title: String,subtitle: String,symbol: String) -> some View {
        Button { store.select(tool) } label: {
            HStack(spacing:10) {
                Image(systemName:symbol).font(.title2)
                VStack(alignment:.leading,spacing:2) { Text(title).font(.headline); Text(subtitle).font(.caption2) }
                Spacer(minLength:0)
                if store.tool == tool { Image(systemName:"checkmark.circle.fill").font(.caption) }
            }.padding(.horizontal,12).frame(maxWidth:.infinity,minHeight:60)
                .background(store.tool == tool ? Palette.green : Color.white.opacity(0.55),in:RoundedRectangle(cornerRadius:16))
                .foregroundStyle(store.tool == tool ? .white : Palette.ink)
                .overlay(RoundedRectangle(cornerRadius:16).strokeBorder(Palette.green.opacity(store.tool == tool ? 1 : 0.18),lineWidth:1))
        }.buttonStyle(.plain).accessibilityIdentifier(tool.rawValue)
            .accessibilityAddTraits(store.tool == tool ? .isSelected : [])
    }
    private var polishControls: some View {
        VStack(spacing:8) {
            HStack {
                Label("きれいさ",systemImage:"sparkles").font(.subheadline.bold())
                ProgressView(value:store.cleanFraction).tint(Palette.green).accessibilityIdentifier("cleanProgress")
                Text("\(Int(store.cleanFraction*100))%").font(.system(.headline,design:.rounded).monospacedDigit()).frame(width:48,alignment:.trailing)
            }
            HStack {
                Button { store.backToField() } label: { Label("発掘にもどる",systemImage:"arrow.left") }.font(.caption.bold()).frame(minHeight:44)
                    .accessibilityIdentifier("backToField")
                Spacer()
                Button { store.collect() } label: {
                    Text(store.cleanFraction == 1 ? "ほねをしまう" : "ぴかぴかにしよう")
                        .font(.subheadline.bold()).padding(.horizontal,16).frame(minHeight:44)
                }.buttonStyle(.borderedProminent).disabled(store.cleanFraction < 1).accessibilityIdentifier("collectBone")
            }
        }
    }
    private func collectionStrip(compact: Bool) -> some View {
        VStack(spacing:6) {
            HStack {
                Text("あつめた ほね").font(.caption.bold())
                Spacer()
                Text("\(store.count) / 8").font(.system(.subheadline,design:.rounded).bold().monospacedDigit())
                    .accessibilityIdentifier("boneCount")
            }
            HStack(spacing:5) {
                ForEach(BoneKind.allCases) { bone in
                    let found = store.expedition.bones[bone.rawValue].collected
                    VStack(spacing:3) {
                        Image(systemName:found ? "checkmark.circle.fill" : "circle.dashed").font(.system(size:compact ? 13 : 17))
                        Text(bone.reading).font(.system(size:8,weight:.bold)).minimumScaleFactor(0.7).lineLimit(1)
                    }.frame(maxWidth:.infinity).foregroundStyle(found ? Palette.green : Palette.ink.opacity(0.40))
                        .accessibilityElement(children:.ignore).accessibilityLabel("\(bone.title)、\(found ? "収集済み" : "未収集")")
                }
            }
        }.padding(10).background(Color.white.opacity(0.45),in:RoundedRectangle(cornerRadius:14))
    }
}

struct SkeletonView: View {
    let collected: Set<Int>
    var body: some View {
        Canvas { context,size in
            let scale = min(size.width / 560, size.height / 310)
            var layer = context
            layer.translateBy(x: (size.width - 560 * scale) / 2, y: (size.height - 310 * scale) / 2)
            layer.scaleBy(x: scale, y: scale)
            for bone in BoneKind.allCases {
                let path = Path(BoneArt.skeletonPath(for: bone))
                layer.fill(path, with: .color(collected.contains(bone.rawValue) ? Color(uiColor: BoneArt.cream) : .white.opacity(0.10)))
                layer.stroke(path, with: .color(collected.contains(bone.rawValue) ? Color(red: 0.62, green: 0.49, blue: 0.30) : .white.opacity(0.18)), lineWidth: 1.5)
            }
            if collected.contains(BoneKind.skull.rawValue) {
                layer.fill(Path(ellipseIn: CGRect(x: 438, y: 60, width: 19, height: 16)), with: .color(Palette.ink))
                layer.fill(Path(ellipseIn: CGRect(x: 508, y: 70, width: 7, height: 5)), with: .color(Palette.ink))
            }
        }.accessibilityLabel("ティラノサウルスの骨格。8部位のうち\(collected.count)部位を収集")
    }
}

struct CollectionView: View {
    @ObservedObject var store: GameStore
    let completed: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var revealed: Set<Int> = []
    var body: some View {
        ScrollView {
            VStack(spacing:20) {
                HStack {
                    Text(completed ? "EXPEDITION COMPLETE" : "SPECIMEN COLLECTION")
                        .font(.system(size:11,weight:.heavy,design:.monospaced)).tracking(2)
                    Spacer()
                    if !completed { Button("とじる") { dismiss() }.frame(minHeight:44) }
                }
                Image(systemName:completed ? "sparkles" : "square.grid.2x2").font(.largeTitle).foregroundStyle(Palette.orange)
                Text(completed ? "はっくつ せいこう！" : "ほねの コレクション")
                    .font(.system(size:28,weight:.heavy,design:.rounded)).accessibilityIdentifier(completed ? "completionTitle" : "collectionTitle")
                Text(completed ? "8このほねが そろったよ！" : "\(store.count) / 8 個 はっけん").font(.headline)
                VStack(spacing:0) {
                    SkeletonView(collected:completed ? revealed : Set(store.expedition.bones.indices.filter { store.expedition.bones[$0].collected }))
                        .frame(height:260)
                    Text("TYRANNOSAURUS REX").font(.system(size:11,weight:.medium,design:.monospaced)).tracking(3).foregroundStyle(.white.opacity(0.7)).padding(.bottom,20)
                }.background(Palette.ink,in:RoundedRectangle(cornerRadius:24))
                if completed {
                    Text(revealed.count == 8 ? "ぜんしんこっかく かんせい！" : "ほねを くみたてているよ")
                        .font(.headline).accessibilityIdentifier("assemblyState")
                }
                Text("ティラノサウルス").font(.title2.bold())
                Text("見つけて、みがいて、つなげよう。\nきみの手で、太古のすがたがよみがえる。")
                    .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Palette.ink.opacity(0.7))
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                    ForEach(BoneKind.allCases) { bone in
                        HStack {
                            Image(systemName:store.expedition.bones[bone.rawValue].collected ? "checkmark.circle.fill" : "circle.dashed")
                            Text(bone.title)
                            Spacer()
                            Text(String(format:"%02d",bone.rawValue+1)).font(.caption.monospaced())
                        }.font(.subheadline.bold()).padding(12).background(.white.opacity(0.5),in:RoundedRectangle(cornerRadius:12))
                    }
                }
                if completed {
                    Button { store.restart() } label: { Label("もういちど はっくつする",systemImage:"arrow.clockwise").frame(maxWidth:.infinity,minHeight:46) }
                        .buttonStyle(.borderedProminent).accessibilityIdentifier("restartExpedition")
                }
            }.padding(24)
        }.background(Palette.paper).foregroundStyle(Palette.ink).tint(Palette.green)
            .task {
                guard completed else { return }
                for bone in BoneKind.allCases {
                    do { try await Task.sleep(for:.milliseconds(180)) } catch { return }
                    _ = withAnimation(.easeOut(duration:0.25)) { revealed.insert(bone.rawValue) }
                }
                if store.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            }
    }
}
