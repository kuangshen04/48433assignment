# Architecture Report — 待办清单

审查对象：`Agricultural_Supply_Chain_Tracker_5k_Reorganized.md`

审查边界：受 5000 words 限制，不追求字段、机制或流程的全面展开；重点处理范围与背景/rubric 的明确要求。

## 待处理

- [ ] 压缩重复的边界声明。保留首次定义和直接支撑架构决策的说明，减少反复出现的“不裁定物理事实”“不自动判断违法”“不是业务真相来源”等表述。此项属于篇幅优化，不是功能 out of scope。
- [x] 明确 IoT 实时要求的承接（§2.4、§4.5），同步 O7、SQ-11、Context 描述和图。参与方提供临时实时视图；普通遥测尽力传输、短期缓冲，最终 EPCIS 被平台接收后可清理普通原始数据；异常优先提交、有限重试并保留异常窗口证据；监测缺口不视为正常，接收与链上确认分离。不新增遥测平台。
- [x] 同步 IoT Component 图、逻辑与参考部署图、Data dictionary：标明外部 adapter 的摘要/异常输入、参与方缓冲与异常证据保留；定义观测窗口、覆盖率、监测缺口，区分 `admittedAt` 与观测时间/链上确认。扩展复用 canonical payload，不新增云端服务或遥测表。
- [ ] 为 S8–S12 补充简短的 stakeholder interest 与 relevance justification（§1.1；rubric 1.2）。每项用“利益 → 架构影响”说明；可合并没有独立作用的条目。
- [ ] 调整 exclusions 的表达以对应 rubric 1.3（§1.2）。用现有内容明确哪些 plausible stakeholders、risks、constraints 被考虑后排除及其理由，区分“排除出范围”和“保留为残余风险”；无需扩充功能排除列表。
- [ ] 补齐 Glossary 的缩写定义（Appendix A）。核对正文和图中的 EPC、ERP/WMS/TMS、OIDC、ELT、IaaS/PaaS、API、UUID、UOM 等，并展开 SOLID、STRIDE 对应字母。最终排版时核对附录不超过三页。
- [ ] 澄清 Context 图中的 analytics/insights 职责及使用者关系（rubric 4.6）。此项是评分证据呈现风险，不是分析能力完全缺失；无需新增外部 BI 系统或数据仓库。

## 已确认的处理边界

- 非区块链 fallback：老师要求分析，保留，不算 out of scope。
- Contribution Table：留到最后处理，不列入当前修改项。
