# Operations & Deployment

> 相关决策：[A7](/decisions/catalog#a7)、[B7–B8](/decisions/catalog#b7)、[B10](/decisions/catalog#b10)、[B12–B13](/decisions/catalog#b12)、[B20](/decisions/catalog#b20)、[B22](/decisions/catalog#b22)、[C1–C3](/decisions/open-items)

## 第一版部署形态

```text
Australian primary region
  stateless application instances
  managed PostgreSQL
  ingestion / projection / export workers
  object snapshots and public origin
  Insights warehouse / mart

Australian control domains outside the platform account
  external archive replica + cross-failure-domain recovery copy
  consortium/trustee-controlled KMS and recovery identity

External/global
  public blockchain
  public CDN

Regulator tenancy (separate cloud account)
  Regulatory Analytics Workspace
  Rule Registry (含规则正文) + Finding Store
```

第一版采用模块化单体。应用职责可以按 command、worker 和 query 逻辑隔离，但不预先部署完整微服务、broker、event store、graph database 和独立 read database。

## 租户划分与"运维"的判据

| 层面 | 归属 | 说明 |
|---|---|---|
| 账户 / 租户 | 平台账户 ≠ 监管方账户 | billing、IAM root、网络边界分开 |
| 控制平面 | 各自租户内 | 谁能部署、缩容、回滚 |
| 数据密钥 | 监管方 KMS 保 rule/finding；联盟/受托方 KMS 保 consortium KEK | 平台无监管方 finding 的解密权限 |
| 制品来源 | 平台构建，监管方审核后在自己租户上线 | **平台不能远程推送**，否则又变回代运维 |

**判据不是"能不能登录数据库"，而是"谁掌握控制平面"。** 掌握控制平面的人至少有三条路径拿到明文：dump 进程内存、直接读宿主存储、替换镜像。因此"和平台同集群、只是没有 DB key"不构成隔离，Analytics 必须整体运行在监管方账户里。

**为什么整个 Analytics 一起搬**：拆分（runner 在平台、registry 在监管方）行不通——runner 执行规则必须读规则正文，那 B21 里"只锚定 digest、正文不外泄"就失效了。

**想要"一个集群"的动机可以不靠共享租户满足**：第一版用的是托管容器服务而非自管 K8s（A7/B10），两边都是托管、都不需要运维节点，只是账户不同。

跨租户只有三条流，契约见 [Regulatory Analytics](/systems/regulatory-analytics)。

## Workload assumptions

| 指标 | NSW pilot 假设 |
|---|---:|
| 初始组织 / 设计增长 | 200 / 1,000 |
| 内部用户 | 2,000 |
| 平均 canonical events | 10,000/day |
| Offline recovery burst | 50 events/s for 15 min |
| Consumer CDN peak | 5,000 requests/s |
| Origin peak after cache | ~250 requests/s |
| Max synchronous lineage | 10,000 edges |
| Large export | 1,000,000 events/job |
| Normal projection lag | <= 30 sec |
| Safety stale threshold | 5 min |
| Rural offline window | up to 72 h |

这些是待 load/failure/usability testing 验证的架构假设，不是客户事实或生产 SLA。

## 故障语义

| 故障 | 写入行为 | 读取行为 |
|---|---|---|
| Signing provider | `PENDING_SIGNATURE` | confirmed data 不受影响 |
| KMS/all archives | `PENDING_ARCHIVE`；不签 receipt | public/materialised view 可继续；即时解密不可用 |
| Public chain/relayer | `PENDING_ANCHOR`；不确认 | confirmed data 继续；official notice 可走 fast path |
| Projection worker | canonical state 不回滚 | affected projection 标记 stale |
| Analytics | trace 继续 | risk assessment 标记 delayed/unavailable |
| PostgreSQL/platform | participant queue 重试 | CDN snapshot 继续；完整 trace 走 recovery |

所有外部副作用使用稳定 identifiers，并在重试前检查既有 archive object、leaf allocation 和 transaction intent，避免重复执行。

## 扩展顺序

1. query/index tuning、connection pooling、vertical scaling；
2. CDN/cache 与 workload quotas；
3. read replica 或专用 export projection；
4. time/organisation partitioning；
5. outbox worker 横向扩展，再评估 broker；
6. 只有图查询成为常态时才评估 graph/read store。

## 恢复目标

- Receipted/confirmed canonical trace logical RPO：0 target，依赖 restore drill；
- PostgreSQL operational RPO：不超过 5 分钟；
- Core platform RTO：不超过 4 小时；
- Full Australian regional rebuild：不超过 24 小时。

Core RTO 优先恢复 ingestion、trace query 和 regulatory access；大型 export 与 analytics 可以后恢复。

## 最终报告仍需选定

决策阶段保留产品选型待定是合理的，但 deployment view 必须给出一套可实施 reference deployment，包括 public network、anchor window、Australian cloud/region、managed PostgreSQL、外部归档产品、KMS ownership/recovery、relayer wallet 和恢复验证路径。详见[待定事项](/decisions/open-items)。
