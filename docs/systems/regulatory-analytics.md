# Regulatory Analytics

> 主要决策：[B15](/decisions/catalog#b15)、[B17](/decisions/catalog#b17)、[B21](/decisions/catalog#b21)

## 系统定位

Regulatory Analytics 与 Traceability Core 是 peer subsystems。Core 保留可归责的 source assertions；Analytics 在 regulator-controlled environment 中运行启发式规则、统计分析或 optional ML，并把结果用于调查辅助。

它不是 Traceability Core 的内部规则引擎，也不是平台用来自动决定违法、召回或事件有效性的组件。

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
