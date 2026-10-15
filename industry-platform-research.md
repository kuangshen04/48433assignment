# 农业供应链追踪平台调研

> 调研对象：IBM Food Trust、TE-FOOD、OriginTrail、VeChain  
> 调研日期：2026-09-30  
> 用途：为 Agricultural Supply Chain Tracker 的业务边界、数据模型、区块链和部署方式提供参考。

## 1. 核心结论

这些平台通常不会要求供应链上所有企业更换为同一套 ERP、WMS、TMS 或农场管理系统。常见模式是：

```text
企业内部系统
ERP / WMS / TMS / Farm Management / IoT Platform
                         │
                  API / EPCIS / File / App
                         │
跨企业追踪平台
Identity / Event Validation / Access Control / Ledger / Trace Query
```

大型企业通常保留现有系统，通过 API 发布一部分需要跨组织共享的追踪事件；没有成熟系统的小型农场或供应商可以直接使用平台提供的移动端或 Web 界面。

行业中最常见的数据思想是 GS1 EPCIS 的“标识对象 + 事件”：

- 对象可以是产品类别、批次、序列化单品、箱、托盘、容器和地点；
- 事件回答 what、when、where、why 和 how；
- ObjectEvent、AggregationEvent 和 TransformationEvent 可以覆盖大部分食品追踪过程；
- 不同产品线在稳定事件结构之上增加版本化扩展字段。

区块链的合理作用是证明跨企业共享事件的来源、顺序和完整性，而不是替代所有企业数据库。高频 IoT 数据、个人信息、大文件和商业敏感信息通常需要链下保存。

## 2. IBM Food Trust

### 2.1 平台定位

IBM Food Trust 是面向食品供应链的共享追踪 SaaS，底层使用 IBM Blockchain Platform/Hyperledger Fabric。它提供一个跨组织共享数据和执行追踪查询的网络，而不是供应链企业共同使用的统一 ERP。

IBM 已发布 Food Trust/Blockchain Transparent Supply 的 cloud service withdrawal 信息，因此本项目将其作为历史架构参考，而不是当前产品推荐。

### 2.2 追踪对象和数据模型

IBM Food Trust 支持以下数据：

- Product ID；
- lot number；
- pallet number；
- Serial Shipping Container Code（SSCC）；
- EPCIS Object Event；
- EPCIS Aggregation Event；
- EPCIS extension；
- dispatch advice 和 receiving advice；
- purchase order；
- item data notification；
- certificate。

因此 IBM 没有规定唯一追踪粒度，而是使用统一标识和事件连接产品、批次、托盘、发货、收货和证书。

### 2.3 平台自带业务

- 企业、用户和设施 onboarding；
- 数据录入和 Connector API；
- EPCIS 事件摄取；
- 端到端 trace 查询；
- certificate manager；
- 合规、测试、审计、设施和交易证书共享；
- 数据 entitlement 和组织间可见性控制；
- Fresh Insights 和平台活动分析。

每个组织拥有自己上传的数据，并选择哪些组织可以查看。多个组织上传引用同一产品实例的记录后，平台可以将这些记录连接成供应链历史。

### 2.4 外部系统负责的业务

IBM Food Trust 通常不替代：

- 农场和生产管理；
- 完整库存管理；
- 仓库拣货和运输调度；
- 财务、支付和合同；
- 实验室检测过程；
- IoT 设备运维；
- 企业内部质量审批。

大型企业需要从内部系统抽取数据、转换为平台要求的 XML/JSON/EPCIS 结构，再通过 Connector API 上传。较小参与者可以使用平台界面录入数据。

### 2.5 修改和不可变性

IBM 允许纠正事件，但不覆盖历史。重新摄取相同 `eventID` 会生成新版本，旧版本继续留在账本中，而查询通常暴露最新版本。

```text
Event E1 v1
    ↓ correction using the same eventId
Event E1 v2
```

### 2.6 部署和去中心化

Food Trust 产品本身是运行在 IBM Cloud 上的 SaaS。Hyperledger Fabric 技术上支持各组织独立运行 peer、CA 和 ordering node，也支持跨云及本地 Kubernetes 部署，但公开的 Food Trust 产品资料没有清晰说明普通订阅者是否能自行运行 Food Trust peer 或 orderer。

因此需要区分：

```text
IBM Blockchain Platform 的多组织部署能力
不等于
Food Trust SaaS 的普通客户必然拥有独立节点
```

Food Trust 的数据所有权和访问授权是分散的，但基础设施控制可能高度集中在 IBM。这能防止普通参与者静默修改数据，但对“防止平台运营商本身控制网络”的保障取决于实际节点和治理安排。

### 2.7 可借鉴之处

