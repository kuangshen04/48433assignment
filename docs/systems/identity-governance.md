# Identity & Governance

> 主要决策：[B5](/decisions/catalog#b5)、[B11](/decisions/catalog#b11)、[B16](/decisions/catalog#b16)、[B20](/decisions/catalog#b20)、[B24](/decisions/catalog#b24)

## 身份分层

| 层 | 谁管理 | Core 保存什么 |
|---|---|---|
| Human Identity | 企业 IdP 或 managed customer identity | pseudonymous subject 与 organisation/role binding |
| Machine/Device Identity | 参与方或 IoT vendor fleet IAM | integration principal、delegation、scope、credential reference |
| Organisation Identity | Membership Governance | organisation status、public keys、roles、governance history |

平台不复制企业员工目录、密码/MFA lifecycle，也不为每个低成本 sensor 建立平台账户。

## 组织是唯一的身份与访问单元（B24）

平台不以自然人为管理单元。组织承担签名归因、租户边界、KMS epoch 和治理记录，因此一个 `organisationId` 必须同时是这四件事的 key。

**每请求显式绑定组织。** 一个 subject 可以代表多个组织（顾问、集团员工、合作社职员），所以 token 里的 subject 推不出以哪个组织身份行动：

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
- 删除独立 archive 中的历史；
- 把自身审批变成对业务声明真实性的证明。

普通 onboarding 可由独立 authorised membership officer 批准。Regulator role、lost-key recovery、KMS recovery、profile publication、archive-operator change 和 chain migration 使用独立 dual control。

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
| `ASSISTED_EXTERNAL_CUSTODY` | 外部 provider/MPC；参与方批准 | 取决于 provider policy 和独立 authenticator |
| `DELEGATED_PLATFORM_CUSTODY` | 平台可调用 | 保证等级最低；平台理论上可代签 |

三种模式输出相同 `SignatureEnvelope`，但必须保留 `custodyMode` 和 `assuranceLevel`，不能用统一接口抹去信任差异。

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
