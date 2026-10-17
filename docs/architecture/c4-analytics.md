# C4 视图 · Regulatory Analytics

这三张图兑现 B21 规定的 C4 义务（container / component / code 三层都要有），粒度按**边界自洽**取——够说清规则从哪来、finding 到哪去、什么跨出监管域，不追求内部完备。图内英文，说明中文。

完整职责、权限矩阵与扩展条件见 [Regulatory Analytics](/systems/regulatory-analytics)；本页只解释图。

## Container 视图

<img src="/diagrams/analytics-container.svg" alt="C4 container view: regulatory analytics containers inside the regulator control domain">

三句话读完：

1. **三个容器全部在监管方账户里**，平台侧只出现两个端点的名字（`Traceability Application` 出数据、`Ingestion & Projection Workers` 收消息）。平台不持这套运行时的凭据，也不能远程推送——这是 B21 租户裁定的直接后果。
2. **`Rule & Model Registry` 存规则正文**，`DatasetSnapshot` 从不带规则；平台也永远看不到正文，只看到后面的 `RuleVersionManifest`。
3. **`Finding & Advisory Store` 是 regulator-private**。finding 默认不出这个域；只有经 disclosure policy 允许的那部分才变成 signed advisory 发出去。

## Component 视图

<img src="/diagrams/analytics-component.svg" alt="C4 component view: Analytics Workspace internals">

1. **`Dataset Intake` 是唯一入口**：校验 schema/version、调用方 service identity、watermark、purpose 与 expiry。少校验一项，后面所有 finding 的"可复现"就无从谈起。
2. **`Rule Loader & Validator` 校验的是监管方签名与适用范围**，不是"规则内容合不合理"——规则由监管方负责，运行时只负责确认"这就是那条已生效的规则"。
3. **`Screening Runner` 在一个不可变 snapshot、一个固定 watermark 上跑 deterministic rules**；首版不含 ML，所以这里没有模型加载器。
4. **`Advisory Publisher` 做三件事**：套 `DisclosurePolicy`、签名、路由回平台 ingestion。它不能扩大 audience，也不能改 severity。

## Code 视图

<img src="/diagrams/analytics-code.svg" alt="C4 code view: major classes of Regulatory Analytics">

8 个类，三个要点：

1. **`RuleVersionManifest` 是唯一离开监管域的产物**，而且只带 `ruleBodyDigest`。平台归档并锚定它，于是"当时依据哪条规则"可事后验证，而"哪里会被查"不外泄。
2. **`Finding` 与 `AdvisoryFinding` 共用 `findingId`**：advisory 不是新对象，是同一个 finding 的披露形态。因此撤回就是同 `findingId` 重签并标 `status: RETRACTED`——追加，不覆盖。
3. **`DisclosurePolicy` 约束的是 advisory，不是 finding。** finding 默认 regulator-private，不需要策略；策略只在"要不要让外面看见"这一步起作用。

## 图里故意没画的

| 没画 | 为什么 |
|---|---|
| 模型训练管线、drift 监控、human review 队列 | 首版明确不做；扩展条件写在 [系统页](/systems/regulatory-analytics) 末节 |
| `RegulationRequirement` | 它是**监管方发给平台**的产物，落在平台侧，不属于本子系统的类模型；约束见 [B21](/decisions/catalog#b21) |
| 平台侧的 finding 消费、advisory store、UI | 属于平台域，见 [C4 视图 · Core](/architecture/c4-core) |
| `ModelVersion`、`ReviewDecision` | 扩展后才新增的类，同样在系统页的"扩展时才出现"表里 |
