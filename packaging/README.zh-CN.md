# 打包说明 — `@spikewang/grok-cli`

[English](README.md) | **简体中文**

本 fork 的分发渠道：

| 渠道 | 包名 / formula | 平台 |
|------|----------------|------|
| **npm** | `@spikewang/grok-cli` | macOS arm64 + x64（optionalDependencies） |
| **Homebrew** | `happyfeetw/grok-cli` tap → `grok-cli` | macOS arm64 + x64 |
| **GitHub Releases** | `grok-cli-<version>-darwin-<arch>.tar.gz` | 仅 macOS |

## 版本管理（上游约定 + SemVer 2.0）

二进制侧遵循 **官方 Grok Build** 约定：

```text
编译进二进制的 VERSION = 构建时环境变量 GROK_VERSION（若已设置）
                      | 否则 shipping crate 的 CARGO_PKG_VERSION（本地/开发）
```

| 角色 | 位置 | 说明 |
|------|------|------|
| 打包用版本源（fork） | [`packaging/VERSION`](VERSION) | 一行，不要 `v` 前缀 |
| 编译期 stamp | 环境变量 `GROK_VERSION` | **发版 CI 必须设置**（与上游相同） |
| 未 stamp 回退 | shipping crate 的 `Cargo.toml` `version` | pager-bin / pager / xai-grok-version |
| npm / formula / tag | `sync-version.js` 写入 | 来自 `packaging/VERSION` |
| `--version` 展示 | `VERSION_WITH_COMMIT` | `{version} ({git short sha})` |

### Fork 编号（SemVer 2.0 预发布后缀）

产品版本以 **上游三段号为基线**，本 fork 仅在本基线上的增量用 **预发布后缀**
`-N`（符合 [SemVer 2.0](https://semver.org/lang/zh-CN/)）：

| 场景 | `packaging/VERSION` 示例 | 含义 |
|------|--------------------------|------|
| 刚合入上游 `0.2.105` | `0.2.105-1` | 该基线上的第 1 个社区发版 |
| 下次合入上游前的 fork 改动 | `0.2.105-2`、`0.2.105-3`… | 只递增 `-N` |
| 上游新基线 `0.2.120` | `0.2.120-1` | 基线重置，后缀从 `-1` 重计 |

规则：

1. **基线 BASE** = 上游产品三段版本（合入后对照 monorepo shipping crates /
   `SOURCE_REV`，例如 `0.2.105`）。
2. **对外发布一律用** `BASE-N`，**不要**单独发裸 `BASE`。SemVer 下
   `0.2.105-1` < `0.2.105`，若先发过裸 `0.2.105`，后面的 `0.2.105-N` 会被
   npm / 更新检查当成更旧。
3. **N** 为正整数，仅在两次上游同步之间递增。
4. 再次合入上游后，改用新的三段基线并从 `-1` 开始。

合法示例：`0.2.105-1`、`0.2.105-2`、`0.2.120-1`。

升级并对齐打包面 + Cargo shipping crates：

```sh
echo '0.2.105-1' > packaging/VERSION
node packaging/scripts/sync-version.js
```

发版 CI：

```sh
export GROK_VERSION="$(tr -d '[:space:]' < packaging/VERSION)"
cargo build -p xai-grok-pager-bin --release
```

本地与发版相同 stamp：

```sh
export GROK_VERSION="$(tr -d '[:space:]' < packaging/VERSION)"
cargo build -p xai-grok-pager-bin --release
./target/release/xai-grok-pager --version
```

未设置 `GROK_VERSION` 时，`--version` 使用 shipping crate 的 Cargo 版本
（由 `sync-version.js` 与 `packaging/VERSION` 对齐）加上 git short SHA。

### 更新日志

打 tag 前在根目录 [`CHANGELOG.md`](../CHANGELOG.md) 写好对应版本小节。
流水线用 `extract-changelog.js` 写入 GitHub Release 正文。

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
export GROK_DARWIN_ARM64=target/release/xai-grok-pager
node packaging/scripts/sync-version.js
node packaging/scripts/assemble-npm.js --darwin-only
```

## 发布（CI）

```sh
VERSION=$(cat packaging/VERSION)
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "v${VERSION}"
```
