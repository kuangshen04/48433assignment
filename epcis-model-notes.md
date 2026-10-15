# GS1 EPCIS 模型笔记

> 适用版本：EPCIS 2.0 / 2.0.1 与 CBV 2.0  
> 记录日期：2026-09-30  
> 用途：定义 Agricultural Supply Chain Tracker 的跨企业追踪事件语言，而不是直接作为完整业务系统设计。

## 1. EPCIS 是什么

GS1 EPCIS（Electronic Product Code Information Services）是一套供应链 visibility event 数据模型和标准接口。它让不同企业和不同软件系统使用共同语言表达：

```text
某个物理或数字对象
在某个时间和地点
经历了某项业务活动
并处于某种业务或环境状态
```

EPCIS 主要规定：

- 供应链事件的数据模型；
- 事件类型和语义；
- 产品、批次、物流单元和地点等标识的引用方式；
- 事件提交 Capture Interface；
- 事件检索 Query Interface；
- JSON、JSON-LD 和 XML 表达；
- 事件纠错语义；
- 自定义行业扩展方式。

EPCIS 不等于完整供应链系统，也不规定数据库、区块链、身份治理、访问控制或企业审批流程。

## 2. Event 而不是可变 Object

EPCIS 的核心记录是 `EPCISEvent`：某个对象在现实世界中发生过的一项业务事实。

```text
Batch A 在 Farm X 被创建
Batch A 被发货
Batch A 在 Warehouse Y 被接收
Cases A1-A10 被装到 Pallet P
Harvest Lots A、B 被加工成 Packaged Lot C
```

EPCIS 不以一个持续被覆盖更新的万能 `TraceableObject` 为中心。对象的历史和当前状态通常由所有相关事件推导：

```text
Object current state
= fold/reduce(all valid related events)
```

因此 EPCIS 更接近标准化的 event-sourcing/event-sharing 模型。

## 3. 事件的五个维度

每条 EPCIS 事件回答 what、when、where、why 和 how。

| 维度 | 问题 | 主要字段 |
|---|---|---|
| What | 涉及什么对象？ | `epcList`、`quantityList`、parent/child、input/output |
| When | 何时发生和何时入库？ | `eventTime`、`eventTimeZoneOffset`、`recordTime` |
| Where | 在哪里发生、事件后对象在哪里？ | `readPoint`、`bizLocation` |
| Why | 处于什么业务步骤和业务状态？ | `bizStep`、`disposition`、transactions、source/destination |
| How | 对象或环境当时状况如何？ | `sensorElementList` |

### 3.1 What

EPCIS 支持不同标识粒度。

#### Instance-level

明确到单个实例，例如：

- serialized retail item；
- 单个箱；
- pallet；
- transport container；
- reusable asset。

通常通过以下字段引用：

- `epcList`；
- `childEPCs`；
- `inputEPCList`；
- `outputEPCList`。

#### Class/lot-level

只知道某个产品类别或批次以及数量，例如：

```text
Strawberry Lot L20260930
Quantity: 500 kg
```

使用 quantity element 表达：

```text
epcClass
quantity
uom
```

因此 EPCIS 不要求所有农产品“一物一码”，批次级追踪是合法模型。

### 3.2 When

EPCIS 区分：

```text
eventTime
现实世界中事件发生的时间

recordTime
EPCIS Repository 记录事件的时间
```

`recordTime` 是 repository bookkeeping 字段，不描述现实事件。它在 Capture Interface 中应被忽略，在 Query Interface 返回的事件中应存在。

这个区分适合离线环境：

```text
eventTime  = 农场实际完成发货的时间
recordTime = 设备恢复网络后提交成功的时间
```

`eventTimeZoneOffset` 保存事件发生地点当时的时区偏移，便于保留业务时间上下文。

### 3.3 Where

EPCIS 区分两种位置：

```text
readPoint
事件实际被观察、扫描或捕获的位置

bizLocation
事件完成后，对象被认为所在的业务地点
```

例如：

```text
readPoint   = Warehouse Y Receiving Gate 3
bizLocation = Warehouse Y Cold Room
```

地点可以使用 GLN，也可使用其他 URI 或适当的地理标识。

### 3.4 Why

Why 描述业务上下文，不是自由文本解释。

#### `bizStep`

表示事件发生时正在进行的业务步骤，例如：

- `commissioning`；
- `packing`；
- `shipping`；
- `receiving`；
- `inspecting`；
- `sampling`；
- `retail_selling`；
- `sensor_reporting`。

#### `disposition`

表示事件之后对象所处的业务状态，例如：

- `active`；
- `in_transit`；
- `expired`；
- `recalled`；
- `retail_sold`；
- `stolen`。

两者的区别是：

```text
bizStep     = 这次做了什么
disposition = 做完以后对象是什么状态
```

示例：

```text
bizStep     = shipping
disposition = in_transit
```

其他 Why 字段包括：

