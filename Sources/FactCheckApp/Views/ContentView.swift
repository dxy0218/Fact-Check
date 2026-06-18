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
            LazyVStack(alignment: .leading, spacing: 18) {
                overview
                inputSection
                resultsSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 92)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("核查")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focusedField = nil
                }
            }
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.teal)
                    .frame(width: 42, height: 42)
                    .background(Color.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("事实核查")
                        .font(.title3.weight(.semibold))
                    Text("把说法、原文或链接放进来，整理公开来源线索。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ViewThatFits {
                HStack(spacing: 8) {
                    statusChip("联网检索", icon: "network")
                    statusChip("来源可追溯", icon: "link")
                    statusChip("本地历史", icon: "clock")
                }

                VStack(alignment: .leading, spacing: 8) {
                    statusChip("联网检索", icon: "network")
                    statusChip("来源可追溯", icon: "link")
                    statusChip("本地历史", icon: "clock")
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("待核查内容", subtitle: "先填一句核心说法；原文和链接有就补上。")

            TextField("例如：喝咖啡会导致脱水吗？", text: $viewModel.claim, axis: .vertical)
                .focused($focusedField, equals: .claim)
                .textFieldStyle(.plain)
                .submitLabel(.next)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onSubmit { focusedField = .content }

            VStack(alignment: .leading, spacing: 7) {
                Text("原文")
                    .font(.subheadline.weight(.medium))
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.content)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 112)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    if viewModel.content.isEmpty {
                        Text("粘贴文章片段、聊天记录或截图转写内容。")
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

            quickActions
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                focusedField = nil
                viewModel.performCheck()
            } label: {
                HStack {
                    if viewModel.isChecking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(viewModel.isChecking ? "正在核查" : "开始核查")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmit)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.fillExample()
            } label: {
                Label("填入示例", systemImage: "text.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isChecking)

            Button {
                viewModel.resetInputs()
            } label: {
                Label("清空", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.hasInput || viewModel.isChecking)
        }
        .controlSize(.regular)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("结果", subtitle: viewModel.results.isEmpty ? "完成一次核查后会保存在这里。" : "最近 \(viewModel.results.count) 条")
                Spacer()
                if !viewModel.results.isEmpty {
                    Button(role: .destructive) {
                        viewModel.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("清空历史")
                    .disabled(viewModel.isChecking)
                }
            }

            if viewModel.results.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.results) { result in
                        FactCheckResultCard(result: result)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    private var contextField: some View {
        TextField("补充上下文（可选）", text: $viewModel.context, axis: .vertical)
            .focused($focusedField, equals: .context)
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var sourceField: some View {
        TextField("来源链接（可选）", text: $viewModel.sourceURL)
            .focused($focusedField, equals: .sourceURL)
            .textFieldStyle(.plain)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("还没有结果")
                .font(.subheadline.weight(.semibold))
            Text("建议先放入一句明确说法，再补充原文或来源链接。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func statusChip(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground), in: Capsule())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(viewModel: FactCheckViewModel())
        }
    }
}
