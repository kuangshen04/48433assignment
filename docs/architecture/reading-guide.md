# 阅读方式

这套文档没有把 Q&A 拆散后逐段复制，而是把它转换为三种视角。

## 三种视角

| 视角 | 回答的问题 | 权威程度 |
|---|---|---|
| 决策目录 | 我们决定了什么，哪些仍待定？ | 决策状态索引 |
| 系统视图 | 某个系统负责什么、依赖什么？ | 当前架构基线的聚合说明 |
| 跨系统流程 | 一次真实操作如何穿过多个系统？ | 契约与故障语义验证 |

项目根目录的 `major-decisions-qa.md` 仍然是完整 trade-off、否决方案和讨论背景的来源。本站中的 `[B5]`、`[B8]` 等引用均指向[决策目录](/decisions/catalog)中的稳定编号。

## 信息维护规则

- 新的重大取舍先进入 Q&A，并获得新的或现有决策编号。
- 决策改变后，再更新受影响的系统页和流程页。
- 系统页不重复长篇 trade-off，只说明当前契约及其来源。
- 同一规则只指定一个主要负责系统；其他系统通过接口或只读投影使用它。
- C 类待定项在最终报告前必须转为明确 reference deployment，或者明确移出首版范围。

## 推荐阅读顺序

第一次阅读：

1. [系统地图](/architecture/system-map)
2. [Traceability Core](/systems/traceability-core)
3. [Trust & Recovery](/systems/trust-recovery)
4. [事件接收与确认](/flows/event-acceptance)
5. 按需要查看其他系统

进行评审或答辩准备：

1. [系统—决策矩阵](/decisions/system-matrix)
2. [待定事项](/decisions/open-items)
3. 三条[跨系统流程](/flows/event-acceptance)
