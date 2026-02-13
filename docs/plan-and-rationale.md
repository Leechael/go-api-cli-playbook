# go-api-cli-playbook Plan And Rationale

## 1) 背景与动机

你在两个 Go CLI 项目（`customerio-skills`、`roamresearch-skills`）中反复遇到相似工程问题：

- GitHub Actions 工作流重复修改、易漂移
- BDD/TDD 执行策略不一致
- 发布流程可恢复性不足
- CLI 输出给脚本/LLM 的契约不稳定
- 文档中的 `gh release` / `download` 示例与实际产物命名经常对不上

目标不是抽象业务逻辑，而是抽象“API -> CLI 工程化落地方法”。

## 2) 目标

构建一个独立 skill 仓库 `go-api-cli-playbook`，沉淀可复用的：

1. 工程流程（初始化、测试、发布）
2. GitHub Actions 模板（CI / release command / release on tag）
3. 质量门禁（prek pre-commit）
4. 发布命名契约（解决 download 名称漂移）
5. 审计脚本（可自动发现配置漂移）
6. OpenAPI-only 启动路径（仅凭 `openapi.json` 生成命令与测试计划）

## 3) 设计原则

1. 单一事实源（Single Source of Truth）
- 发布命名由 `release-naming.env` 统一管理，不允许在 README 或 workflow 随意硬编码。

2. 先门禁，后测试
- 本地和 CI 都要求先过 `prek`，再执行测试。

3. 可组合而非强绑定
- 发布支持两种策略：GoReleaser 与 Manual Packaging；通过模板选择，不把项目锁死在单一路径。

4. 失败可恢复
- release-command 负责“解析/授权/打 tag”；发布由 tag workflow 负责，降低耦合。

5. 脚本化关键逻辑
- 版本计算、下载命令生成、命名审计都脚本化，减少手工复制错误。

6. 最小可用但可扩展
- 先提供统一模板与 checklist，再按具体项目收敛细节。

7. Spec-first 可交付
- 允许在没有现成代码时，只根据 `openapi.json` 先生成命令覆盖计划和测试矩阵，再进入实现。

## 4) 核心产出结构

- `SKILL.md`
  - 统一流程与强约束
- `references/`
  - `github-actions-comparison.md`
  - `github-actions-adoption-checklist.md`
  - `openapi-first-delivery.md`
  - `release-packaging-strategies.md`
  - `prek-precommit.md`
- `assets/templates/`
  - `.github/workflows/go-ci.yml`
  - `.github/workflows/release-command.yml`
  - `.github/workflows/release-on-tag.yml`
  - `.github/workflows/release-on-tag-manual.yml`
  - `prek.toml`
  - `release-naming.env`
  - `scripts/next-version.sh`
- `scripts/`
  - `init-prek.sh`
  - `init-release-naming.sh`
  - `openapi-bootstrap.sh`
  - `print-release-download.sh`
  - `audit-workflows.sh`
  - `audit-release-naming.sh`

## 5) 关键决策与原因

1. 引入 `prek`
- 原因：把格式化/快速校验前移，减少 CI 才暴露的问题。

2. 增加 release naming contract
- 原因：修复“文档/命令和真实产物名不一致”的高频错误。

3. 增加 manual packaging 模板
- 原因：不同项目 release packaging 策略不同，不能只给 GoReleaser 路径。

4. 增加 naming 审计
- 原因：即使有模板，后续维护仍会漂移，需自动检测。

5. 增加 OpenAPI bootstrap
- 原因：新项目常只有 API 文档，先生成“命令计划 + 测试矩阵”可降低启动成本并防止漏接口。

## 6) 当前约束

- workflow 模板中的占位符（如 `your-cli`）必须在落地时替换。
- `release-naming.env` 必须与 workflow 触发 tag 模式一致。
- `gh release download` 示例必须通过 `scripts/print-release-download.sh` 生成。

## 7) 推荐落地顺序（给目标仓库）

1. `scripts/init-release-naming.sh <repo-dir>`
2. `scripts/init-prek.sh <repo-dir>`
3. 复制 workflow 模板并替换占位符
4. 运行：
   - `scripts/audit-workflows.sh <repo-dir>`
   - `scripts/audit-release-naming.sh <repo-dir>`
5. 本地执行：
   - `prek run --all-files`
   - `go test ...`
6. 如果是文档先行项目：
   - `scripts/openapi-bootstrap.sh <openapi.json> <repo>/docs/openapi`

## 8) 后续演进建议

1. 把 workflow 中占位符替换步骤做成自动化脚本（按 `release-naming.env` 渲染）。
2. 为 `audit-release-naming.sh` 增加对 README 中下载命令的检测。
3. 在真实仓库（例如 `gogcli`）做一次端到端接入并回灌经验。
