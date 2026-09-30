# Agricultural Supply Chain Tracker — 当前系统边界

> 状态：Working draft  
> 记录日期：2026-09-30  
> 说明：本文记录目前讨论形成的系统边界。它用于约束后续业务和架构设计，不代表所有技术与治理决策已经最终确定。

## 1. 系统定位

Agricultural Supply Chain Tracker 是一个跨企业的农业供应链追踪平台。

它不取代参与企业已有的 ERP、WMS、TMS、农场管理或 IoT 平台，而是在这些系统之上提供共同的追踪协议、可信事件记录和端到端查询能力。

```text
Enterprise Operational Systems
ERP / WMS / TMS / Farm Management / IoT Platform
                         │
            API / EPCIS / File / Platform UI
                         │
Agricultural Supply Chain Tracker
Identity / Schema / Events / Ledger / Trace / Disclosure
```

系统的核心目标是：

> 将多个相互独立、并不完全互信的供应链企业分别产生的追踪事件，连接成一条可验证、不可被静默改写、按权限查询的端到端产品 provenance。

## 2. 主要参与者

### 2.1 供应链参与组织

- Farmer/Producer；
- Processor/Packer；
- Logistics Provider；
- Distributor/Wholesaler；
- Retailer。

它们创建或处理 traceable objects，提交自己负责阶段的事件，并查询与自己有业务关系的数据。

### 2.2 证据提供者

- IoT platform/device operator；
- Laboratory；
- Certification body；
- Inspector/Auditor。

它们提供传感器观测、检测结果、证书或审计证据，但不一定参与产品 custody。

### 2.3 查询者

- Consumer：查询经过筛选的公共 provenance；
- Auditor/Regulator：在被授权时查询更完整的历史和证据；
- Supply-chain analyst/manager：查看流程、异常和可视化结果。

### 2.4 平台和联盟治理方

- Platform Operator：运行共享应用和部分基础设施；
- Consortium Members：共同决定成员准入、schema/profile、账本规则和网络升级；
- Node Operators：由独立利益方运行 ledger peer/orderer/validator 节点。

平台运营者不应单独拥有所有企业签名密钥、全部账本节点和全部治理权限。

## 3. 核心业务域：系统范围内

### 3.1 Network, Organisation and Identity Management

管理可信网络中的参与主体：

- organisation；
- site/location；
- user；
- device；
- organisation membership；
- role and delegation；
- organisation/device certificate；
- signing public key；
- identity suspension/revocation；
- organisation onboarding/offboarding。

这一业务域回答：

```text
谁在提交事件？
代表哪个组织？
是否有资格提交这种事件？
设备是否属于该组织且凭证仍然有效？
```

身份、授权和联盟治理需要区分：

- Identity：主体是谁；
- Authorisation：主体可以做什么；
- Governance：组织为什么有资格加入和参与网络。

### 3.2 Schema and Profile Registry

管理跨企业事件和对象扩展的共同语义：

- EPCIS core model；
- Core Business Vocabulary（CBV）子集；
- product/industry profile；
- regional/compliance profile；
- extension fields；
- schema version；
- validation rules；
- deprecation and migration rules。

采用：

```text
Stable EPCIS core
+ Consortium-approved versioned profiles
+ Limited organisation-specific extensions
```

不允许每个企业为同类事件任意提交互不兼容的 JSON schema。

### 3.3 Traceable Object Registry

管理可被事件引用的标识对象及其最小 master data。

当前考虑的对象类型包括：

- Product class；
- lot/batch；
- serialized retail item；
- case；
- pallet；
- reusable asset；
- transport/logistic unit；
- device；
- location。

第一版以 lot/batch 为食品安全追踪的主要粒度，以 case、pallet、container 等物流单元辅助运输追踪；零售 serial 可以作为消费者查询入口并关联所属 batch。

对象支持以下关系：

- aggregation/disaggregation；
- transformation；
- persistent association；
- derivation/split；
- evidence attachment。

对象当前状态主要从事件历史派生，不以持续覆盖一个万能 object record 为主要模型。

