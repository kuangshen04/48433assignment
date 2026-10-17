# C4 视图 · 动态（事件接收与确认）

这是主场景：一条事件从参与方提交到 `CONFIRMED` 并可见。报告里的动态视图用它，替代按状态逐个讲的流水账。

**为什么用 sequence 形式而不是 numbered collaboration。** C4 的动态图通常是"编号协作图"，但这个场景有 9 个参与者，协作图会摊成 2500px 宽的横幅，在竖版页面里缩到读不出字。sequence 形式保留同样的编号与顺序，还天然给出阶段分隔——这正好对上"18 个状态折叠成 5 段"的需要。同一份交互，换一种更适合排版的画法。

<img src="/diagrams/c4-dynamic.svg" alt="Dynamic view: one event from submission to CONFIRMED, in five phases">

## 五个阶段与 18 个状态

状态机的完整定义见[事件接收与确认](/flows/event-acceptance)。主链 **13 个状态**（含 `REVIEW_REQUIRED` 旁路）加 **5 个终止/重试状态**，合计 18 个；图上折叠成 5 段：

| 阶段 | 覆盖的状态 | 步骤 |
|---|---|---|
| 1 · 接收与校验 | `DRAFT` → `QUEUED_OFFLINE` / `SYNCING` → `RECEIVED` → `VALIDATED` | 1–2 |
| 2 · 加密与归档 | `PENDING_SIGNATURE` → `PENDING_ARCHIVE` 完成 | 3–7 |
| 3 · 回执 | 状态不变，但 receipt 已签发 | 8–9 |
| 4 · 锚定与最终性 | `PENDING_ANCHOR` → `SUBMITTED_ON_CHAIN` → `INCLUDED` → `FINALISED` | 10–13 |
| 5 · 确认与投影 | `FINALISED` → `CONFIRMED` | 14–16 |

不在主链上的四个去处：

- `REVIEW_REQUIRED`：旁路，事件不签 receipt，等补签或治理例外（图上未画，见流程页）；
- `REJECTED` / `SIGNING_REJECTED` / `EXPIRED`：终止；
- `ARCHIVE_RETRY` / `ANCHOR_RETRY`：停在当前段重试，不跳段。

## 三条读图要点

1. **回执在 `ArchiveAck` 之后、finality 之前（步骤 8–9）。** 这是整个设计的支点：平台在拿到外部持久化确认后就要对参与方负责，但此时还没上链——所以"承诺纳入锚定窗口"不等于"已锚定"。
2. **`CONFIRMED` 只能等 finality（步骤 14）。** 任何超时都不会把事件提升到 `CONFIRMED`；失败就停在当前状态，幂等重试。回执已签发却卡在锚定的事件，正是恢复演练要覆盖的那一类。
3. **归档持有方不解密（步骤 5–7）。** 它只对实际保存的字节签名，因此它的独立性可以按"能否签发 `ArchiveAck`"来验收，而不必信任它的运营水平。

## 生命线对应哪个容器

图上用短名是为了控制宽度，正式名称以 container 图为准：

| 图上 | 对应容器 |
|---|---|
| `Portal / ERP` | Participant Portal / ERP（参与方环境） |
| `Traceability App` | Traceability Application |
| `Operational DB` | Operational PostgreSQL（含 `QueryStore`） |
| `Workers` | Ingestion & Projection Workers |
| `KMS` | Consortium KMS |
| `External Archive` | External Archive（平台控制域之外） |
| `Relayer` | Batch Builder & Relayer |
| `Blockchain` | Public Blockchain |
| `Public CDN` | Public Snapshot Delivery |

## 这个场景没有覆盖的分支

| 分支 | 差别 | 在哪 |
|---|---|---|
| managed / assisted custody | 步骤 2 与 3 之间多一个 `PENDING_SIGNATURE`，等参与方或 provider 批准 | [Identity & Governance](/systems/identity-governance) |
| 离线提交 | 先 `QUEUED_OFFLINE` / `SYNCING`，签名可能已提前完成 | [IoT & Edge](/systems/iot-edge) |
| 官方召回/安全公告 | 拿到自己的 `ArchiveAck` 后即以 `VERIFIED_PENDING_ANCHOR` 发布，不等 finality | [召回与监管调查](/flows/recall-investigation) |
| 撤回、纠错、竞争对手方 | 不改变本流程，作为新的签署事件走同一条写路径 | [Traceability Core](/systems/traceability-core) |