- 使用 EPCIS 作为企业间共同数据语言；
- 上传者拥有数据并控制可见性；
- 纠错采用版本追加而不是覆盖；
- 将共享追踪层与企业内部系统分开。

## 3. TE-FOOD

### 3.1 平台定位

TE-FOOD 是较完整的食品追踪产品，覆盖标识、采集、账本、处理和消费者展示。它既可以作为小企业直接使用的业务应用，也可以作为大型企业 ERP 之上的 traceability layer。

### 3.2 追踪对象和标识

TE-FOOD 支持：

- item；
- lot/batch；
- case；
- transport；
- livestock；
- serialized retail product；
- QR、RFID 和 security seal。

零售商品的唯一 serial 可以连接到所属生产或包装 batch：

```text
Retail Item Serial
        ↓ belongs to
Packaging Batch
        ↓ derived from
Production/Harvest Batch
```

### 3.3 平台自带业务

- 产品和包装序列化；
- QR/RFID/标签管理；
- B2B mobile app 和 Web admin；
- 农场、加工、包装、发货和收货事件记录；
- 批次和原料关系；
- blockchain traceability ledger；
- 端到端追踪；
- targeted recall；
- supplier protocol/control point；
- 公司、产品和批次级证书管理；
- 报表和流程分析；
- 消费者扫码页面和召回通知。

### 3.4 接入已有系统

TE-FOOD 根据参与者数字化程度提供多种入口：

```text
小型农场             → B2B mobile app
有基本数字化能力的企业 → Web admin
只有旧系统的企业       → Excel upload
大型企业              → API / EPCIS integration
IoT                  → staging system / integration API
```

API 可以创建和更新 master data、发送 batch traceability data，并连接工业打印机完成产品序列化。平台能够接收 EPCIS XML，也能把非标准事件转换为 EPCIS。

TE-FOOD Enterprise 支持定制供应链流程和数据集；Lite 版本则提供较固定的流程和数据集。

### 3.5 外部系统负责的业务

企业仍可以保留：

- ERP 和 farm management system；
- MES/WMS/TMS；
- 实验室系统；
- 工业打印和包装设备；
- IoT 设备管理；
- 内部生产、库存和质量控制。

小企业可能直接把追踪记录托管给 TE-FOOD；大型企业更可能只同步跨组织追踪所需的数据。

### 3.6 部署和去中心化

TE-FOOD 的应用通常由 TE-FOOD 或实施合作方托管。其 TrustChain 被描述为 public-permissioned/public-private hybrid blockchain：

- 只有经过验证和许可的参与者可以写入或验证；
- 部分 Supernodes 由供应链公司运行；
- 部分 Masternodes 由社区运行；
- 企业可以选择哪些数据公开到 explorer；
- 链上只处理 traceability-related business activities。

这比单一供应商运行全部节点更分散，但准入、validator 许可、chaincode 升级和治理仍可能依赖 TE-FOOD，因此属于许可型、有限去中心化网络。

### 3.7 可借鉴之处

- 为不同技术成熟度的企业提供 App、Web、Excel、API 和 EPCIS；
- 批次追踪与零售单品序列化并存；
- 平台可同时作为完整工具和企业系统上方的共享追踪层；
- 不要求每一个小农场运行节点。

## 4. OriginTrail

### 4.1 平台定位

OriginTrail 是 Decentralized Knowledge Graph（DKG）和可信数据基础设施，不是开箱即用的农业供应链 SaaS。业务应用需要由企业或解决方案提供商构建。

### 4.2 数据模型

OriginTrail 将相互关联的数据包装为 Knowledge Asset。Knowledge Asset 可以表示：

- 产品或批次；
- 物流设备；
- 地点；
- EPCIS 供应链事件；
- 贸易文件；
- 证书和凭证；
- 上述对象之间的关系。

数据使用 RDF/JSON-LD 和图关系表示，可结合 GS1 EPCIS、W3C Verifiable Credentials、Digital Link 等标准。Knowledge Asset 具有稳定的 UAL 标识、发布者、所有权和版本历史。

### 4.3 平台原生能力

- 发布和更新 Knowledge Asset；
- 数据身份和所有权；
- 数据来源和发布者证明；
- 数据完整性验证；
- 图关系连接、发现和查询；
- 授权共享；
- 区块链 anchoring。

### 4.4 不自带的业务

OriginTrail 不直接提供：

- 农场发货或收货 UI；
- 库存管理；
- 运输调度；
- 食品召回工作流；
- 质量审批；
- 农业专用消费者页面。

典型集成过程是：

