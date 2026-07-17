<div align="center">

<p><a href="README.md">English</a> | <strong>简体中文</strong></p>

<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://media.x.ai/v1/website/spacexai-symbol-white-transparent-0c31957f.png">
    <source media="(prefers-color-scheme: light)" srcset="https://media.x.ai/v1/website/spacexai-symbol-black-transparent-6435cf42.png">
    <img alt="SpaceXAI logo" src="https://media.x.ai/v1/website/spacexai-symbol-black-transparent-6435cf42.png" width="96">
  </picture>
  <br>
  Grok Build (<code>grok</code>)
</h1>

<p align="center">
  <a href="https://linux.do"><img src="https://shorturl.at/ggSqS" alt="LINUX DO" /></a>
</p>

<p>
  <a href="https://www.npmjs.com/package/@spikewang/grok-cli">
    <img
      src="https://img.shields.io/npm/v/@spikewang/grok-cli?style=for-the-badge&logo=npm&logoColor=white"
      alt="npm @spikewang/grok-cli"
    />
  </a>
  <a href="LICENSE">
    <img
      src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge"
      alt="Apache-2.0"
    />
  </a>
</p>

**Grok Build** 是 SpaceXAI 的终端 AI 编程助手。它以全屏 TUI 形式运行，能理解代码库、编辑文件、执行命令、检索网页并管理长时间任务——支持交互、无界面（脚本/CI）以及通过 Agent Client Protocol（ACP）嵌入编辑器。

