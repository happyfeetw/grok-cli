# 打包说明 — `@spikewang/grok-cli`

[English](README.md) | **简体中文**

本 fork 的分发渠道：

| 渠道 | 包名 / formula | 平台 |
|------|----------------|------|
| **npm** | `@spikewang/grok-cli` | macOS arm64 + x64（optionalDependencies） |
| **Homebrew** | `happyfeetw/grok-cli` tap → `grok-cli` | macOS arm64 + x64 |
| **GitHub Releases** | `grok-cli-<version>-darwin-<arch>.tar.gz` | 仅 macOS |

## 版本唯一来源

```text
packaging/VERSION
```

该文件一行版本号（**不要**带前缀 `v`）是 **唯一的产品版本**，会同步到：

- npm 的 `package.json`（`packaging/npm/**`，经 `sync-version.js`）
- Homebrew formula（`Formula/grok-cli.rb`）
- Git tag（`v` + 版本，如 `v0.1.223`）
- GitHub Release 资源文件名
- CLI 二进制（`grok-cli --version`，由 build script 注入）

### 产品版本 vs Cargo crate 版本

本仓库主体是 Rust monorepo，各 crate 的 `Cargo.toml` `version`（如
`0.1.220-alpha.4`、`0.2.0-dev`）只服务 crate 自身演进，**不是**用户可见的
CLI / npm 版本。

编译期解析见
`crates/codegen/xai-grok-version/product_version_for_build.rs`：

1. 环境变量 `GROK_VERSION`（发版 CI 显式设置）
2. 否则读 `packaging/VERSION`
3. 否则 `0.0.0-dev`（**绝不用** `CARGO_PKG_VERSION` 冒充产品版本）

发版 CI 另设 `GROK_RELEASE_BUILD=1`：若拿不到 packaging 版本则 **直接失败**。

升级版本：

```sh
echo '0.1.224' > packaging/VERSION
node packaging/scripts/sync-version.js
```

打 tag 发版前，请在仓库根目录 [`CHANGELOG.md`](../CHANGELOG.md) 为新版本写好
Keep a Changelog 小节。发布流水线会用
`packaging/scripts/extract-changelog.js` 把该小节写进 GitHub Release 正文。

本地（有 `packaging/VERSION` 时会自动 stamp）：

```sh
cargo build -p xai-grok-pager-bin --release
./target/release/xai-grok-pager --version
```

## GitHub Release 资源命名

```text
grok-cli-<version>-darwin-arm64.tar.gz
grok-cli-<version>-darwin-arm64.tar.gz.sha256
grok-cli-<version>-darwin-x64.tar.gz
grok-cli-<version>-darwin-x64.tar.gz.sha256
```

每个 tar 内含单个可执行文件 **`grok-cli`**（不是 `grok`）。

## 本地干跑

```sh
# 本机 cargo build --release 之后
export GROK_DARWIN_ARM64=target/release/xai-grok-pager   # Apple Silicon 示例
node packaging/scripts/sync-version.js
node packaging/scripts/assemble-npm.js
```

## 发布（CI）

推送与 `packaging/VERSION` 一致的 tag：

```sh
VERSION=$(cat packaging/VERSION)
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "v${VERSION}"
```

CI 将：构建 macOS 二进制 → 创建 GitHub Release → 更新 Homebrew formula →
`npm publish`（需要仓库 Secret `NPM_TOKEN`）。

仅从已有 Release 发布 npm（不重新编译）可使用工作流
[Publish npm](../.github/workflows/npm-publish.yml)。
