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

```bash
# 1) 工作区干净后，一键 merge + 恢复上游 lock
packaging/scripts/merge-upstream.sh

# 2) 处理剩余冲突（保留 grok-cli 品牌 / system-proxy）
# 3) 更新 CHANGELOG 并 commit
# 4) 打 tag 前做策略检查
packaging/scripts/merge-upstream.sh --check-only
# 或
packaging/scripts/verify-upstream-policy.sh

# 5) 用 packaging/VERSION（如 0.2.110-1）打 tag 发版
```

脚本会：

1. `git fetch upstream` 并 merge（可用 `--ref <sha>`）。
2. **`git checkout <上游 tip> -- Cargo.lock`**，强制第三方与上游一致。
3. 将 fork 发版号写成 **`{上游 shell 三段版本}-1`**（`packaging/VERSION` + `sync-version.js`）。
4. **仅**执行：
   ```bash
   cargo update -p xai-grok-pager -p xai-grok-pager-bin -p xai-grok-version
   ```
   只刷新 path 包在 lock 里的版本，不升级 crates.io。
5. 校验第三方 lock 一致 + toolchain 双处 pin 一致。

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

仅当 **上游** 提高 `rust-toolchain.toml`（或你接受 fork 长期更高 MSRV）。然后 **两处一起改**：

1. `rust-toolchain.toml` → `channel = "…"`
2. `.github/workflows/release-macos.yml` → `toolchain: "…"`

改完跑 `packaging/scripts/verify-upstream-policy.sh`。

## 相关文档

- 打包 / SemVer `BASE-N`：[packaging/README.zh-CN.md](../packaging/README.zh-CN.md)
- 产品版本 stamp：发版 CI 的 `GROK_VERSION`（与上游约定一致）
