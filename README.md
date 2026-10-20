# dsh-bridge-browser

> 让 dsh（DeepSeek Harness）直接操作**你正在用的 Chrome 标签页**：读取页面、点击、填表、导航、管理标签页，同时保留你的登录态、会话与 Cookie。

[![npm](https://img.shields.io/npm/v/@shallbay/dsh-bridge-browser.svg)](https://www.npmjs.com/package/@shallbay/dsh-bridge-browser)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 这是什么

本仓库是 dsh 的**浏览器桥插件**源码，npm 包名为 [`@shallbay/dsh-bridge-browser`](https://www.npmjs.com/package/@shallbay/dsh-bridge-browser)。

它是 [`@yuxianglin/dsh-bridge-browser`](https://github.com/Lum1104/dsh-browser)（作者 Yuxiang Lin）的**再打包版**：运行时逻辑来自上游，本仓库只维护"让它能从 npm 安装、并能在 dsh Desktop 0.2.x 上跑起来"所需的差异（详见 [NOTICE.md](NOTICE.md)）。

浏览器侧是一个随 npm 包分发的 **Chrome MV3 扩展**（构建产物，不在本仓库内）。

## 能力

| 工具 | 作用 |
|---|---|
| `browser_snapshot` | 结构化文本快照：标题 / URL / 正文 / 带编号的交互元素 / 表单字段 |
| `browser_click` | 按编号点击链接、按钮、复选框等 |
| `browser_type` | 输入文本（兼容 React/Vue 受控组件），`replace` 可清空重填 |
| `browser_press` | 按键（Enter / Tab / Escape / 方向键…） |
| `browser_scroll` | 视口滚动（up / down / top / bottom） |
| `browser_navigate` / `browser_open_tab` / `browser_back` / `browser_forward` / `browser_reload` | 导航 |
| `browser_list_tabs` / `browser_follow_tab` / `browser_close_tab` | 标签页枚举与绑定 |
| `browser_get_text` | 读取局部文本 / 懒加载内容 |
| `browser_wait` | 等待页面加载与渲染稳定 |

页面以**纯文本**呈现（不截图），模型靠编号定位元素；密码与支付卡字段始终显示为 `••••`，其值不会离开页面。

## 安装

前提：已安装 dsh。桌面端请**先启动过一次**（这样 `profiles/desktop` 才会被初始化）。

```powershell
# 桌面端
dsh plugin --profile desktop add @shallbay/dsh-bridge-browser

# 或 web / CLI 端
dsh plugin --profile web add @shallbay/dsh-bridge-browser
```

装完**重启桌面端**（菜单 `Restart App and Host`）。

### 卸载

```powershell
# 桌面端
dsh plugin --profile desktop remove @shallbay/dsh-bridge-browser

# 或 web / CLI 端
dsh plugin --profile web remove @shallbay/dsh-bridge-browser
```

卸载后建议顺带清理：

- 残留目录 `~/.dsh/profiles/<profile>/node_modules/@shallbay/dsh-bridge-browser`
- 浏览器里已加载的扩展：`chrome://extensions` → 该扩展 → **移除**
- 如果之前手动加过端口固定 / 兼容豁免，按需从 `cordis.patch.yml` / `compatibility.json` 里删掉

### 加载浏览器扩展（必做一次）

扩展随 npm 包发布在 `extension/` 目录，包内附带一键脚本：

```powershell
$pkg = Join-Path $HOME '.dsh\profiles\desktop\node_modules\@shallbay\dsh-bridge-browser'
powershell -ExecutionPolicy Bypass -File "$pkg\scripts\setup-extension.ps1"
```

脚本会把扩展复制到 `%USERPROFILE%\.dsh\browser-extension`（旧版自动备份）并尝试打开 `chrome://extensions`。
然后：**开发者模式 → 加载已解压的扩展程序 → 选择该目录**。

> 不要直接从 `node_modules` 里加载：那个路径会随 profile 切换 / 依赖重装而变化，Chrome 里的扩展会变成"已损坏"。

### 把桌面端口固定下来

DSH Desktop **0.2.1 起**用 `--port 0` 启动，端口每次随机分配，浏览器扩展无法自动发现。在 profile 的 `cordis.patch.yml` 里追加：

```yaml
- id: webserver
  name: "@deepseek-ai/dsh-host-webserver"
  config:
    host: '127.0.0.1'
    port: 19387
```

本包附带的扩展把 `19387` 加进了自动探测端口，所以**扩展里的"桥接地址"留空即可**。

> 每次触发"禁用第三方插件"恢复流程都会重写该 patch，恢复后需要重新加回这段。

## 从源码构建

需要 **Node `^22.19` 或 `>=24`**（`tsdown` 依赖现代 Node 内建模块）。

```powershell
npm install
npm run build        # 产物在 lib/
```

> `lib/` 与 `extension/` 都是构建产物，已被 `.gitignore` 排除。本仓库不含扩展源码——扩展来自上游仓库的 `extensions/dsh-browser`，随 npm 包发布。

## 与上游的差异

1. **包标识**：改为 `@shallbay/dsh-bridge-browser` 并去掉 `private`，使 `dsh plugin add` 能从 registry 解析。
2. **peerDependencies 放宽** 到 `>=0.1.7-rc.2 <0.3.0`。dsh 的兼容闸门会校验插件声明的 `@deepseek-ai/dsh*` peer，上游的 `^0.1.x-rc.n` 会被 0.2.x 直接拒绝。
3. **适配 DSH 0.2.1 的 Peer 校验**：0.2.1 的 Gateway 对 `wireStream.open` 和 unary `invoke` 都要求传入 Peer（`peer.signal`、`peer.interactions === 'answer'`）。本包用 `connection.createPeer({ principal: { kind: 'owner' } })` 铸造一个 in-process Peer 并透传，避免 `Cannot read properties of undefined (reading 'signal')`。
4. **客户端 bundle 的插件 id** 同步为包名，避免 `client-modules: duplicate factory registration` 导致 web boot 失败。
5. **扩展自动探测 `19387`**（桌面端端口），并随 npm 包一起分发。

## 版本记录

| 版本 | 说明 |
|---|---|
| 1.0.0 | 首个 npm 版本 |
| 1.0.1 | 修正客户端 bundle 的插件 id（重复注册导致 web boot 失败） |
| 1.0.2 | 基于上游 main 适配 DSH 0.2.x；修复 wire stream 的 peer 校验 |
| 1.0.3 | 回归修复：客户端 id（1.0.2 重新构建时被覆盖） |
| 1.0.4 | 补齐 unary `invoke` 的 peer —— 修复 `session.list` / `settings.describe` 报 `Cannot read properties of undefined` |

## 已知限制

- 桥只接受**一个**活动扩展连接；桌面端与 `dsh web` 不能同时运行。
- 点击、输入、导航等写操作默认需要在浏览器侧边栏确认；页面读取按需进行。
- Chrome 需 116+；Firefox 需 140+ 且必须手动填写 `~/.dsh/ext-bridge-token`（`moz-extension://` 的 UUID 每次安装都不同，无法零配置）。
- 受保护页面（扩展商店、`chrome://` 等）只能读取标签页元数据，不能操作 DOM。

## 许可与归属

- 许可证：**MIT**，见 [LICENSE](LICENSE)。
- 上游项目：[Lum1104/dsh-browser](https://github.com/Lum1104/dsh-browser)，作者 **Yuxiang Lin**。
- 本仓库为再打包，运行时逻辑版权归上游作者所有；改动清单见 [NOTICE.md](NOTICE.md)。

## 目录结构

```
src/                TypeScript 源码（插件、协议、工具、远程 Host 适配）
scripts/            setup-extension.ps1（复制扩展并打开 chrome://extensions）
cordis.patch.yml    插件 bundle patch（注册 bridge-browser 行）
tsconfig.json       TS 配置
tsdown.config.ts    打包配置
NOTICE.md           上游归属与改动清单
```