### 3.4 Traceability Event Capture and Ledger

使用 EPCIS 作为 canonical event model，记录：

```text
What / When / Where / Why / How
```

第一版计划支持：

- ObjectEvent；
- AggregationEvent；
- TransformationEvent；
- 可选 AssociationEvent。

事件处理包括：

1. 接收平台 UI、API、file import 或 integration adapter 的事件；
2. 验证 schema/profile；
3. 验证 organisation/user/device identity；
4. 验证签名和提交权限；
5. 验证对象和引用是否存在；
6. 验证状态转换及关系是否允许；
7. 执行 idempotency、duplicate 和 ordering 检查；
8. 根据 endorsement policy 收集所需签名；
9. 向共享 ledger 提交不可覆盖记录；
10. 更新链下 trace graph/read model。

### 3.5 Event Correction and Dispute Representation

不可篡改不等于禁止纠错。系统支持：

- EPCIS ErrorDeclaration；
- corrective event；
- correction reason；
- original/corrective event linkage；
- authorised reviewer；
- complete revision and audit history；
- disputed/unconfirmed state。

错误事件不能被物理删除或覆盖：

```text
Original Event
      ↓
Error Declaration
      ↓
Corrective Event
```

系统需要同时展示原始断言、错误声明和当前有效解释。

### 3.6 Inter-organisation Handover

交接是构建在 EPCIS event 和 traceable object 之上的核心服务。

交接至少管理：

- sender and receiver；
- source and destination site；
- objects/quantities；
- dispatch and receipt events；
- custody；
- ownership reference；
- physical movement；
- acceptance/rejection；
- partial acceptance；
- quantity or condition discrepancy；
- sender/receiver signatures。

推荐采用双阶段模型：

```text
Sender: Dispatch declared
             ↓ pending
Receiver: Receipt accepted / partially accepted / rejected
```

发送方与接收方各自提交事实。平台记录不一致，不擅自认定哪一方在现实世界中正确。

`ownership`、`custody` 和 `physical location` 是不同概念，不应由一个 owner 字段代替。

### 3.7 Evidence and External Data Integration

统一管理外部证据引用：

- IoT observation；
- certificate；
- laboratory report；
- inspection result；
- document/image；
- external ERP/WMS/TMS event reference。

IoT 平台通常在系统边界之外，但本系统内部负责：

- device identity and ownership；
- device certificate/revocation；
- device-object/shipment association；
- sensor metadata；
- observation time window；
- measurement summary；
- threshold exception；
- raw data URI/hash；
- device/platform signature。

完整高频时序数据默认留在外部 IoT platform 或链下 time-series storage：

```text
IoT Device
    ↓
External IoT Platform
    ├── raw time-series
    └── signed summary/hash
              ↓
Traceability Platform
```

### 3.8 Trace, Verification and Read Models

提供：

- object current state；
- complete event history；
- backward provenance；
- forward destination/impact；
- aggregation contents；
- transformation inputs and outputs；
- current/last known custodian and location；
- provenance completeness indicators；
- signature/hash/schema verification；
- revoked/superseded/error-declared status。

验证结果需要区分：

```text
Cryptographically valid
Schema valid
Authorised publisher
Evidence available
Superseded/revoked
Incomplete provenance
Unverified external claim
```

查询和可视化使用链下 read model/trace graph，不直接依赖遍历区块链。

### 3.9 Access Control and Controlled Disclosure

系统根据主体和用途产生不同的数据投影：

```text
Organisation-private view
Trading-partner view
Auditor/regulator view
Consumer-public view
```

访问控制可能作用于：

- object；
- event；
- field；
- evidence/document；
- organisation relationship；
- role and purpose。

消费者可以看到来源、主要流转阶段、公开认证和 safety/recall status，但不能自动看到价格、合同、精确库存、个人信息和商业敏感字段。

### 3.10 Minimal Food-safety and Compliance Support

系统不负责制定或执行全部食品安全法规，但提供最小合规支持：

