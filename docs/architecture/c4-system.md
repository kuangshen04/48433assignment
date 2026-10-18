# C4 视图 · 上下文与部署

这两组图是"系统级"的：context 说明系统边界与外部依赖，deployment 说明这些东西实际跑在谁的账户里。图内英文，说明中文。

职责与不变量的权威仍在系统页；本页只解释图。

## System context

<img src="/diagrams/c4-context.svg" alt="C4 system context: users, external systems and the traceability system">

四句话：

1. **黑框里只有一个系统。** 参与方的 ERP/WMS、监管方的规则引擎、外部归档与 KMS 都在框外——它们各自的职责与失败语义见对应系统页。
2. **IoT 设备不直接连平台。** 传感器、秤、扫码枪先进参与方的业务系统或网关，再由业务系统发布 EPCIS 事件。这条决定了平台不做设备管理，也决定了原始遥测留在参与方一侧。
3. **身份有两条独立的线。** 人员认证来自外部 IdP（`OIDC`）；组织的法律身份在 onboarding 时经企业登记库核验。前者管"谁在操作"，后者管"这个组织是否存在"。
4. **三个外部依赖承担"平台之外的证明"**：外部归档签 `ArchiveAck`、联盟 KMS 持有密钥、公链保存 Merkle 根。它们被画在边界之外，正因为其价值来自"不在平台的账户里"。

## Deployment（逻辑）

<img src="/diagrams/c4-deployment.svg" alt="C4 logical deployment: accounts, regions and placement of containers">

这张图只表达**归属与位置**，不写产品名：

1. **四个控制域，五个账户。** 平台账户、受托方账户、监管方的 analytics 账户与 evidence 账户各自独立；公链是外部基础设施。把四个域合进一个账户，前面所有证明都会退化成平台自证。
2. **监管方有两份资产、两个账户。** 规则与 finding 在 analytics 账户；归档 mirror 在 evidence 账户。后者是 C3 的默认持有方之一——但它持有的是**密文副本**，不等于能读。
3. **单区域起步，副本跨故障域。** 应用与数据库在一个 Australian region；归档与 KMS 在受托方账户、跨故障域保存。
4. **钱包只有一个进程持有。** `Batch Builder & Relayer` 是唯一接触链上私钥的组件，单独部署。

## Reference deployment（产品级）

<img src="/diagrams/c4-reference-deployment.svg" alt="C4 reference deployment: an implementable configuration with products">

这张图把逻辑部署落到一套**可实施的配置**上（C1–C3）：

| 层 | 选型 | 关键约束 |
|---|---|---|
| 应用运行时 | ECS Fargate（application 与 workers 为同一镜像的两种角色） | 无自管集群 |
| 数据库 | Aurora PostgreSQL，Sydney，writer + 1 reader | PITR 35 天；快照跨区复制到 Melbourne；RDS Proxy |
| 公链 | Ethereum 主网 + 不可升级的最小合约 | 30 分钟窗口、两 epoch finality |
| 归档 | 持有方集合；默认监管方 mirror + 受托方 mirror | 参考实现：S3 Object Lock compliance；门禁取集合内任一方 `ArchiveAck` |
| 密钥 | 受托方账户的多区域 KMS | 平台只有 wrap/unwrap |
| 公开分发 | S3 + CloudFront | 版本化快照；召回可强制回源 |

**产品名是参考实现，不是架构依赖。** 需要被架构保证的是控制域归属、区域驻留、失败语义与证明格式——这几项换供应商不会变。监管方 analytics 账户甚至可以不在同一家云上：两条跨租户接口都是签名消息，没有共享网络。

## 两张部署图为什么都留着

- **逻辑部署**回答"谁拥有什么、东西放在哪个控制域"，它不应该因为换了一家托管服务就重画。
- **Reference deployment**回答"第一版具体怎么搭"，它必须能指向可采购的产品，否则 4.14–4.15 没有内容。

评审时可以这样用：先看逻辑图确认边界，再看参考图确认可实施性。两张图共用同一套节点命名，所以不会互相矛盾。

## 还没定的

成本实测（Aurora 规格、gas 与窗口数）、恢复演练是否满足 B22 的 RPO/RTO、以及持有方集合的现实组成。这些是实施期确认项，不是架构缺口。
