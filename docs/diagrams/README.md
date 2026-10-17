# C4 图源

`src/*.puml` 是 [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) 源文件，`../public/diagrams/*.svg` 是渲染产物，被 [上下文与部署](/architecture/c4-system)、[Core](/architecture/c4-core)、[Analytics](/architecture/c4-analytics) 与 [动态](/architecture/c4-dynamic) 引用。

**图内文字用英文**，因为这些图要直接进报告；页面说明用中文。

## 重新生成

```powershell
pwsh -File docs/diagrams/render.ps1
```

需要 Java 11+。`vendor/plantuml.jar` 不进版本库（28 MB），脚本会在缺失时自动下载；`vendor/C4_*.puml` 是小文件，随仓库保存以保证可复现。

## 约定

- 每张图一个 `.puml`，文件名决定 SVG 文件名。
- 用 smetana 布局（PlantUML 默认）。**不要**设 `GRAPHVIZ_DOT`：dot 的路由对这种稠密图更差，标签会叠在一起。
- 端口/协议写在 `Rel` 的技术参数上，不要塞进标签。

## 线型与间距

所有图共享 endor/style.puml，改一处即全部生效：

| skinparam linetype | 效果 | 什么时候用 |
|---|---|---|
| polyline（当前） | 直线段 + 折角，节点位置与曲线版一致 | 默认。密图里标签不会压到方框上 |
| ortho | 纯直角路由 | 稀疏图好看；但 context / container 这类密图上标签会穿进方框（实测过） |
| splines | 曲线（PlantUML 默认） | 不用 |

间距也在同一个文件里调，不需要逐张图改：

`
skinparam nodesep 25    ' 同一层节点间距
skinparam ranksep 30    ' 层间距
`

**为什么默认不是 ortho：** 直角更好看，但它会改变边进入节点的方式，标签因此更容易落在方框内部。context 图实测会把 "EPCIS events"、"Wrap / unwrap DEK" 压进参与者框里。polyline 保留了原有的节点布局，只把曲线换成折线——这就是"改线型不改布局"的取舍。
