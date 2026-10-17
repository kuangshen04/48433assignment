# 待定事项

本页只管 C1–C3 这类「逻辑边界已定、只差产品参数」的关闭项。**还没做出的架构决策与交付工作见[待办清单](/decisions/backlog)。**

现有架构不需要大规模重构。剩余工作主要是把已确定的逻辑边界落实为一套可验证的 reference deployment，而不是继续增加抽象决策。

## C1 · Public-chain anchoring

已确定：

- canonical payload 不上链；
- deterministic Merkle batching；
- 平台 relayer；
- leaf 绑定 event、signature 与 ArchiveAck；
- 普通目标确认时间为 15–60 分钟范围；
- 首版没有 secondary relayer。

提交前需要选择：

- 具体 public network 与 finality rule；
- 固定 anchor window；
- commitment contract 是否 immutable/upgradeable；
- relayer wallet、gas funding、nonce/retry；
- chain outage 与 migration continuity；
- 如何长期验证旧链 proofs。

## C2 · PostgreSQL 与应用部署

已确定：

- Australian primary region，优先 NSW/Sydney；
- managed PostgreSQL；
- 模块化单体、transactional outbox；
- operational RPO <= 5m、core RTO <= 4h；
- scaling triggers 而不是预先多数据库。

提交前需要选择：

- cloud provider、region 和 managed PostgreSQL tier；
- Multi-AZ、PITR、backup retention、encryption 和 connection pooling；
- application/workers/public origin 的 execution environment；
- read replica 是否进入 reference deployment；
- load/recovery test 如何证明 B22 数量假设；
- 估算成本及低成本替代方案。

## C3 · Independent Archive 与 KMS

已确定：

- mandatory WORM archive 在平台控制域之外；
- 至少跨 Australian failure domain；
- Consortium KMS account/policy/recovery authority 不归平台单独控制；
- Recovery Client 不依赖平台 IAM、DNS、数据库；
- logical RPO=0 需 restore drill 证明。

提交前需要选择：

- archive operator/product 和 account owner；
- WORM/object-lock mode、retention、catalogue/export API；
- recovery replica/failure domains；
- KMS product、KEK ownership、key deletion protection 和 emergency recovery；
- 是否需要第二 provider escrow 或 threshold recovery；
- Participant Gateway 是否为首版 deliverable。

## 必须完成的验证场景

| 场景 | 需要证明 |
|---|---|
| 参与方离线 48 小时，期间 key 被撤销 | `eventTime` 不能绕过撤销；可信时间证据和 review path 有效 |
| ArchiveAck/receipt 后数据库完全丢失 | 能恢复未锚定 intent 并继续 anchoring，不重复 receipt/leaf |
| Archive ciphertext 被替换 | Envelope/Ack/digest/Merkle 验证链能检测 |
| Analytics 停止两小时 | Trace 继续，UI 明确显示 risk assessment unavailable |
| 冲突 Transformation claims | Core 保留双方，Analytics 可独立提示风险 |
| Recall 时 public chain 不可用 | Official notice 快速发布但不伪装为 confirmed event |
| 成员只持有自身 scope（B3） | 能验证日志连续性与自己记录的 inclusion；不能重建完整历史，且把不可见节点显示为不可见而不是不存在 |
| 成员加入后要访问加入前历史 | 默认不自动获得旧 epoch；历史访问走显式治理授予并可审计 |
| Australian primary region 故障 | Archive catalogue、KMS recovery 与 core service 满足目标恢复路径 |

## 最终报告的关闭标准

最终 C4 deployment diagram 和 XaaS rationale 必须选定一套实际 reference configuration，并解释：

1. 为什么它符合 B1 的控制权分离；
2. 为什么数据驻留和 privacy 边界成立；
3. 每个 RPO/RTO 依赖哪些产品能力和演练；
4. 哪些数字是设计假设而不是已证明 SLA；
5. 更便宜或更简单的替代方案为什么没有被选择。
