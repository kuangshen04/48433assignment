# C4 图源

`src/*.puml` 是 [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) 源文件，`../public/diagrams/*.svg` 是渲染产物，被 [C4 视图 · Core](/architecture/c4-core)、[C4 视图 · Analytics](/architecture/c4-analytics) 与 [C4 视图 · 动态](/architecture/c4-dynamic) 引用。

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