- `bizTransactionList`：订单、发票、提单等业务交易；
- `sourceList`：业务转移的来源组织或地点；
- `destinationList`：业务转移的目标组织或地点；
- `persistentDisposition`：需要跨事件显式 set/unset 的持续状态。

### 3.5 How

EPCIS 2.0 通过 `sensorElementList` 表达传感器信息。

```text
sensorElementList
├── sensorMetadata
└── sensorReport
```

`sensorMetadata` 可以包含：

- `deviceID`；
- `startTime`、`endTime`；
- `deviceMetadata`；
- `rawData`；
- `dataProcessingMethod`；
- `bizRules`。

`sensorReport` 可以包含：

- measurement type；
- observation time；
- value 和 unit；
- min/max/mean；
- standard deviation；
- microorganism；
- chemical substance；
- alarm/exception。

EPCIS 不要求在单个事件中嵌入全部高频原始数据。事件可以保存统计摘要，并通过 `rawData` 引用外部时序数据。

## 4. 五种标准事件类型

### 4.1 ObjectEvent

`ObjectEvent` 表示一个或多个对象经历了相同业务事件。

典型场景：

- batch creation/commissioning；
- inspection；
- shipping；
- receiving；
- sensor reporting；
- retail selling；
- destroying/decommissioning。

主要 What 字段：

```text
epcList          instance-level objects
quantityList     class/lot-level objects
action
```

ObjectEvent 的 action：

- `ADD`：对象生命周期开始；
- `OBSERVE`：对象生命周期中的观察或业务活动；
- `DELETE`：对象生命周期结束。

`DELETE` 不代表删除数据库记录，而是声明该对象不应继续出现在后续正常事件中。

### 4.2 AggregationEvent

`AggregationEvent` 表示可逆的物理包装、装载或容纳关系。

```text
Cases A1-A10 → Pallet P
Pallets P1-P5 → Container C
```

主要字段：

```text
parentID
childEPCs / childQuantityList
action
```

AggregationEvent 的 action：

- `ADD`：children 加入 parent；
- `OBSERVE`：观察到组合关系存在；
- `DELETE`：children 从 parent 移除。

关键语义：child 仍保留自己的身份，组合关系通常可以被拆除。

### 4.3 TransformationEvent

`TransformationEvent` 表示一个或多个输入对象被全部或部分消耗，并产生一个或多个新输出对象。

```text
Harvest Lot A ─┐
               ├─→ Packaged Lot C
Harvest Lot B ─┘
```

主要字段：

```text
inputEPCList
inputQuantityList
outputEPCList
outputQuantityList
transformationID
```

Transformation 与 Aggregation 的区别：

```text
Aggregation
对象只是被装在一起，child 仍存在，关系可逆

Transformation
输入参与产生新的输出，通常不可逆
```

多个持续一段时间的 transformation events 可以共享相同 `transformationID`。

### 4.4 TransactionEvent

`TransactionEvent` 表示对象与商业交易建立、保持或解除关联。

```text
Pallet P
↔ Purchase Order 123
↔ Invoice 456
```

它不负责支付，也不自动代表 ownership/custody transfer。许多场景可以直接在其他事件的 `bizTransactionList` 中附上订单或发票，因此不一定需要独立 TransactionEvent。

### 4.5 AssociationEvent

`AssociationEvent` 是 EPCIS 2.0 新增的类型，用于比包装关系更持久的关联。

```text
Sensor D 安装到 Reusable Container C
Equipment E 固定到 Location L
```

主要字段：

```text
parentID
childEPCs / childQuantityList
action = ADD / OBSERVE / DELETE
```

与 Aggregation 的区别：

- Aggregation 主要表示临时包装、装载和共同移动；
- Association 主要表示安装或更持久的组成关系；
- Association 的 `parentID` 可以使用物理地点标识。

本项目可以用 AssociationEvent 表达长期 `Device → Container` 或 `Sensor → Cold Room` 绑定。仅针对一次运输的临时设备绑定也可以由普通事件和 evidence reference 表达。

## 5. Action 的语义

| Event Type | ADD | OBSERVE | DELETE |
|---|---|---|---|
| ObjectEvent | 开始对象生命周期 | 观察或普通业务活动 | 结束对象生命周期 |
| AggregationEvent | 加入 parent | 观察组合关系 | 从 parent 移除 |
| TransactionEvent | 建立交易关联 | 观察关联 | 解除关联 |
| AssociationEvent | 建立持久关联 | 观察关联 | 解除关联 |
| TransformationEvent | 不使用 | 不使用 | 不使用 |

`action` 与 `bizStep` 是不同字段：

```text
action  = OBSERVE
bizStep = shipping
```

表示对象没有被创建或销毁，而是在生命周期中经历发货步骤。

## 6. CBV：统一业务词汇

EPCIS 规定事件字段结构；Core Business Vocabulary（CBV）规定字段常用值及其业务语义。

CBV 主要定义：

- business step；
- disposition；
- business transaction type；
- source/destination type；
- error reason；
- sensor measurement 等标准词汇。

采用 CBV 的目的，是避免不同公司分别使用以下词汇表达相同业务：

