# 上游同步策略（本 fork）

[English](upstream-sync.md) | **简体中文**

社区 fork（`happyfeetw/grok-cli`）如何跟踪
[`xai-org/grok-build`](https://github.com/xai-org/grok-build)，并 **避免依赖 / MSRV 漂移**。

## 目标

1. **代码**：合入上游 `main`，保留 fork 差异（产品名 `grok-cli`、system-proxy、
   npm/Homebrew、SemVer `BASE-N`）。
2. **锁文件**：`Cargo.lock` 里所有带 `registry+` / `git+` 的第三方包，
   **name@version 必须与上游一致**；仅允许本 fork **system-proxy** 多出来的
   少量依赖（`system-configuration*` 等白名单）。
3. **工具链**：`rust-toolchain.toml` 的 `channel` **必须等于**
   [`.github/workflows/release-macos.yml`](../.github/workflows/release-macos.yml)
   里的 pin。只有上游 bump（或你明确要分叉）时才一起改。

## 合入上游后绝对不要做

| 命令 | 后果 |
|------|------|
| `cargo generate-lockfile` | 按「当前最新兼容」重解析 → 常升到 **高于** 钉死的 rustc（如 1.92）的依赖。 |
| 无 `-p` 的 `cargo update` | 整仓第三方版本漂移。 |
| 手改 `Cargo.lock` 随机版本 | 与上游分叉且难审查。 |
| 只改 CI 的 toolchain | 本地与 CI 编译器不一致。 |

## 标准流程

### 自动流程

[Sync upstream 工作流](../.github/workflows/upstream-sync.yml)每天运行：

1. GitHub 托管 runner 抓取一次 `upstream/main`，并固定完整 SHA。
2. 用 `--merge-only --no-fetch` 做真实 merge；这个阶段不运行 Cargo。
3. 无冲突时，由 GitHub 托管的 Linux / macOS runner 完成后处理、策略检查和
   两种 macOS 架构构建。候选分支通过后快进到 `main`，再显式触发
   `release-macos.yml`。
4. 有冲突时，创建带 `upstream-sync` 和 `needs-codex` 标签的 Issue。本机
   Codex 定时任务只在隔离 worktree 中解决 Git 冲突，并推送
   `automation/upstream-sync-<完整SHA>`；后处理、构建、合入和发布仍由同一
   GitHub 工作流完成。

本机冲突任务不得运行 Cargo、构建或发布，不得直接改写 `main`，也不得
force push。候选分支推送后先保留冲突 worktree；后续每次任务开始时，只有
确认候选提交已进入 `origin/main`、Issue 已关闭且 worktree 干净，才删除这个
精确 worktree。未完成现场继续保留；超过 7 天只告警，不自动强删。候选分支
成功合入且 release dispatch（发布调度）被接受后，GitHub Actions 才关闭
冲突 Issue。

### 手工流程

```bash
# 只做 merge；适合不希望本机产生 Rust 构建产物的情况。
git fetch upstream main
SHA="$(git rev-parse upstream/main)"
packaging/scripts/merge-upstream.sh --merge-only --no-fetch --ref "$SHA"

# 解决冲突并提交后，在构建 runner 上执行后处理。
packaging/scripts/merge-upstream.sh --finalize-only --no-fetch --ref "$SHA"

# 打 tag 前验证策略。
packaging/scripts/verify-upstream-policy.sh --no-fetch --ref "$SHA"
```

脚本会：

1. 独立手工运行时默认 fetch；自动流程传 `--no-fetch`，复用已经抓取并固定的
   commit，避免同一 job 重复 fetch。
2. `--merge-only` 只做 Git merge。冲突退出码为 `10`，且不会运行 Cargo 或
   版本写入脚本。
3. `--finalize-only` 要求固定的上游 commit 已是 `HEAD` 的祖先，然后对齐
   release toolchain pin，并采用该 commit 的 `Cargo.lock`。
4. 将 fork 发版号写成 **`{上游 shell 三段版本}-1`**（`packaging/VERSION` +
   `sync-version.js`）。
5. 后处理阶段 **仅**执行：
   ```bash
   cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
   ```
   只刷新 path 包在 lock 里的版本，不升级 crates.io。
6. `--check-only` 校验第三方 lock、toolchain 双处 pin，以及固定的上游 commit
   确实已经合入。

若已在同一 base 上需要发 `-2`/`-3`：脚本默认写成 `-1` 后，自行改
`packaging/VERSION`，再跑 `sync-version.js` 和上面的三条 `cargo update -p`。

## 锁文件已漂移时的恢复

```bash
git fetch upstream
git checkout upstream/main -- Cargo.lock
node packaging/scripts/sync-version.js   # packaging/VERSION 正确之后
cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
packaging/scripts/verify-upstream-policy.sh
```

## 何时升级 Rust

仅当 **上游** 提高 `rust-toolchain.toml`（或你接受 fork 长期更高 MSRV）。
自动后处理会对齐 release workflow 的 pin；手工修改时仍要 **两处一起改**：

1. `rust-toolchain.toml` → `channel = "…"`
2. `.github/workflows/release-macos.yml` → `toolchain: "…"`

改完跑 `packaging/scripts/verify-upstream-policy.sh`。

## 相关文档

- 打包 / SemVer `BASE-N`：[packaging/README.zh-CN.md](../packaging/README.zh-CN.md)
- 产品版本 stamp：发版 CI 的 `GROK_VERSION`（与上游约定一致）
