<#
.SYNOPSIS
    把本包内置的 Chrome 扩展复制到固定目录，并打开 chrome://extensions 提示加载。

.DESCRIPTION
    本包把浏览器扩展放在内部的 extension/ 目录。直接从 node_modules 里加载虽然可以，
    但路径会随 profile 切换、pnpm 清理或重装而失效，Chrome 里那个已加载的扩展就会
    变成"已损坏"。所以推荐先复制到一个稳定目录（默认 ~/.dsh/browser-extension，
    与上游安装器一致），再从那里加载。

    脚本只做三件事：
      1. 把 extension/ 复制到目标目录（目标已存在则先改名为 .bak-<时间戳> 备份）
      2. 打印扩展版本与目标路径
      3. 尝试打开 chrome://extensions（失败也不影响，手动打开即可）

.PARAMETER Target
    扩展的固定存放目录。默认 `$HOME\.dsh\browser-extension`。

.PARAMETER NoOpen
    不尝试打开 chrome://extensions。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\setup-extension.ps1
#>
[CmdletBinding()]
param(
    [string]$Target = '',
    [switch]$NoOpen
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$t) { Write-Host "==> $t" -ForegroundColor Cyan }
function Write-Ok([string]$t) { Write-Host "    OK   $t" -ForegroundColor Green }
function Write-Warn2([string]$t) { Write-Host "    WARN $t" -ForegroundColor Yellow }
function Fail([string]$t) { Write-Host "    FAIL $t" -ForegroundColor Red; exit 1 }

# --- 定位包内的 extension/ ---------------------------------------------------
$packageRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $packageRoot 'extension'
if (-not (Test-Path -LiteralPath (Join-Path $source 'manifest.json'))) {
    # 兼容：从 tgz 解压出来后直接运行（package/scripts → package/extension）
    $alt = Join-Path (Split-Path -Parent $packageRoot) 'extension'
    if (Test-Path -LiteralPath (Join-Path $alt 'manifest.json')) { $source = $alt }
    else { Fail "找不到扩展目录（期望 $source\manifest.json）。请在解压后的包根目录下运行本脚本。" }
}
$manifest = Get-Content -LiteralPath (Join-Path $source 'manifest.json') -Raw | ConvertFrom-Json
Write-Step '找到内置扩展'
Write-Ok "来源   : $source"
Write-Ok "版本   : $($manifest.version)  (MV$($manifest.manifest_version))"

# --- 目标目录 ----------------------------------------------------------------
if ($Target -eq '') { $Target = Join-Path $HOME '.dsh\browser-extension' }
Write-Step "复制到固定目录：$Target"

if (Test-Path -LiteralPath $Target) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$Target.bak-$stamp"
    Move-Item -LiteralPath $Target -Destination $backup
    Write-Warn2 "已存在，旧版本备份为 $backup"
}

$parent = Split-Path -Parent $Target
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
Copy-Item -LiteralPath $source -Destination $Target -Recurse -Force
if (-not (Test-Path -LiteralPath (Join-Path $Target 'manifest.json'))) { Fail '复制后未找到 manifest.json' }
Write-Ok "已就位 : $Target"

# --- 打开 chrome://extensions ------------------------------------------------
$chrome = $null
foreach ($key in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')) {
    if (Test-Path $key) {
        $value = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'(default)'
        if ($value -and (Test-Path -LiteralPath $value)) { $chrome = $value; break }
    }
}
if (-not $NoOpen) {
    if ($chrome) {
        try { Start-Process -FilePath $chrome -ArgumentList 'chrome://extensions'; Write-Ok '已尝试打开 chrome://extensions' }
        catch { Write-Warn2 "无法自动打开浏览器：$($_.Exception.Message)" }
    } else {
        Write-Warn2 '未找到 chrome.exe，请手动打开 chrome://extensions'
    }
}

# --- 后续步骤 ----------------------------------------------------------------
Write-Host ''
Write-Host '接下来（只需一次）：' -ForegroundColor Cyan
Write-Host '  1. 在 chrome://extensions 右上角打开「开发者模式」'
Write-Host '  2. 点「加载已解压的扩展程序」'
Write-Host "  3. 选择目录：$Target"
Write-Host '  4. 打开任意网页 → 点工具栏的 DeepSeek 图标 → 侧边栏显示「已连接」'
Write-Host ''
Write-Host '桥接地址留空即可：本包已把 19387（桌面端）加进扩展的自动探测端口。' -ForegroundColor DarkGray
Write-Host '更新插件后请重新运行本脚本并点击扩展卡片上的「重新加载」。' -ForegroundColor DarkGray
