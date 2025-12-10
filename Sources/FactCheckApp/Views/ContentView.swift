import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: FactCheckViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                inputSection
                primaryAction
                resultsSection
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("事实核查")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("基于离线知识库的快速验证")
                        .font(.title2.weight(.semibold))
                    Text("录入陈述、补充上下文与来源后，即可得到可信度、证据与后续建议。")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 16) {
                Label("保持事实中立", systemImage: "sparkles")
                Label("支持离线知识库", systemImage: "externaldrive.connected.to.line.below")
                Label("建议与后续行动", systemImage: "arrow.uturn.right")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("输入与选项")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                TextField("需要核查的陈述（标题）", text: $viewModel.claim)
                    .textFieldStyle(.roundedBorder)

                contentEditor

                ViewThatFits {
                    HStack(spacing: 12) {
                        contextField
                        sourceField
                    }
                    VStack(spacing: 12) {
                        contextField
                        sourceField
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    infoPill(title: "联网 20+ 信源交叉比对", icon: "antenna.radiowaves.left.and.right")
                    infoPill(title: "支持文本与网页链接", icon: "link")
                    infoPill(title: "复杂情境按最高可能性回复", icon: "chart.bar")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var primaryAction: some View {
        Button {
            viewModel.performCheck()
        } label: {
            Label("立即核查", systemImage: "bolt.shield")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("核查结果")
                .font(.headline)

            if viewModel.results.isEmpty {
                ContentUnavailableView(
                    "尚无结果",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("提交第一条陈述后会在此展示核查记录。")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(spacing: 14, pinnedViews: []) {
                    ForEach(viewModel.results) { result in
                        FactCheckResultCard(result: result)
                    }
                }
            }
        }
    }

    private var contextField: some View {
        TextField("补充上下文（可选）", text: $viewModel.context)
            .textFieldStyle(.roundedBorder)
    }

    private var sourceField: some View {
        TextField("来源链接或网页（可选）", text: $viewModel.sourceURL)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.URL)
    }

    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容输入")
                .font(.subheadline.weight(.semibold))
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                if viewModel.content.isEmpty {
                    Text("在此粘贴需要核查的正文、聊天记录或网页片段。")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
            }
        }
    }

    private func infoPill(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(viewModel: FactCheckViewModel())
        }
    }
}
