# 记录开始时间
$startTime = Get-Date

# 设置控制台窗口大小（安全自适应）
try {
    $rawui = $Host.UI.RawUI
    $maxSize = $rawui.MaxPhysicalWindowSize
    $bufferSize = $rawui.BufferSize

    # 设置缓冲区宽度至少为我们将要设置的窗口宽度
    $targetWidth = [Math]::Min(45, $maxSize.Width)
    $targetHeight = [Math]::Min(55, $maxSize.Height)

    # 先设置缓冲区（必须先设置）
    if ($bufferSize.Width -lt $targetWidth) {
        $bufferSize.Width = $targetWidth
        $rawui.BufferSize = $bufferSize
    }

    # 设置窗口尺寸
    $rawui.WindowSize = New-Object System.Management.Automation.Host.Size($targetWidth, $targetHeight)

    # 设置缓冲区高度（大于窗口高度以便滚动）
    $bufferSize.Height = $targetHeight + 100
    $rawui.BufferSize = $bufferSize
} catch {
    Write-Host "无法设置窗口尺寸，跳过。" -ForegroundColor Yellow
}

# 读取网址列表
$urls = Get-Content .\urls.txt | ForEach-Object { $_.Trim() } | Where-Object { $_ -match 'https?://' }

# 设置最大线程数
$maxThreads = 20

# 清空结果文件
New-Item -Path 响应成功.txt -ItemType File -Force | Out-Null
New-Item -Path 响应失败.txt -ItemType File -Force | Out-Null

# 创建线程池
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads)
$runspacePool.Open()

$runspaces = @()

foreach ($url in $urls) {
    Write-Host "开始检测：" $url
    $ps = [powershell]::Create()
    $ps.RunspacePool = $runspacePool

    $null = $ps.AddScript({
        param($u)
        try {
            $resp = Invoke-WebRequest -Uri $u -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            if ($resp.StatusCode -eq 200) {
                return @{url = $u; success = $true}
            } else {
                return @{url = $u; success = $false}
            }
        } catch {
            return @{url = $u; success = $false}
        }
    }).AddArgument($url)

    $async = $ps.BeginInvoke()
    $runspaces += [PSCustomObject]@{
        Pipe = $ps
        Async = $async
    }
}

# 检查并获取所有结果
while ($runspaces.Count -gt 0) {
    foreach ($r in @($runspaces)) {
        if ($r.Pipe.EndInvoke($r.Async)) {
            $result = $r.Pipe.EndInvoke($r.Async)
            $r.Pipe.Dispose()
            $runspaces = $runspaces | Where-Object { $_ -ne $r }

            if ($result.success) {
                Write-Host "检测成功：" $result.url -ForegroundColor Green
                $result.url | Out-File -FilePath 响应成功.txt -Encoding utf8 -Append
            } else {
                Write-Host "检测失败：" $result.url -ForegroundColor Red
                $result.url | Out-File -FilePath 响应失败.txt -Encoding utf8 -Append
            }
        }
    }
    Start-Sleep -Milliseconds 200
}

# 清理线程池
$runspacePool.Close()
$runspacePool.Dispose()

# 记录结束时间
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n检测完毕！成功 $((Get-Content 响应成功.txt).Count) 个，失败 $((Get-Content 响应失败.txt).Count) 个。" -ForegroundColor Cyan
Write-Host ("总用时: {0:N2} 秒" -f $duration.TotalSeconds) -ForegroundColor Cyan

Read-Host "按回车键退出"
