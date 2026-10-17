# Identity & Governance

> 主要决策：[B5](/decisions/catalog#b5)、[B11](/decisions/catalog#b11)、[B16](/decisions/catalog#b16)、[B20](/decisions/catalog#b20)

## 身份分层

| 层 | 谁管理 | Core 保存什么 |
|---|---|---|
| Human Identity | 企业 IdP 或 managed customer identity | pseudonymous subject 与 organisation/role binding |
| Machine/Device Identity | 参与方或 IoT vendor fleet IAM | integration principal、delegation、scope、credential reference |
| Organisation Identity | Membership Governance | organisation status、public keys、roles、governance history |

平台不复制企业员工目录、密码/MFA lifecycle，也不为每个低成本 sensor 建立平台账户。

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
