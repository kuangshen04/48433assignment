---
layout: home

hero:
  name: Agricultural Supply Chain Tracker
  text: 架构决策手册
  tagline: 在保留 Q&A 决策追溯的同时，按系统边界和端到端流程重新组织设计。
  actions:
    - theme: brand
      text: 查看系统地图
      link: /architecture/system-map
    - theme: alt
      text: 浏览决策目录
      link: /decisions/catalog

features:
  - title: 按系统阅读
    details: 从 Traceability Core、Trust & Recovery、Identity、IoT、Analytics 等责任边界理解架构。
  - title: 按流程验证
    details: 沿事件确认、召回调查和灾难恢复三条路径检查跨系统契约是否闭合。
  - title: 按决策追溯
    details: A/B/C 编号继续作为稳定索引，系统页只聚合结论，不取代原始决策理由。
---

## 这套文档解决什么问题

项目根目录中的 `major-decisions-qa.md` 是完整的决策日志，适合回答“为什么这样决定”。随着决策增多，同一个系统的职责会分散在多个问题中，不适合直接用来理解“这个系统到底做什么”。

本站提供三个互补入口：

1. [系统地图](/architecture/system-map)：先确定系统、控制域和信任边界。
2. [系统视图](/systems/traceability-core)：查看每个系统的职责、数据、接口、失败语义与关联决策。
3. [决策目录](/decisions/catalog)：按 A/B/C 编号回看状态和简要结论。

需要验证端到端行为时，使用[跨系统流程](/flows/event-acceptance)，而不是从单个系统页推断完整保证。
