# Identity & Governance

> 相关决策：[B5](/decisions/catalog#b5)、[B11](/decisions/catalog#b11)、[B16](/decisions/catalog#b16)、[B20](/decisions/catalog#b20)、[B24](/decisions/catalog#b24)

## 身份分层

| 层 | 谁管理 | Core 保存什么 |
|---|---|---|
| Human Identity | 企业 IdP 或 managed customer identity | **仅可变层的 delegation**（subject → organisation + scope）；canonical trace 不含任何自然人引用 |
| Machine/Device Identity | 参与方或 IoT vendor fleet IAM | integration principal、delegation、scope、credential reference |
| Organisation Identity | Membership Governance | organisation status、public keys、roles、governance history |

平台不复制企业员工目录、密码/MFA lifecycle，也不为每个低成本 sensor 建立平台账户。

**`actorId` 不进入 immutable 历史**（B5）：canonical event 只记录 signer organisation、`keyId`、`custodyMode` 与 `assuranceLevel`。"谁在何时操作"留在可变的 operational audit，可被组织自己的 IdP 日志印证；组织内部追责由组织负责（B24）。

## 组织是唯一的身份与访问单元（B24）

平台不以自然人为管理单元。组织承担签名归因、租户边界、KMS epoch 和治理记录，因此一个 `organisationId` 必须同时是这四件事的 key。

### 核心侧最小模型

```text
Organisation Registry      组织身份、类型、membership 状态
Organisation Key Registry  签名/加密公钥、用途（SIGNING | ENCRYPTION）、有效期、撤销状态
Delegation Registry        subjectOrIntegrationPrincipal → organisation + allowedScopes + 有效期
Governance Record History  membership/key/delegation 变更的签署历史
```

角色只保留少量固定值（OrgAdmin、EventPublisher、EvidenceManager、Viewer）用于划分权限范围；**不建模组织内部组织架构**。`ENCRYPTION` 用途的密钥供 [B23](/decisions/catalog#b23) 的内容加密接收方使用。

### 每请求显式绑定组织

一个 subject 可以代表多个组织（顾问、集团员工、合作社职员），所以 token 里的 subject 推不出以哪个组织身份行动：

```text
authenticated subject       由外部 IdP 断言
+ explicit actingOrganisationId
+ operation scope
-> Delegation Registry 校验
-> 决定归因、可见范围与 KMS epoch
```

缺少显式绑定时拒绝请求，**不能默认取第一个组织或最近使用的组织**——那会让归因取决于会话历史。

**明确不管的部分：**

| 不归平台管 | 归谁 |
|---|---|
| 员工名册、入离职、岗位、汇报线 | 组织自己的 HR/IAM |
| 组织内部审批链、双人复核 | 组织自己的流程；平台只验证最终签名 |
| 密码、MFA、会话 | 外部 IdP |
| 合作社与成员农场、集团与子公司 | 商业安排：注册成多个 `organisationId` + delegation |
| 多站点企业的站点结构 | 同上；站点写成不同 `bizLocation`，仍属同一 organisation |

平台可以提供很简易的用户界面，但那是 delegation 注册表的编辑器，不是权威用户目录。

**组织层级 out of scope。** 不建 `parentOrganisationId`：层级一旦存在，`CONSORTIUM` 可见范围、scope 计算、KMS epoch 和签名归因都要沿层级继承，复杂度立刻上升；而农业场景的层级形态（合作社、集团、代工、代销）差异太大，无法给出通用语义。若出现"父组织代为提交"的需求，先看 delegation 是否够用。

## Membership Governance 的有限权力

Membership Governance 可以验证现实组织资格、批准角色和发布治理记录，但不能：

- 代表 self-custody 组织签署业务事件；
- 修改已 finalise 的 public-chain commitment；
- 删除外部归档中的历史；
- 把自身审批变成对业务声明真实性的证明。

普通 onboarding 可由独立 authorised membership officer 批准。Regulator role、lost-key recovery、KMS recovery、profile publication、外部归档持有者/账户变更 和 chain migration 使用独立 dual control。

## Governance effective gate

```text
PROPOSED
  -> APPROVED_AND_SIGNED
  -> ARCHIVED
  -> ANCHORED_AND_FINALISED
  -> EFFECTIVE
```

依赖新 identity、key 或 profile 的业务事件，在治理记录生效前不能获得 receipt/confirmation。Emergency suspension/revocation 可以 fail closed 立即阻止新操作，并以 `EMERGENCY_PENDING_ANCHOR` 留下待补外部证明的状态。

## 签名 custody 模式

| 模式 | 私钥控制 | 主要保证 |
|---|---|---|
| `ENTERPRISE_SELF_CUSTODY` | 参与组织 | 平台不能单独冒充组织 |
| `DEVICE_BOUND_SELF_CUSTODY` | 组织拥有、私钥留在设备上不可导出 | 同为 self-custody，但只证明"哪个组织"，不证明"哪个自然人"；按载体可用 |
| `ASSISTED_EXTERNAL_CUSTODY` | 外部 provider/MPC；参与方批准 | 取决于 provider policy 和独立 authenticator |
| `DELEGATED_PLATFORM_CUSTODY` | 平台可调用 | 保证等级最低；平台理论上可代签 |

四种模式输出相同 `SignatureEnvelope`，但必须保留 `custodyMode` 和 `assuranceLevel`，不能用统一接口抹去信任差异。

**设备密钥的注册方式：** 它是 `Organisation Key Registry` 下的一条组织密钥，`owner = organisation`，并绑定一条 Delegation 限定可发布的 scope 与事件类型。因此"小农场用手机离线自签"在语义上是**组织用设备密钥签名**——归因仍是组织，canonical trace 不出现自然人。离线时不存在"该以哪个组织身份签"的歧义，因为一把设备密钥只绑一个组织。

**载体是硬边界：** iOS 上 WebCrypto 非导出密钥持久化不可靠、passkey 也无法直接签任意 digest，因此该档位只在能可靠持有密钥的载体（原生 App 或支持的 PWA）上提供；其余载体退回 draft + 联网补签。不要承诺"所有小农场都能离线签名"。

## 离线签名与撤销

`eventTime`、`assertedSignedAt` 和 `captureRecordId` 都不是可信签署时间。验证被拆为：

1. cryptographic authenticity；
2. acceptance-time organisation/key authority；
3. trusted signing-time evidence。

如果 key 在平台接收前已经撤销或过期：

- 有绑定相同 digest/key/signer 的可信撤销前时间证据：进入受治理的 late/offline path；
- 只有参与方声明的时间：进入 `REVIEW_REQUIRED`，不能自动确认。

可信证据可以是 signing-provider receipt、撤销前的 challenge receipt，或已归档/锚定的 enterprise-gateway queue checkpoint。已经确认的旧事件不会因后来发现 key compromise 而自动失效。

## 退出与历史验证

`SUSPENDED/EXITED/REVOKED` 组织不能发布新事件或获得新 KEK epoch，但旧 membership、public keys 和 signed events 必须保留到最后一个依赖 payload 的 retention 到期。已经下载的 plaintext 无法通过撤回密钥收回。
