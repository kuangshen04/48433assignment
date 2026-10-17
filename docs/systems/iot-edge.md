# IoT & Edge

> 相关决策：[A8](/decisions/catalog#a8)、[B12](/decisions/catalog#b12)、[B14](/decisions/catalog#b14)、[B16](/decisions/catalog#b16)

## 两种接入模式

```text
Large participant
  existing IoT platform -> enterprise gateway -> EPCIS submission

Small participant
  platform-assisted device binding / ingestion / private storage
  -> summary generation -> EPCIS submission
```

一体化接入不表示平台取得原始 telemetry 所有权，也不表示 telemetry 自动成为联盟共享数据。平台提供的 private storage 按 B23 是**零知识托管**：平台只有密文，没有解密能力，也不能用它做训练或二次分析。

## 数据分类

| 数据 | 默认分类 | 保存位置 |
|---|---|---|
| 高频 raw readings、完整轨迹 | `PRIVATE` | participant/IoT provider；可选平台托管 |
| Device credential、firmware、运维日志 | `PRIVATE` | participant/IoT provider |
| Raw bundle reference、hash、time range | `CONSORTIUM` | canonical sensor evidence metadata |
| Min/max/mean、excursion duration、source-reported alarm | `CONSORTIUM` | profile-required summary |
| 消费者可理解的声明 | `PUBLIC` | 明确 allowlisted projection |

## 责任链

Device/provider signature 可以说明 bundle 的技术来源，但 canonical EPCIS publication 仍由 organisation 或其注册 gateway/machine actor 承担责任。设备签名、校准和防拆提高 assurance，不能证明设备实际位置或测量的物理真实性。

Product Profile 只定义 required evidence 的字段、单位、结构和引用格式。Traceability Core 按 profile 对比后记录 `evidencePresence`（`PRESENT/MISSING/DELAYED/UNAVAILABLE`，语义见 [Data & Access](/systems/data-access)）；缺失是否构成风险或违规由 Regulatory Analytics 或监管人员判断。

## 离线与农村网络

PWA 或 local gateway 使用 durable offline queue 保存：

- draft 与 client-generated `captureRecordId`；
- payload、profile/vocabulary 和依赖；
- signature 或待签状态；
- retry/sync status。

必须区分：

```text
edge sync lag       device/gateway -> platform reception
processing lag      reception -> archive/operational projection
anchor lag          archive -> public-chain finality
```

`LOCAL_DRAFT/QUEUED_OFFLINE/SYNCING` 不是平台已接受历史，不能生成 acceptance receipt。

## 离线签名限制

- Enterprise self-custody gateway 可以离线签名并排队。
- **`DEVICE_BOUND_SELF_CUSTODY`（组织的设备密钥）在支持的载体上可以离线签名并排队**（B5）。它是组织密钥、私钥不可导出、绑定一条 delegation，不引入自然人身份；代价是只能证明"哪个组织"，不能证明"哪个自然人"。
- **载体能力不足时退回草稿**：iOS 上 WebCrypto 非导出密钥持久化不可靠、passkey 也无法直接签任意 digest，因此不支持该能力的 PWA 仍只能离线保存 draft，联网后重新认证并签署。
- 需要 external approval 或 platform custody 的 PWA event 同样只能离线保存 draft。
- 事件到达时 key 已撤销/过期且没有可信撤销前时间证据，进入 `REVIEW_REQUIRED`。
- 设备时钟和 `eventTime` 不决定全局顺序或撤销有效性。

**不要把它说成"所有小农场都能离线签名"**：能承诺的是"支持的载体上可以，其余是草稿 + 联网补签"，而且离线签名产出的 assurance 档位低于 enterprise self-custody。

## 设备身份边界

IoT vendor/参与方管理 fleet certificate provisioning、rotation、firmware、connectivity 和 calibration。平台只注册 integration principal、organisation delegation、allowed devices/locations/event types 和 credential reference，不成为通用 IoT device-management platform。
