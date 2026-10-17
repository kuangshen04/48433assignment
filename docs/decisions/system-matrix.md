# 系统—决策矩阵

本页给每个决定指定一个主要落点。系统页可以引用多个决定，但不应形成“多个系统都以为对方负责”的灰区。

## 按系统归属

| 系统/主题 | 主要决策 | 支撑或跨系统决策 | 该系统拥有的核心契约 |
|---|---|---|---|
| Scope & Context | A1、A2、A7、A8 | B1、B20 | 追溯层边界、参与方集成方式、首版复杂度 |
| Traceability Core | A3、A6、B6、B9、B10、B11 | A4、B13、B17、B18、B19 | EPCIS 写模型、状态机、handover、correction、lineage |
| Trust & Recovery | A5、B1、B2、B4、B7、B8 | B3、B6、B20、B22、C1、C3 | Archive envelope/Ack、Merkle leaf、KMS 与 recovery |
| Identity & Governance | B5、B16 | B6、B11、B20 | Organisation/key/delegation、签名 assurance、治理生效 |
| Data & Access | B3、B10、B20 | A5、B2、B12、B14、B15 | PUBLIC/CONSORTIUM/PRIVATE、ProtectedResource、retention |
| IoT & Edge | B14 | A8、B12、B16 | Telemetry ownership、summary/evidence、offline queue |
| Regulatory Analytics | B15、B17、B21 | B13、B18、B20 | 最小化输入、finding、disclosure、freshness |
| Query & Experience | B12、B18、B19 | B9、B10、B13、B21 | Consumer/participant/regulator reads、recall、watermark |
| Operations & Deployment | B13、B22、C1、C2、C3 | A7、B7、B8、B12、B20 | 部署、扩展、故障恢复、reference configuration |

## 跨系统不变量

| 不变量 | 负责建立 | 负责消费/展示 |
|---|---|---|
| `CONFIRMED` 只表示 signed + archived + finalised | Core + Archive/Anchor | 所有 projections、Analytics |
| Participant time 不是可信签署时间 | Identity/Signature validation | Core、Governance、offline UI |
| Platform DB 不是唯一历史 | Archive/Recovery | Core rebuild、Operations |
| Profile 不产生合规结论 | Profile/Core | IoT、Analytics、UI |
| 没有 finding 不等于没有风险 | Regulatory Analytics | Platform Advisory/UI |
| Recall query 不等于物理下架 | Traceability/Regulator Portal | Participant ERP/WMS/POS |
| QR 不等于防伪证明 | Consumer projection | Consumer UI/Analytics |
| PRIVATE hosting 不改变 ownership | Data Access | IoT、Evidence、Regulator access |

## 容易混淆的边界

### Traceability Core vs Regulatory Analytics

Core 判断结构、签名、权限和可重建关系；Analytics 判断 plausibility、risk 和 compliance relevance。机械派生的 handover status 不算异常判断。

### Identity Governance vs Public Blockchain

Governance 决定谁有现实参与资格；公共链限制确认后历史被静默替换。错误批准恶意成员不会让其获得其他组织的 self-custody key。

### Independent Archive vs PostgreSQL

Archive 保存可验证 canonical bytes；PostgreSQL 提供热状态和索引。Archive 没有完整 query 功能，PostgreSQL 也不能单独兑现 platform-independent recovery。

### Participant Evidence vs Platform-hosted Evidence

Hosting mode 是运营选择；classification、ownership、purpose 和 access grant 不随托管位置改变。
