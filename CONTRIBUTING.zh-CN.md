# 贡献指南

感谢关注 **grok-cli**——开源 [Grok Build](https://github.com/xai-org/grok-build)
的社区 fork，包含打包与 system-proxy 相关修复。**欢迎外部贡献。**

参与讨论与提交时，请保持尊重与建设性。严重辱骂或骚扰可能导致被限制互动。

英文版：[CONTRIBUTING.md](CONTRIBUTING.md)

## 可以怎么贡献

- 通过 [GitHub Issues](https://github.com/happyfeetw/grok-cli/issues) 报告缺陷与体验问题
- 建议功能或打包改进（npm、Homebrew、文档）
- 提交修复、文档、CI、功能相关的 Pull Request
- 改进翻译或面向用户的帮助文案

若不确定想法是否合适，可先开 Issue 说明问题与可能方案。

## 开始之前

1. 先搜索已有 [issues](https://github.com/happyfeetw/grok-cli/issues) 与
   [pull requests](https://github.com/happyfeetw/grok-cli/pulls)，避免重复。
2. 较大改动（新平台、依赖大版本升级、公共 API 变更）请先开 Issue 讨论再投入大量时间。
3. **安全漏洞不要公开提 Issue**，请遵循 [`SECURITY.md`](SECURITY.md) /
   [`SECURITY.zh-CN.md`](SECURITY.zh-CN.md)。

## 开发环境

构建与工具要求见 [`README.md`](README.md) / [`README.zh-CN.md`](README.zh-CN.md)
（「从源码构建」）。简要命令：

```sh
# 工具链由 rust-toolchain.toml 固定（rustup 会安装）
cargo check -p xai-grok-pager-bin
cargo test -p <crate>
cargo clippy -p <crate>
cargo fmt --all
```

优先对 **单个 crate** 做 `check` / `test` / `clippy`；全 workspace 构建很慢。

打包（版本、npm、Homebrew）见 [`packaging/`](packaging/) 与 [`Formula/`](Formula/)，
说明见 [`packaging/README.md`](packaging/README.md) /
[`packaging/README.zh-CN.md`](packaging/README.zh-CN.md)。

> [!IMPORTANT]
> 根目录 `Cargo.toml`（workspace 成员、依赖版本、lint、profile）按上游习惯视为
> **生成物**——请谨慎修改。优先编辑各 crate 的 `Cargo.toml`。

## Pull Request 流程

1. **Fork** 本仓库，并从 `main` 建分支：
   ```sh
   git checkout -b fix/short-description
   ```
2. 提交尽量聚焦。建议清晰的提交说明，例如：
   - `fix(http): honor NO_PROXY for local hosts`
   - `docs: clarify Homebrew install steps`
   - `ci: fix npm publish auth for granular tokens`
3. 对改动到的 crate 保证能构建且 lint 通过：
   ```sh
   cargo fmt --all
   cargo clippy -p <crate>
   cargo test -p <crate>
   ```
4. 推送到你的 fork，并向 `main` 开 PR。
5. PR 描述请写清：
   - **改了什么**、**为什么**
   - 如何测试
   - 相关 issue（如 `Fixes #123`）
6. 请配合 review；维护者可能要求修改或拆分过大的 PR。

### 什么样的 PR 更好

- 尽量一 PR 一事
- 不做无关的大范围格式化
- 用户可见行为或安装路径变更时同步更新文档
- 仅在有意发版时改版本（`packaging/VERSION` 等需保持一致）

### 可能被婉拒的改动

- 仓库中的密钥、凭证或个人隐私数据
- 无明确必要的依赖“顺手升级”
- 未经讨论重新关掉已启用的重要 feature（例如再次关闭 `system-proxy`）
- 大段无法说明问题与测试的生成代码堆砌

## Issue 指南

**缺陷报告** 尽量包含：

- 操作系统与架构（如 macOS 15 arm64）
- 安装方式（`npm`、Homebrew、Release tar、源码）
- 版本（`grok-cli --version` / 包版本）
- 复现步骤、期望与实际行为
- 相关日志（打码 token 与个人路径）

**功能请求** 请先说明用户痛点，而不只给实现方案。

## 许可

本项目采用 **Apache License 2.0** — 见 [`LICENSE`](LICENSE)。

除非另有明确说明，任何有意合入本项目的贡献均按相同的 Apache License 2.0
授权，不附加额外条件。

你确认有权提交该贡献（例如为原创，或已获授权）。

## 社区

- GitHub：[happyfeetw/grok-cli](https://github.com/happyfeetw/grok-cli) 上的
  Issue 与 PR
- 本项目感谢 [LINUX DO](https://linux.do) 社区

贡献相关问题欢迎通过 Issue 讨论。感谢帮助改进 grok-cli。
