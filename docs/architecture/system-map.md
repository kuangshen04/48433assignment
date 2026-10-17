# 系统地图

## 一句话架构

本系统是跨组织农业供应链追溯层：参与方发布可归责的 EPCIS source assertions；平台负责接收、查询和投影；独立归档、联盟控制的 KMS 与公共链共同限制平台运营者单方面改写或垄断历史的能力；监管分析在独立控制域中判断领域风险。

## 两个有意选择的成立前提

### B1 不是装饰性 threat model

作业明确要求 blockchain，因此架构必须给它一个普通平台数据库不能独立完成的职责。B1 显式假设参与方不完全信任平台对确认后历史的单方控制，使公共链成为外部 existence/integrity checkpoint。若 archive、KMS、recovery identity 和验证结果最终仍全部由平台单独控制，即使使用公链也只是 `blockchain theatre`。

### B17/B21 不是把领域功能移出核心

Traceability Core 不掌握产品、地区和监管制度下的权威领域规则，因此只做 admission/protocol validation。普通领域启发式、统计分析和 optional ML 一起由 regulator-controlled Regulatory Analytics 管理；监管方可授权一部分基础 rule findings 给平台用于提醒。它是平台整体的一等核心业务子系统，只是不是 canonical write path 的同步依赖。

## 控制域与系统

```text
Participant Environment
  PWA / ERP / WMS / TMS / IoT Platform / Enterprise Gateway
                      |
                      | signed EPCIS submissions / evidence references
                      v
Shared SaaS Application Plane
  Traceability Core -- Operational PostgreSQL -- Projections
       |          |                  |                 |
       |          |                  |                 +--> Public CDN / Consumer UI
       |          |                  +--------------------> Regulator Portal / Exports
       |          +---------------------------------------> Regulatory Analytics Projection
       |
       +--> Independent WORM Archive <--> Consortium-controlled KMS
       |
       +--> Merkle Batch / Relayer --> External Public Blockchain

Regulator-controlled Environment
  Regulatory Analytics / optional ML --> signed AdvisoryFinding
```

## 系统职责总表

| 系统或控制域 | 主要职责 | 明确不负责 |
|---|---|---|
| Participant Environment | 产生业务声明、企业签名、离线排队、私有证据保存 | 全网查询、公共链 finality |
| Traceability Core | EPCIS 接收、结构验证、幂等、生命周期、handover 和 lineage projection | 判断物理事实真假、库存核算、违法结论 |
| Identity & Governance | 组织资格、public key、delegation、profile/高权限变更历史 | 企业员工目录、设备 fleet IAM、替参与方签名 |
| Operational PostgreSQL | 热查询、状态机、outbox、可重建投影 | 作为唯一权威历史或唯一恢复副本 |
| Independent Archive | 保存可验证的 encrypted archive envelope 并签发 ArchiveAck | 解密业务数据、判断内容真实性 |
| Consortium KMS | 保护 consortium KEK，向获授权 runtime/recovery identity 提供密码操作 | 参与业务审批或替组织签名 |
| Public Blockchain | 保存 Merkle commitment，提供外部 existence/integrity checkpoint | 保存完整 EPCIS、证明 eventTime 或物理事实 |
| Regulatory Analytics | 运行启发式、统计或可选 ML，输出私有 finding 或获准 advisory | 改写 trace、继承监管人员全部权限、自动执法 |
| Public Delivery Plane | 发布版本化消费者 projection，使用 CDN 承担高并发 | 直接读取 archive/KMS 或展示联盟私有数据 |

## 核心信任边界

### 平台运营者不是完全可信方

架构主要限制平台对完整性、可恢复性、密钥控制和接受后审查的单方权力。这个边界是题设所要求 blockchain 的实际用途，而不是泛化地声称“区块链更安全”。平台 runtime 仍然被授权读取 `CONSORTIUM` 明文，因此当前模型不声称在 runtime 被攻破时仍能保持联盟数据机密性。

### 组织声明不等于物理事实

签名、ArchiveAck 和公共链 finality 可以证明“谁发布了什么、保存了什么、之后是否被替换”，不能证明货物真的存在、传感器真的安装在声明位置，或参与方没有串谋。

### Regulatory Analytics 是 peer subsystem

Traceability Core 保存可归责的 source assertions；Regulatory Analytics 维护监管方拥有的 deterministic heuristics、statistics 和 optional ML，并解释领域风险。监管方可以授权指定 rule/version 的 signed findings 给平台形成基础提醒。关闭 Analytics 不应阻止追溯写入、查询、召回遍历或监管人员手工调查，但必须显式显示分析结果过期或不可用；这种故障隔离不降低它作为核心业务子系统的地位。

## 主要数据类别

| 数据类别 | 默认位置 | 默认访问 |
|---|---|---|
| Canonical EPCIS trace | 加密独立归档；PostgreSQL 索引/投影 | `CONSORTIUM` |
| Consumer projection | 版本化对象/CDN | `PUBLIC` |
| Raw IoT、报告、合同等证据 | 参与方或可选平台托管 ProtectedResource | `PRIVATE` |
| Membership/profile/key history | 独立归档并锚定；数据库 current projection | 受治理访问 |
| Analytics dataset/findings | regulator-controlled environment | 目的受限；默认 regulator-private |
| Public-chain commitment | 外部公共链 | 公开，但不得含可字典匹配的个人字段 |

## 继续阅读

- 核心写模型：[Traceability Core](/systems/traceability-core)
- 信任保证：[Trust & Recovery](/systems/trust-recovery)
- 端到端确认：[事件接收与确认](/flows/event-acceptance)
- 决策归属：[系统—决策矩阵](/decisions/system-matrix)
