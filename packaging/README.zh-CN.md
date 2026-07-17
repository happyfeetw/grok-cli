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

该文件一行版本号（**不要**带前缀 `v`）会同步到：

- npm 的 `package.json`（`packaging/npm/**`）
- Homebrew formula（`Formula/grok-cli.rb`）
- Git tag（`v` + 版本，如 `v0.1.221`）
- GitHub Release 资源文件名

升级版本：

```sh
echo '0.1.222' > packaging/VERSION
node packaging/scripts/sync-version.js
```

## GitHub Release 资源命名

```text
grok-cli-<version>-darwin-arm64.tar.gz
grok-cli-<version>-darwin-arm64.tar.gz.sha256
grok-cli-<version>-darwin-x64.tar.gz
grok-cli-<version>-darwin-x64.tar.gz.sha256
```

每个 tar 内含单个可执行文件 **`grok`**。

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
