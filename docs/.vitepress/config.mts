import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'zh-CN',
  title: 'Agricultural Supply Chain Tracker',
  description: '按系统边界组织的架构决策与端到端契约',
  cleanUrls: true,
  lastUpdated: true,
  markdown: {
    lineNumbers: true,
  },
  themeConfig: {
    nav: [
      { text: '系统地图', link: '/architecture/system-map' },
      { text: '系统视图', link: '/systems/traceability-core' },
      { text: '跨系统流程', link: '/flows/event-acceptance' },
      { text: '决策目录', link: '/decisions/catalog' },
      { text: '待定事项', link: '/decisions/open-items' },
    ],
    sidebar: {
      '/architecture/': [
        {
          text: '架构总览',
          items: [
            { text: '系统地图', link: '/architecture/system-map' },
            { text: '阅读方式', link: '/architecture/reading-guide' },
          ],
        },
      ],
      '/systems/': [
        {
          text: '系统视图',
          items: [
            { text: 'Traceability Core', link: '/systems/traceability-core' },
            { text: 'Trust & Recovery', link: '/systems/trust-recovery' },
            { text: 'Identity & Governance', link: '/systems/identity-governance' },
            { text: 'Data & Access', link: '/systems/data-access' },
            { text: 'IoT & Edge', link: '/systems/iot-edge' },
            { text: 'Regulatory Analytics', link: '/systems/regulatory-analytics' },
            { text: 'Query & Experience', link: '/systems/query-experience' },
            { text: 'Operations & Deployment', link: '/systems/operations-deployment' },
          ],
        },
      ],
      '/flows/': [
        {
          text: '跨系统流程',
          items: [
            { text: '事件接收与确认', link: '/flows/event-acceptance' },
            { text: '召回与监管调查', link: '/flows/recall-investigation' },
            { text: '平台失效与恢复', link: '/flows/platform-recovery' },
          ],
        },
      ],
      '/decisions/': [
        {
          text: '决策管理',
          items: [
            { text: '决策目录', link: '/decisions/catalog' },
            { text: '完整决策日志', link: '/decisions/log' },
            { text: '系统—决策矩阵', link: '/decisions/system-matrix' },
            { text: '待定事项', link: '/decisions/open-items' },
            { text: '待办清单', link: '/decisions/backlog' },
          ],
        },
      ],
    },
    search: {
      provider: 'local',
    },
    outline: {
      level: [2, 3],
      label: '本页目录',
    },
    docFooter: {
      prev: '上一页',
      next: '下一页',
    },
    lastUpdated: {
      text: '最后更新',
      formatOptions: {
        dateStyle: 'medium',
        timeStyle: 'short',
      },
    },
    returnToTopLabel: '返回顶部',
    sidebarMenuLabel: '目录',
    darkModeSwitchLabel: '主题',
  },
})
