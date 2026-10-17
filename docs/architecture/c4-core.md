# C4 视图 · Traceability Core

这两张图把 Core 的结构画出来，分别对应报告里的 container 视图（3.2–3.4）与 component 视图（3.5–3.7）。**图内文字用英文**，因为这些图会直接进报告；说明用中文。

图的权威不是这张页面：结构的行为、接口与不变量以系统页为准，本页只负责把形状画对。图源在 `docs/diagrams/src/`，重新生成用 `docs/diagrams/render.ps1`（说明见仓库里的 `docs/diagrams/README.md`）。

## Container 视图

<img src="/diagrams/core-container.svg" alt="C4 container view: platform control domain, regulator control domain and external systems">

读图时注意五处——它们都是决策的落点，不是画法选择：

1. **两个控制域在同一个系统边界内，但不是同一个租户。** `Regulator control domain` 跑在监管方自己的云账户里，平台只交付制品、不持运行时凭据、不能远程推送。这就是 B21 的租户裁定在图上的样子。
2. **`External Archive` 与 `Consortium KMS` 画在平台控制域之外。** 如果它们被画进 `Platform control domain`，B1 就退化成 blockchain theatre——这正是 B1 反误读测试要抓的错误。归档持有者必须是能签发 `ArchiveAck` 的主体，"独立"按三条验收测试判定，不按机构类型判定。
3. **`Operational PostgreSQL` 里包含 `QueryStore`。** 明文副本是有名字、有边界的：可重建、不进恢复包、静态加密、按组织审计读取。不把它画出来，就等于说这套系统没有明文，那是假话。
4. **只有 `Batch Builder & Relayer` 持有链上钱包。** Core 不直接连链，所有上链动作经它提交；因此链故障只让事件停在 `PENDING_ANCHOR`，不影响写入与查询。
5. **跨租户只有两条边。** `DatasetSnapshot` 出去，signed findings 与规则进来；不存在"平台去查 Analytics"的路径。传输认证不等于授权，权威性来自监管方签名。

## Component 视图

<img src="/diagrams/core-component.svg" alt="C4 component view: Traceability Core internals">

同样有五处要点：

1. **只有一条写路径。** `Capture API → Canonicalisation → Signature/Authority → State Machine → Archive & Anchor Orchestrator → Confirmed Event Store`。召回通知、监管评估、纠错声明都不能绕过它——它们必须作为签署事件走同一条路。
2. **`QueryPort` 是唯一读入口，三条不可下放的规则在它这里强制**：scope、non-collapsing、watermark。放到模块里实现，一定有人漏掉。
3. **`Archive & Anchor Orchestrator` 是唯一与 archive / KMS / relayer 打交道的组件。** 门禁集中在一处：拿到 `ArchiveAck` 才签 receipt，达到 finality 才 `CONFIRMED`，任何一侧失败都停在对应状态。
4. **`Evidence Graph Builder` 只由 EPCIS 标准语义生成边**，且推导规则随 `edgeDerivationVersion` 版本化。因此"平台藏了一条边"是事后可举证的——持明文的方可以重算并比对。
5. **`Semantic Modules` 在 Core 之外、但同进程。** 它们只有 `edges()` 一个入口，读不到 canonical 表；这是分层，不是微服务。

## 图里故意没画的东西

| 没画 | 在哪 |
|---|---|
| 部署形态、区域、故障域、恢复路径 | [Operations & Deployment](/systems/operations-deployment)、[平台失效与恢复](/flows/platform-recovery) |
| 数据分类、租户隔离、保留期 | [Data & Access](/systems/data-access) |
| 完整的 18 个提交状态 | [事件接收与确认](/flows/event-acceptance) |
| Analytics 的内部容器与组件 | [Regulatory Analytics](/systems/regulatory-analytics) |
| 类与接口（code 层） | [Traceability Core](/systems/traceability-core) 的组件边界与写入契约 |

一张 container 图塞进部署细节，读者就分不清哪些是逻辑边界、哪些是产品选型——这两件事在本项目里被刻意分开：C1–C3 的产品参数仍在[待定事项](/decisions/open-items)里。