```text
Enterprise TMS/ERP
        ↓ extract
Shipment/Product Event
        ↓ transform
GS1 EPCIS 2.0 Knowledge Asset
        ↓ publish
OriginTrail DKG
        ↓ query
Enterprise Traceability Application
```

### 4.5 链上和链下

OriginTrail 明确区分两个层次：

```text
DKG / knowledge graph
- 保存和查询完整的语义数据和关系

Blockchain
- asset identity/ownership
- state update
- publisher and timestamp proof
- cryptographic fingerprint
```

即完整图数据不等于全部存进区块链；区块链主要提供可验证身份、状态和完整性证明。

### 4.6 部署和去中心化

OriginTrail 网络由独立 DKG nodes 承载，组织和个人都可以运行节点。企业也可以使用第三方节点或网关，而不自行运维。DKG 的证明层连接 NeuroWeb、Gnosis、Base 等外部网络。

与高度托管的 SaaS 相比，企业可以：

- 自己运行 DKG node；
- 自己保存和查询图数据；
- 保管钱包和发布密钥；
- 依靠外部公共链验证资产状态。

这种模式的去中心化较强，但增加了节点运维、token、钱包、隐私共享和应用开发复杂度。

### 4.7 可借鉴之处

- 将复杂供应链关系放在可查询的图数据层；
- 仅把身份、版本和指纹等证明放到区块链；
- 使用语义标准处理多产品、多 schema 和跨企业数据连接；
- 允许企业独立保存、发布和验证数据。

## 5. VeChain

### 5.1 平台定位

VeChainThor 是公共企业级区块链；ToolChain 是建立在其上的 BaaS/SaaS 和业务模板。使用同一公共链不代表所有企业使用同一套供应链应用。

### 5.2 追踪模型

ToolChain 主要采用：

- 商品 ID；
- 一物一码；
- QR、NFC 和 RFID 标签；
- 商品基本信息；
- 生产、物流和流转记录；
- IoT 环境数据；
- 第三方认证和消费者验证。

它更强调序列化商品、消费者扫码、防伪和品牌故事。

### 5.3 ToolChain 原生能力

- 商品数字身份；
- 一物一码；
- 基本溯源、防伪和第三方认证管理；
- 流转记录模板；
- API 和自定义模板；
- 区块链交易和验证证明。

### 5.4 外部系统负责的业务

企业通常仍需保留或建设：

- 生产和物流系统；
- 商品、库存和质量管理；
- IoT 平台；
- 数据映射和上链接口；
- 消费者应用；
- 具体业务智能合约。

VeChainThor 提供 REST API、SDK 和公共节点，企业也可以运行自己的 full node。

### 5.5 部署和去中心化

ToolChain 应用可以由平台以 SaaS/BaaS 方式托管，但底层 VeChainThor 是独立公共链：

- 当前由 101 个获准 validator 负责出块；
- 共识需要 `2/3 + 1` validators；
- validator 需要身份审核和抵押；
- 任何人都可以运行 full node 保存和验证账本；
- 普通 full node 不自动拥有出块权。

因此 ToolChain 可以在上链前拒绝、延迟或遗漏数据，也能控制自己的消费者展示，但不能单独改写已经由公共链 validators 确认的交易。企业可以绕过 ToolChain API，通过自己的 full node 验证链上记录。

这种模式比单一 SaaS 私有账本更抗平台运营商篡改，但 validator 准入和网络治理仍然不是完全开放的。

### 5.6 数据真实性限制

VeChain 的服务条款明确区分“不被修改”和“现实中真实”：平台可以证明第三方企业上传的信息之后没有被篡改，但不自动保证企业最初上传的数据准确、完整或真实。

这反映所有供应链区块链都会面对的 oracle problem。真实性还需要：

- 企业身份审核；
- 双方交接确认；
- 设备身份和安全硬件；
- 防拆标签；
- 实验室或认证机构签名；
- 现场审计。

### 5.7 可借鉴之处

- SaaS 业务应用可以与独立公共证明层分开；
- 企业可运行 full node 进行独立验证；
- 一物一码适合消费者入口和防伪，但食品安全的主追踪粒度仍可保持为 batch；
- 不应声称区块链能自动证明现实数据真实。

## 6. 横向比较

| 平台 | 应用模式 | 企业系统接入 | 节点/共识模式 | 去中心化判断 |
|---|---|---|---|---|
| IBM Food Trust | IBM Cloud SaaS | API、XML/JSON、EPCIS、平台录入 | Fabric 技术支持多组织节点，但 Food Trust 客户自建节点不明确 | 数据授权分散，基础设施可能高度托管 |
| TE-FOOD | 托管应用 + 定制实施 | Mobile、Web、Excel、API、EPCIS | 获准企业 Supernodes + 社区 Masternodes | 有分布性，但准入和治理许可化 |
| OriginTrail | 基础设施/中间件 | 企业自行构建发布和查询应用 | 独立 DKG nodes + 外部公共链 | 四者中最接近开放、可自部署模型 |
| VeChain | ToolChain SaaS/BaaS + 公链 | API、SDK、自定义应用 | 101 validators；任何人可运行 full node | 应用可中心化，最终账本不由单一应用控制 |