- 将 certificate/inspection/lab result 关联到 organisation、site 或 batch；
- 记录 issuer、validity period、revocation status 和 hash；
- 验证强制追踪字段或证据是否缺失；
- 导出授权范围内的审计历史；
- 标记 batch 为 hold/affected/recalled；
- 执行 upstream/downstream impact query。

第一版不需要实现完整 recall case-management workflow，但必须能计算潜在影响范围并暴露批次安全状态。

## 4. 平台提供的派生能力：系统范围内

这些能力依赖核心业务域，但不是账本的基础语义。

### 4.1 Consumer Trace Portal

- 扫描 QR/GS1 Digital Link；
- 查询公共 product/batch provenance；
- 展示公开证书和来源信息；
- 展示 affected/recalled status；
- 隐藏私有和商业敏感数据。

### 4.2 Visualisation and Insights

- supply-chain graph；
- object provenance graph；
- geographic flow；
- IoT condition timeline；
- incomplete trace/gap；
- event and condition exceptions；
- organisation-authorised operational insights。

### 4.3 Compliance/Audit Export

- 按 object、batch、organisation、site 和时间范围导出；
- 包含事件、签名、证据引用和验证结果；
- 遵守访问控制和数据最小化规则。

### 4.4 Notifications

可作为辅助能力通知：

- handover pending/rejected；
- missing required event/evidence；
- IoT threshold exception；
- certificate expiry/revocation；
- batch affected/recalled。

通知本身不是账本事实来源，关键状态仍以事件记录为准。

## 5. 接入方式：系统范围内

平台支持不同数字化成熟度的参与者：

```text
Small Farmer/SME     → PWA/mobile/web forms
Legacy Organisation → CSV/file import
Large Enterprise    → EPCIS/REST integration API
IoT Provider        → IoT/evidence ingestion API
Consumer            → Public trace portal
Auditor             → Authorised query/export interface
```

### 5.1 Rural/Offline Support

农村访问能力至少包括：

- offline event drafting/queue；
- delayed submission；
- low-bandwidth mode；
- retry and idempotency；
- eventTime/recordTime separation；
- conflict and duplicate handling；
- local secure key storage where feasible。

离线事件在提交并得到 ledger confirmation 前只能视为 pending local record。

## 6. 外部系统：系统边界之外

以下系统继续由参与企业或专业服务商负责，本平台只通过接口接收所需事件或证据。

### 6.1 Enterprise Operational Systems

- ERP；
- Warehouse Management System（WMS）；
- Transport Management System（TMS）；
- Manufacturing Execution System（MES）；
- Farm Management System；
- retailer inventory/POS system。

### 6.2 IoT Infrastructure

- sensor firmware；
- device provisioning platform；
- connectivity/network provider；
- raw telemetry ingestion；
- high-frequency time-series database；
- device maintenance and calibration operations。

本平台管理 IoT evidence 与追踪对象的可信关联，但不负责完整 IoT fleet management。

### 6.3 Laboratory and Certification Systems

- 实际样本采集和检测；
- laboratory information management；
- 证书审核和签发；
- 认证机构的法律判断；
- inspection scheduling and field operations。

本平台验证签发者身份、保存证据引用和完整性证明，但不自动保证现实检测过程正确。

### 6.4 Regulatory Systems

- 法律和法规制定；
- 正式行政审批；
- 执法决定；
- 政府处罚；
- 政府拥有的监管数据库。

监管机构可以成为授权查询者或独立节点运营者，但本平台不取代监管机构。

### 6.5 Public Blockchain

如果联盟账本采用周期性公共链锚定，公共区块链属于外部证明系统。本平台向其提交 Merkle root/commitment，不提交敏感业务明文。

## 7. 明确排除的业务

当前不在系统范围内：

- 完整农业生产和种植计划；
- 施肥、饲养、用药等完整 farm operations management；
- 采购、销售和合同谈判；
- 商品定价；
- 支付、结算和财务会计；
- 完整库存和仓库作业；
- 车辆调度和路线优化；
- 物流承运业务执行；
- 实验室检测本身；
- 证书审核和签发决定；
- IoT 固件和 fleet management；
- 食品质量的自动最终判定；
- 法律责任认定；
- 监管执法；
- 保证企业最初输入的数据在现实世界中必然真实。

