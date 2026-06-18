import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: FactCheckViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case claim
        case context
        case sourceURL
        case content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                inputSection
                actionBar
                resultsSection
            }
            .padding(.horizontal)
            .padding(.vertical, 18)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("事实核查")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focusedField = nil
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.teal, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("实时事实核查助手")
                        .font(.title2.weight(.semibold))
                    Text("输入陈述、正文或来源链接，应用会联网检索百科、新闻索引和原始网页，生成证据线索与可信度判断。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ViewThatFits {
                HStack(spacing: 10) {
                    featurePill("实时联网", icon: "network")
                    featurePill("来源追踪", icon: "link")
                    featurePill("本地历史", icon: "clock.arrow.circlepath")
                }

                VStack(alignment: .leading, spacing: 8) {
                    featurePill("实时联网", icon: "network")
                    featurePill("来源追踪", icon: "link")
                    featurePill("本地历史", icon: "clock.arrow.circlepath")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("核查内容")
                .font(.headline)

            TextField("需要核查的陈述", text: $viewModel.claim, axis: .vertical)
                .focused($focusedField, equals: .claim)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                Text("正文、截图转写或聊天记录")
                    .font(.subheadline.weight(.semibold))
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.content)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 118)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if viewModel.content.isEmpty {
                        Text("粘贴需要核查的正文片段，或把网页、群聊、帖子内容转写到这里。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
            }

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
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button {
                focusedField = nil
                viewModel.performCheck()
            } label: {
                Label(viewModel.isChecking ? "正在核查" : "立即核查", systemImage: viewModel.isChecking ? "hourglass" : "bolt.shield.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmit)

            if viewModel.isChecking {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.fillExample()
                } label: {
                    Label("填入测试内容", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.resetInputs()
                } label: {
                    Label("清空输入", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("核查结果")
                    .font(.headline)
                Spacer()
                if !viewModel.results.isEmpty {
                    Button(role: .destructive) {
                        viewModel.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("清空历史")

                    Text("\(viewModel.results.count) 条")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.results.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.results) { result in
                        FactCheckResultCard(result: result)
                    }
                }
            }
        }
    }

    private var contextField: some View {
        TextField("补充上下文（可选）", text: $viewModel.context, axis: .vertical)
            .focused($focusedField, equals: .context)
            .textFieldStyle(.roundedBorder)
    }

    private var sourceField: some View {
        TextField("来源链接（可选）", text: $viewModel.sourceURL)
            .focused($focusedField, equals: .sourceURL)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("暂无结果")
                .font(.subheadline.weight(.semibold))
            Text("提交第一条陈述后，结果会按时间倒序保存在这里。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func featurePill(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(viewModel: FactCheckViewModel())
        }
    }
}