## 7. SaaS 与去中心化的判断

SaaS 本身不一定破坏去中心化。应按照以下层级判断。

### 7.1 单一 SaaS 控制所有组件

```text
SaaS controls:
- all application services
- all enterprise signing keys
- all peers
- all orderers/validators
- all governance keys
```

这种部署主要提供 append-only implementation 和内部审计，不能有效解决对 SaaS 运营商本身的不信任。

### 7.2 SaaS 托管应用，企业独立签名

```text
Company signs event
        ↓
SaaS validates and submits event
```

SaaS 仍能拒绝或延迟提交，但如果企业私钥不交给 SaaS，平台就不能伪造企业事件。

### 7.3 SaaS 托管应用，多组织运行联盟节点

```text
Platform Operator    peer/orderer
Producer Group       peer/orderer
Logistics Group      peer/orderer
Retail Group         peer/orderer
Independent Body     peer/orderer
```

如果 endorsement 和网络治理要求多个独立组织批准，平台运营商不能单方面写入、改写或修改规则。

### 7.4 私有联盟链锚定公共链

联盟账本可以周期性计算 Merkle root，并把 root 写入公共链：

```text
Private consortium ledger
          │ periodic commitment
          ▼
Public blockchain Merkle root
```

这样既不公开敏感业务数据，又能防止整个联盟事后无痕重建历史。

## 8. 参考资料

### GS1

- [EPCIS & CBV](https://www.gs1.org/standards/epcis)
- [EPCIS 2.0 Standard](https://ref.gs1.org/standards/epcis/2.0.0/)

### IBM

- [Using IBM Food Trust with App Connect](https://www.ibm.com/docs/en/app-connect/13.0.x?topic=applications-using-food-trust-app-connect-enterprise)
- [IBM Food Trust Connector API](https://www.ibm.com/docs/en/app-connect/12.0.x?topic=hga-food-trust)
- [Changing data already ingested into IBM Food Trust](https://www.ibm.com/support/pages/changing-data-already-ingested-ibm-food-trust)
- [IBM Blockchain Platform: managing organisations](https://www.ibm.com/docs/en/blockchain-platform/2.5.2?topic=console-managing-organizations)
- [IBM Support for Hyperledger Fabric deployment](https://www.ibm.com/docs/en/hlf-support/1.0.0?topic=started-about-support-hyperledger-fabric)
- [IBM Food Trust cloud service withdrawal](https://www.ibm.com/support/pages/cloud-service-program-withdrawal-ibm-supply-chain-intelligence-suite-and-ibm-blockchain-transparent-supply-and-select-parts-withdrawal-ibm-sterling-order-management)

### TE-FOOD

- [TE-FOOD Solution](https://te-food.com/solution/)
- [TE-FOOD Data Capture](https://te-food.com/solution/data-capture/)
- [TE-FOOD Data Processing](https://te-food.com/solution/data-processing/)
- [TE-FOOD Blockchain](https://te-food.com/solution/blockchain/)
- [TE-FOOD Business Card and TrustChain](https://te-food.com/business-card/)
- [TE-FOOD Implementation Guide](https://te-food.com/how-to-plan-a-food-traceability-implementation/)

### OriginTrail

- [OriginTrail Documentation](https://docs.origintrail.io/)
- [Knowledge Assets](https://github.com/OriginTrail/dkg/blob/main/docs/how-dkg-works/knowledge-assets.md)
- [OriginTrail Supply Chain Assets](https://origintrail.io/blog/from-data-to-assets-transforming-global-supply-chains-with-origintrail-decentralized-knowledge-graph)
- [OriginTrail Multichain Architecture](https://origintrail.io/technology/multichain)

### VeChain

- [VeChain Nodes](https://docs.vechain.org/core-concepts/nodes)
- [VeChainThor Consensus](https://docs.vechain.org/introduction-to-vechain/about-the-vechain-blockchain)
- [Running a VeChain Node](https://docs.vechain.org/how-to-run-a-node)
- [VeChain ToolChain Definition](https://cdn.vechain.com/Toolchain/VeChainWork/html/profile_cn.html)
- [VeChain Pro Service Terms](https://cdn.vechain.com/vechainthorwallet/docs/cn/protocol/vechainproprotocol.html)