系统可以验证：

```text
谁在什么时间提交了什么断言
提交者当时是否被授权
断言提交后是否被修改
证据是否与已记录 hash 一致
```

系统不能仅凭区块链证明：

```text
断言描述的现实世界事实必然真实
```

## 8. 初步数据边界

### 8.1 共享联盟账本

初步考虑保存：

- event ID/version/type；
- traceable identifiers；
- publisher organisation；
- event and recorded time；
- object relationship references；
- business status necessary for shared interpretation；
- payload/evidence hash；
- signatures；
- visibility/access policy reference；
- error/corrective event linkage。

### 8.2 链下平台存储

初步考虑保存：

- 完整 EPCIS JSON/JSON-LD；
- organisation-authorised business details；
- search index；
- trace graph/read model；
- analytics model；
- encrypted document/evidence metadata；
- consumer-safe projection。

### 8.3 外部数据存储

初步考虑继续由外部系统保存：

- raw IoT time-series；
- ERP/WMS/TMS 原始记录；
- laboratory source records；
- 大型 PDF、图片和视频；
- 不需要跨组织共享的企业私有数据。

具体链上/链下字段仍属于后续架构决策，当前边界只确定责任归属。

## 9. 初步部署和信任边界

当前倾向：

```text
SaaS Application Plane
Web / PWA / API / Query / Read Models
              │ signed EPCIS events
              ▼
Multi-organisation Consortium Ledger
Producer / Logistics / Retail / Independent Body / Platform Operator
              │ optional periodic commitment
              ▼
External Public Blockchain
```

关键约束：

- SaaS 可以托管用户体验和共享计算；
- 企业私钥不由 SaaS 运营商统一持有；
- 重要联盟成员独立运行 ledger nodes；
- 网络规则变更需要多组织批准；
- handover 等关键事件需要相关组织 endorsement；
- 小企业不需要运行节点，但需要拥有可验证的组织或用户身份；
- 可选使用公共链 commitment 防止整个联盟事后无痕重建历史。

## 10. 最小端到端业务场景

一个场景应能验证目前全部核心边界：

```text
1. Farmer 注册 Batch A
2. Batch A 按 Fresh Produce Profile 验证并提交 commissioning event
3. Batch A 或其包装单元被聚合到 Pallet P
4. Farmer 声明向 Distributor 发货
5. IoT Device D 与运输对象/阶段关联并提供温度证据
6. Distributor 接收并确认或报告差异
7. Pallet P 被拆分，部分对象发送给 Retailer
8. Retailer 接收
9. Consumer 查询允许公开的 provenance
10. Auditor 验证签名、hash、证据和 provenance completeness
11. 错误事件通过 ErrorDeclaration 和 corrective event 纠正
12. 如果 Batch A 被标记 affected，系统执行 downstream impact query
```

## 11. 尚未最终决定的问题

- 首个产品 profile 是否聚焦 cold-chain fresh produce；
- 是否强制使用真实 GS1 GTIN/GLN/SSCC，还是同时支持平台 URI；
- AssociationEvent 是否进入第一版；
- 联盟账本具体采用 Hyperledger Fabric、其他 permissioned ledger 或公共链方案；
- 哪些组织必须运行节点；
- ordering/endorsement quorum；
- 哪些 EPCIS 核心字段进入 ledger 明文，哪些仅保存 hash；
- 是否实施公共链周期性 anchoring；
- 交接是否强制 sender+receiver 双方 endorsement；
- consumer serialisation 是第一版能力还是仅支持 batch QR；
- compliance profile 选择哪些具体地区和法规；
- 完整 recall workflow 是否属于后续版本。

## 12. 关联文档

- [Case background](./Agricultural%20Supply%20Chain%20Tracker.md)
- [Industry platform research](./industry-platform-research.md)
- [GS1 EPCIS model notes](./epcis-model-notes.md)

