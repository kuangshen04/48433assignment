# Query & Experience

> 主要决策：[B9–B10](/decisions/catalog#b9)、[B12–B13](/decisions/catalog#b12)、[B18–B19](/decisions/catalog#b18)、[B21](/decisions/catalog#b21)

## 三个读取平面

| 平面 | 负载形态 | 读取策略 |
|---|---|---|
| Consumer | 高频、小响应、活动时突发 | versioned public snapshots + CDN |
| Participant | 中低频、按自身业务对象查询 | operational projections + bounded lineage |
| Regulator/Investigation | 低并发、可能一次读取大量历史 | bounded sync query + async export |

三者可以来自同一模块化应用的数据，但不能共享相同在线查询路径和资源池。

## Consumer 体验

QR 只是 resolver，不是防伪证明。消费者看到的是明确 allowlisted 的 `PUBLIC` projection，例如产品说明、公开来源摘要和 signed recall status；不会直接访问 PostgreSQL、archive、KMS 或完整 consortium trace。

Consumer UI 必须区分：

- confirmed trace；
- `VERIFIED_PENDING_ANCHOR` official safety notice；
- stale public snapshot；
- 无数据、未知和已明确无相关记录。

平台不因为多个地点扫描同一 QR 就自动认定 counterfeit。Duplicate/impossible-scan pattern 可以成为 regulator-private analytics signal。

## Lineage 与 Recall 查询

Recall 是对共享 consortium lineage 的保守、可复现遍历，不是实际下架执行：

- transformation：input 到所有 claimed outputs；
- aggregation：child 与时间适用的 parent/container；
- handover：对象到所有 claimed destination/custodian；
- disputed、partial、unacknowledged 和 external edges 都保留 provenance。

视图必须 non-collapsing：同一对象的竞争断言并存显示，不排序、不打分、不选代表路径。任何“受影响 / 未受影响”的结论都要能追溯回它依赖的断言集合与 watermark；依赖集合含竞争边时必须显示该竞争关系。折叠成单一路径等于用界面替平台裁决了真伪。

结果语义是 `possibly affected based on available claims`，不是污染或责任结论。超过同步 10,000 edges 或接近响应限制时转为固定 watermark 的异步 export。

## Freshness 契约

每个 projection 显示：

```text
dataCompleteThrough
projectionLag
health
source assurance/finality status
```

Recall/food-safety 查询超过安全阈值时必须等待追平、回查 eligible confirmed source index，或返回 `STALE/INCOMPLETE`。不能把 projection 缺失解释为没有风险。

Analytics freshness 与 trace freshness 分开：trace 当前不表示规则已经运行；Analytics health 不当前时，UI 单独显示风险评估延迟。

## Official Safety Notice fast path

授权监管方或 responsible organisation 签署的 Recall/Safety Notice，在获得 independent ArchiveAck 后可以立即以 `VERIFIED_PENDING_ANCHOR` 发布，不等待 15–60 分钟的普通 anchor/finality。

该例外不适用于普通 event、ML finding 或 preliminary advisory。UI 必须显示 issuer、issuedAt、archive verification 和 pending-anchor 状态，并在链恢复后补齐 finality。