```text
shipping
shipped
dispatch
sent_out
```

如果 CBV 没有合适值，可以定义由联盟控制的 URI，例如：

```text
https://example.org/cbv/bizstep/field_harvesting
```

但自定义词汇越多，互操作性越差。

## 7. 标识方式

EPCIS 可以引用：

- EPC URN；
- GS1 Digital Link URI；
- 符合要求的其他 URI。

常见 GS1 标识包括：

| 标识 | 用途 |
|---|---|
| GTIN | 产品类别 |
| GTIN + lot | 产品批次 |
| SGTIN | 序列化产品实例 |
| SSCC | 物流单元，如箱、托盘或容器 |
| GLN | 企业或地点 |
| GRAI | 可重复使用资产 |
| GIAI | 单个资产 |

EPCIS 本身不负责：

- 分配 GTIN/GLN；
- 打印二维码；
- 管理 RFID；
- 防止标签复制或更换；
- 证明标签贴在正确的物理对象上。

## 8. Capture 和 Query 接口

### 8.1 Capture Interface

Capture Interface 接收由业务系统生成的 EPCIS events：

```text
ERP / WMS / Mobile / IoT Adapter
                 │
                 ▼
          EPCIS Capture API
                 │
                 ▼
          EPCIS Repository
```

EPCIS 2.0 支持 REST/OpenAPI、JSON、JSON-LD 和 XML。

### 8.2 Query Interface

Query Interface 支持根据以下条件检索事件：

- object ID；
- event ID/type；
- event/record time；
- bizStep/disposition；
- location/read point；
- source/destination；
- parent/child；
- transformation input/output；
- error declaration。

REST 资源包括：

```text
/events
/events/{eventID}
/eventTypes/{eventType}/events
```

标准还定义 SimpleEventQuery 和 standing query/callback。GS1 提供 OpenAPI、JSON Schema、XSD、SHACL 和 JSON-LD context 等 normative artefacts。

EPCIS 不规定 repository 必须采用关系数据库、图数据库还是区块链。

## 9. 纠错和不可覆盖历史

EPCIS Capture/Query Interface 不提供直接修改或删除已记录事件的操作。发现错误时使用新的 `ErrorDeclaration`。

```text
Original Event E1
        │
Error Declaration
“E1 的业务断言是错误的”
        │
Corrective Event E2
```

ErrorDeclaration 包含：

```text
declarationTime
reason
correctiveEventIDs
```

错误声明事件在除 `errorDeclaration` 和 `recordTime` 外的内容上与原事件相同，并保留相同 `eventID`。原事件不会被修改；后续查询可以返回原事件、错误声明和修正事件。

这与本项目的 append-only blockchain ledger 很契合：纠错通过附加记录表达，不覆盖历史。

## 10. Certification 和扩展

EPCIS 事件可以包含 `certificationInfo`，指向与事件中的对象、地点或组织有关的认证详情。认证详情可以使用 GS1 Web Vocabulary 的 `CertificationDetails` 表达。

EPCIS 允许使用 namespace、URI 和 JSON-LD context 增加行业或企业字段。例如农业 profile 可以增加：

```text
harvestMethod
cropVariety
farmPlot
pesticideTreatment
organicClaim
qualityGrade
```

推荐扩展顺序：

```text
EPCIS core
+ CBV standard values
+ consortium-approved agricultural profiles
+ limited company-specific extensions
```

不应允许每个企业随意提交结构完全不同的 JSON。

## 11. EPCIS 没有规定的内容

EPCIS 不负责：

- 企业如何加入或退出联盟；
- organisation/user/device identity；
- 登录、RBAC 或 ABAC；
- 数字签名和密钥管理；
- 哪些事件需要双方 endorsement；
- 字段级数据可见性；
- 数据上链或链下；
- 区块链类型和共识机制；
- 数据库和云部署；
- 企业争议处理；
- IoT 设备注册、校准和撤销；
- 法规合规判断；
- 离线同步；
- 消费者 UI；
- 完整 recall workflow。

EPCIS 可以分别表达：

```text
Company A 声明 Batch X 已发货
Company B 声明 Batch X 已接收
```

但不规定 A 与 B 是否必须共同签署同一条交接，也不判断双方出现差异时谁正确。

## 12. 官方资料

- [GS1 EPCIS & CBV](https://www.gs1.org/standards/epcis)
- [EPCIS 2.0.1 Standard](https://ref.gs1.org/standards/epcis/2.0.1/)
- [EPCIS Normative Artefacts](https://ref.gs1.org/standards/epcis/artefacts)
- [EPCIS/CBV Implementation Guideline 2.0](https://ref.gs1.org/guidelines/epcis-cbv/2.0.0/)
- [Core Business Vocabulary 2.0](https://ref.gs1.org/standards/cbv/2.0.0/)
- [EPCIS JSON/XML Examples](https://ref.gs1.org/docs/epcis/examples)
- [GS1 Digital Link](https://www.gs1.org/standards/gs1-digital-link)

