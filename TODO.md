# Architecture Report — 待办清单

审查对象：`Agricultural_Supply_Chain_Tracker_5k_Reorganized.md`

审查边界：受 5000 words 限制，不追求字段、机制或流程的全面展开；重点处理范围与背景/rubric 的明确要求。

## 待处理

- [x] 精简 §2.1 的额外承诺：删除 WCAG/200% text、固定离线采集次数及 chain replacement 场景；农村可访问性保留低端设备、间歇断网和清晰状态；SQ-13 聚焦产品线/冷链 insights；性能与恢复数值明确为待验证的规划假设。
- [x] 压缩八处重复声明（§0、§2.2、§2.4、§3.2、§4.2、§4.5、§5.2、§5.3）。保留系统定位、具体机制与残余风险，删除重复免责声明和总结；Insights 段落聚焦可视化入口及状态。此项属于篇幅优化，不是功能 out of scope。
- [x] 明确 IoT 实时要求的承接（§2.4、§4.5），同步 O7、SQ-11、Context 描述和图。参与方提供临时实时视图；普通遥测尽力传输、短期缓冲，最终 EPCIS 被平台接收后可清理普通原始数据；异常优先提交、有限重试并保留异常窗口证据；监测缺口不视为正常，接收与链上确认分离。不新增遥测平台。
- [x] 同步 IoT Component 图、逻辑与参考部署图、Data dictionary：标明外部 adapter 的摘要/异常输入、参与方缓冲与异常证据保留；定义观测窗口、覆盖率、监测缺口，区分 `admittedAt` 与观测时间/链上确认。扩展复用 canonical payload，不新增云端服务或遥测表。
- [x] 为 S8–S12 补充 stakeholder interest 与 relevance justification（§1.1；rubric 1.2），用“利益 → 架构影响”说明各方相关性。
- [x] 调整 exclusions 以对应 rubric 1.3（§1.2）：明确首期排除的直接用户、被拒绝的部署约束和参与方证据丢失的恢复保证边界；将 compromised onboarding、密钥失窃、链故障及高级攻击者保留为残余风险。
- [ ] 补齐 Glossary 的缩写定义（Appendix A）。核对正文和图中的 EPC、ERP/WMS/TMS、OIDC、ELT、IaaS/PaaS、API、UUID、UOM 等，并展开 SOLID、STRIDE 对应字母。最终排版时核对附录不超过三页。
- [x] 澄清 Context 图中的 analytics/insights 职责及使用者关系（rubric 4.6）：系统描述明确内置 supply-chain analytics，参与方关系标明产品线/冷链 insights；§3.1 对应已有 Insights module 和 worker projections，不新增外部 BI 系统或数据仓库。

## 已确认的处理边界

- 非区块链 fallback：老师要求分析，保留，不算 out of scope。
- Contribution Table：留到最后处理，不列入当前修改项。
