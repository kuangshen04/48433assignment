# Regulatory Analytics

> 主要决策：[B15](/decisions/catalog#b15)、[B17](/decisions/catalog#b17)、[B21](/decisions/catalog#b21)

## 系统定位

Regulatory Analytics 与 Traceability Core 是 peer core subsystems。Core 保留可归责的 source assertions；Analytics 在 regulator-controlled environment 中运行普通领域启发式规则、统计分析或 optional ML，并把结果用于风险筛查、平台基础提醒和监管调查。

它不是只供监管人员“查东西”的附加报表工具，也不是 Traceability Core 的内部规则引擎。平台运营者不知道不同产品、地区和监管制度下的权威领域规则，因此 deterministic heuristics 与高级分析统一由监管方配置、版本化和审计。这里 optional 的是 ML 技术，而不是 Regulatory Analytics 这一核心业务能力。

它也不是平台用来自动决定违法、召回或事件有效性的组件：规则执行结果必须保留来源、版本、watermark 和保证等级，正式监管结论仍需 authorised officer 签署。

## 身份与权限分离

| 能力 | Regulator officer | Analytics service |
|---|---|---|
| 读取 confirmed consortium trace | 通过 regulator role | 只读 purpose-minimised projection |
| 读取完整 archive | 必要时经授权路径 | 无直接 KMS/archive 权限 |
| 访问 private evidence | 具体案件和记录的法律/治理依据 | 日常筛查不允许 |
| 发出 evidence request/行使权力 | 可以 | 不可以 |
| 产生风险提示 | 可以 | 可以，默认 regulator-private |
| 签署正式 Assessment/Inspection | authorised officer | 不可以 |
| 自动改变 event/handover/recall | 不可以原地修改 | 不可以 |

## 输入投影

```text
CONFIRMED consortium assertions at watermark W
  -> field- and purpose-minimised dataset
  -> dataset/schema version + recipient + expiry + audit ID
  -> Regulatory Analytics
```

可包含 event relationships、handover claims、sensor summaries、evidence status、correction history 和必要 organisation/location identifiers。不得包含 raw telemetry、完整文件、credentials 或 signing material，也不能根据 reference 自动追取 ProtectedResource。

第一版不分析 pending assertions；其 freshness SLO 明确包含普通事件等待 public-chain finality 的时间。

## 输出与披露

```text
private RiskAlert
  -> regulator review
  -> optional evidence request / investigation
  -> formal human-signed Assessment, Recall or Safety Notice

approved rule/finding
  -> signed AdvisoryFinding
  -> Platform Advisory Ingestion
  -> permitted participant reminder
```

`AdvisoryFinding` 至少绑定 issuer、rule/version、affected references、severity/reason codes、data watermark、generated/expiry time、disclosure scope 和 regulator signature。它不进入 canonical trace，不改变 event validity，也不自动成为 recall。

### 基础规则如何授权给平台

监管方可以把部分基础 `ruleId/ruleVersion` 的输出标为 `SUBJECT_ORGANISATION` 或 `CONSORTIUM_ADVISORY`。第一版仍由规则在 regulator-controlled environment 中运行，再向平台返回 signed `AdvisoryFinding`；平台据此生成基础提醒，但不能修改规则、重新解释 severity 或扩大 audience。

这实现了“监管方把基础规则能力授权给平台使用”，同时避免平台维护一套未经授权的领域规则副本。未来若低延迟确实要求平台本地执行，可以单独设计 signed declarative rule package 与 sandbox；它不能悄悄进入 Core write validation。

## 披露范围

- `REGULATOR_ONLY`：监管人员内部使用；
- `SUBJECT_ORGANISATION`：只通知涉及组织；
- `CONSORTIUM_ADVISORY`：只面向明确获准的联盟 audience；
- `PUBLIC`：自动 analytics output 不允许，必须独立人工签署发布。

行业协会当前不是 Regulatory Advisory issuer。它可以通过联盟治理提出 Product Profile、vocabulary 或行业指导；若未来允许其直接发出提示，需要与监管 advisory 分开的 authority type、适用范围和 UI 语义。

## Freshness 与故障

Analytics 对外发布：

```text
analysisInputWatermark
lastSuccessfulEvaluationAt
activeRuleSetVersion
analysisHealth = CURRENT | DELAYED | UNAVAILABLE
```

Analytics 故障时，trace ingestion/query、recall traversal 和人工调查继续运行。UI 必须显示 `Risk assessment delayed/unavailable`；“没有当前 finding”只能表示对已成功评估到的 watermark 未产生提示，不能解释为没有食品安全风险。
