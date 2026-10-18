# 产品与运营参数（已关闭）

本页记录 C1–C3 的关闭结果。它们在 Q&A 阶段是待定参数，现在按"公司级项目"的定位定成一套**参考配置**：架构可以依赖，但不是采购承诺，也不声称已达生产 SLA。

还没关掉的架构决策与交付工作见[待办清单](/decisions/backlog)；理由与代价见[完整决策日志](/decisions/log)。

## C1 · Public-chain anchoring

**已定：** Ethereum 主网 + 不可升级的最小合约 + 30 分钟锚定窗口 + 两 epoch finality + KMS 托管的 relayer 签名密钥。

- 合约只存批次元数据（`batchId`、`root`、`prevRoot`、窗口起止、manifest digest）；无 owner、无代理，因此没有可被攻破的治理入口。
- `CONFIRMED` 的判据是 **finalised**（约 12.8 分钟），不是 safe/latest。30 分钟窗口 + 约 13 分钟 finality ≈ 43 分钟，落在 15–60 分钟目标内。
- 空窗口不提交；`oldestPendingAge` 与积压量告警；窗口可延长到 60 分钟上限。
- 迁移：leaf 绑定 `chainId + contractAddress`，换链只换地址与批次元数据，旧 proof 继续可验证。

**仍需实施期确认：** 实测 gas 与真实非空窗口数（估算 A$4–8 万/年）、relayer 运维手册、链拥堵时的窗口策略。

## C2 · PostgreSQL 与应用部署

**已定：** Aurora PostgreSQL，`ap-southeast-2`（Sydney），writer + 1 reader，Multi-AZ；PITR 35 天；每日快照跨区复制到 `ap-southeast-4`（Melbourne）；RDS Proxy；KMS CMK 静态加密。

- reader 专供 export 与召回遍历，避免监管读负载和写入抢同一套存储。
- 故障切换低于 60 秒，是四小时 core RTO 的主要贡献项。
- 分区、图投影、broker 仍按 B22 的触发条件决定，不预设。

**仍需实施期确认：** 实例规格与月度成本实测、load/recovery test 是否证明 RPO/RTO、Aurora 与 RDS 的最终成本对比（RDS 是次选）。

## C3 · 归档与 KMS

**已定：** 归档由**治理配置的合格持有方集合**承担，门禁取集合内任一方对实际保存字节签发的合格 `ArchiveAck`。v1 默认集合：**监管方 mirror（独立账户）+ 至少一个成员 mirror 或商用 WORM**。

- **门禁不绑特定机构。** 绑定监管方会让它的 attestor 维护直接停掉写入，并给它一个隐性的确认否决权。
- **集合至少两项。** 只有一家时门禁可用性等于该家可用性（99.9% ≈ 每月约 43 分钟写入受阻）。
- **持有不等于可读。** 监管方拿到的是密文副本；离线解密需要一次 KEK epoch 授予。
- **资格条件是能力：** 能签 `ArchiveAck`（ECDSA P-256 / Ed25519）；不能提前删除；到期可删并签确认；catalogue 可被非平台方枚举；非公开数据澳境驻留。
- **参考实现（非规定）：** S3 Object Lock compliance 模式 + 受托方 attestor + 受托方账户的多区域 KMS。

**仍需实施期确认：** 持有方集合的现实组成、KMS 产品与密钥策略的具体写法、restore drill 是否满足 B22、是否需要第二 provider 作为附加副本。

## 必须完成的验证场景

这些场景是关闭的验收证据，而不是设计假设：

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
| 监管方 attestor 停摆 | 其他持有方仍可满足门禁，写入不停在 `PENDING_ARCHIVE` |

## 关闭标准（已满足）

最终 deployment view 需要一套可实施的配置，并解释：为什么它符合 B1 的控制权分离、为什么数据驻留与隐私边界成立、每个 RPO/RTO 依赖哪些产品能力与演练、哪些数字是假设而非 SLA、以及更便宜或更简单的替代为什么没被选。这四点现在都能回答，剩余的是实测与采购。