[安装](#安装) ·
[更新日志](CHANGELOG.md) ·
[从源码构建](#从源码构建) ·
[HTTP 代理](#http-代理) ·
[文档](#文档) ·
[仓库结构](#仓库结构) ·
[开发](#开发) ·
[贡献](#贡献) ·
[许可证](#许可证)

![Grok Build TUI](https://media.x.ai/v1/website/universe-tui-screenshot-6f7a0837.png)

**了解官方 Grok Build： [x.ai/cli](https://x.ai/cli)**

本仓库是开源 Grok Build 的 **社区 fork**（上游：[xai-org/grok-build](https://github.com/xai-org/grok-build)），额外提供打包与 system-proxy 相关修复。**欢迎贡献。**

</div>

---

## 安装

本仓库是社区 fork（`happyfeetw/grok-cli`）：重新启用了 **system-proxy**，并以 **`grok-cli`** 为产品名提供以 macOS 为主的分发渠道。

版本唯一来源：[`packaging/VERSION`](packaging/VERSION)（与 git tag `v*`、npm、Homebrew 对齐）。

本 fork 的变更说明见 [`CHANGELOG.md`](CHANGELOG.md)，并会同步展示在
[GitHub Releases](https://github.com/happyfeetw/grok-cli/releases) 页面。

### npm / bun（macOS）

```sh
npm install -g @spikewang/grok-cli
# 或
bun add -g @spikewang/grok-cli

grok-cli --version
```

安装后的命令是 **`grok-cli`**（不是 `grok`），不会覆盖或抢占官方 SpaceXAI/xAI
的 `grok` 命令。

应用内更新（`grok-cli update` / 自动更新）只拉 **本 fork**：npm 包
`@spikewang/grok-cli` 与 GitHub Releases 仓库 `happyfeetw/grok-cli`，
**不会**走 `x.ai/cli` 或 `@xai-official/grok`。

当前仅发布 **macOS** 平台可选依赖：

| 包名 | 平台 |
|------|------|
| `@spikewang/grok-cli` | 元包（trampoline + postinstall） |
| `@spikewang/grok-cli-darwin-arm64` | Apple Silicon |
| `@spikewang/grok-cli-darwin-x64` | Intel |

### Homebrew（macOS）

```sh
brew tap happyfeetw/grok-cli https://github.com/happyfeetw/grok-cli
brew install grok-cli
grok-cli --version
```

Formula：[`Formula/grok-cli.rb`](Formula/grok-cli.rb)（sha256 由发布流水线更新）。

### GitHub Releases（macOS tar 包）

其它安装方式仅保留 GitHub Release 归档：

```text
grok-cli-<version>-darwin-arm64.tar.gz
grok-cli-<version>-darwin-x64.tar.gz
```

每个归档内含单个 **`grok-cli`** 可执行文件（以及对应的 `.sha256`）。

```sh
tar -xzf grok-cli-<version>-darwin-arm64.tar.gz
install -m 755 grok-cli ~/.local/bin/grok-cli
```

参见 [Releases](https://github.com/happyfeetw/grok-cli/releases)。

### 官方上游安装方式

SpaceXAI 官方构建（**非**本 fork）：

```sh
curl -fsSL https://x.ai/cli/install.sh | bash   # macOS / Linux / Git Bash
irm https://x.ai/cli/install.ps1 | iex          # Windows PowerShell
```

## 从源码构建

依赖：

- **Rust** — 版本由 [`rust-toolchain.toml`](rust-toolchain.toml) 固定；首次构建时 `rustup` 会自动安装。
- **protoc** — 代码生成会查找 [`bin/protoc`](bin/protoc)（[dotslash](https://dotslash-cli.com) 启动器），否则回退到 `PATH` / `$PROTOC` 中的 `protoc`。
- 支持在 macOS 与 Linux 上构建；Windows 为尽力支持，本树未做系统测试。

```sh
cargo run -p xai-grok-pager-bin              # 构建并启动 TUI
cargo build -p xai-grok-pager-bin --release  # 产物：target/release/xai-grok-pager
cargo check -p xai-grok-pager-bin            # 快速校验
```

Cargo 产物名为 `xai-grok-pager`。本 fork 安装为 **`grok-cli`**，与官方 `grok`
命令区分：

```sh
mkdir -p ~/.local/bin
install -m 755 target/release/xai-grok-pager ~/.local/bin/grok-cli
```

请确保 `~/.local/bin` 在 `PATH` 中。首次启动会打开浏览器完成登录——见
[认证指南](crates/codegen/xai-grok-pager/docs/user-guide/02-authentication.md)。

打包细节（版本同步、npm 组装、formula 更新）见
[`packaging/README.md`](packaging/README.md) /
[`packaging/README.zh-CN.md`](packaging/README.zh-CN.md)。

## HTTP 代理

共享 HTTP 客户端（API、采样、上传、MCP HTTP 传输）通过 reqwest 的
`system-proxy` 发现代理：

| 平台 | 行为 |
|------|------|
| **macOS** | 对应环境变量未设置时，读取 **系统设置 → 网络 → 代理** |
| **Linux** | 仅环境变量（`HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`、`NO_PROXY`） |
| Windows | 同一 feature 也会读 Internet Settings；本树对 Windows 仍为尽力支持 |

显式 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` / `NO_PROXY` **始终优先于** 系统设置。
不解析 PAC / 自动配置脚本；代理在进程级 client 首次创建时读取。

## 文档

在线文档： [docs.x.ai/build/overview](https://docs.x.ai/build/overview)。

用户指南随 pager crate 提供：
[`crates/codegen/xai-grok-pager/docs/user-guide/`](crates/codegen/xai-grok-pager/docs/user-guide/)
— 入门、快捷键、斜杠命令、配置、主题、MCP、skills、插件、hooks、无界面模式、沙箱等。

## 仓库结构

| 路径 | 内容 |
|------|------|
| `packaging/` | 版本文件、npm 包（`@spikewang/grok-cli*`）、发布脚本 |
| `Formula/grok-cli.rb` | Homebrew formula |
| `crates/codegen/xai-grok-pager-bin` | 组合根；产出 `xai-grok-pager` 二进制 |
| `crates/codegen/xai-grok-pager` | TUI：滚动区、提示、弹窗、渲染 |
| `crates/codegen/xai-grok-shell` | Agent 运行时 + leader/stdio/无界面入口 |
| `crates/codegen/xai-grok-tools` | 工具实现（终端、文件编辑、搜索等） |
| `crates/codegen/xai-grok-workspace` | 主机文件系统、VCS、执行、检查点 |
| `crates/codegen/...` | 其余 CLI 依赖闭包（配置、MCP、markdown、沙箱等） |
| `crates/common/`、`crates/build/`、`prod/mc/` | 闭包中的小型叶子 crate |
| `third_party/` | 上游 vendored 源码（Mermaid 图栈） |

> [!IMPORTANT]
> 根目录 `Cargo.toml`（workspace 成员、依赖版本、lint、profile）按上游风格视为
> **生成物**——尽量只读。优先修改各 crate 自己的 `Cargo.toml`。

## 开发

```sh
cargo check -p <crate>        # 尽量指定 crate；全 workspace 很慢
cargo test -p xai-grok-config # 按 crate 跑测试
cargo clippy -p <crate>       # 配置见根目录 clippy.toml
cargo fmt --all               # 配置见根目录 rustfmt.toml
```

## 贡献

**欢迎外部贡献。** Bug 报告、文档、打包改进与功能 PR 都很感谢。

流程与约定见 [`CONTRIBUTING.md`](CONTRIBUTING.md)（英文）/
[`CONTRIBUTING.zh-CN.md`](CONTRIBUTING.zh-CN.md)（中文）。

本项目感谢 [LINUX DO](https://linux.do) 社区。

## 许可证

本仓库第一方代码采用 **Apache License 2.0** — 见 [`LICENSE`](LICENSE)。

第三方与 vendored 代码保留其原许可证。参见：

- [`THIRD-PARTY-NOTICES`](THIRD-PARTY-NOTICES) — crates.io / git 依赖、内置 UI 主题、
  **树内源码移植**（含 openai/codex 与 sst/opencode 工具实现）
- [`crates/codegen/xai-grok-tools/THIRD_PARTY_NOTICES.md`](crates/codegen/xai-grok-tools/THIRD_PARTY_NOTICES.md)
  — codex / opencode 移植的 crate 本地声明
- [`third_party/NOTICE`](third_party/NOTICE) — Mermaid 相关 vendored 索引
