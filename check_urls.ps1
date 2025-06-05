# 从 urls.txt 导入 URL（每行一个 URL）
$urls = Get-Content -Path ".\urls.txt"

$failedUrls = @()

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -ne 200) {
            $msg = "$url responded with status code $($response.StatusCode)"
            $failedUrls += $msg
        }
    } catch {
        $msg = "$url"
        $failedUrls += $msg
    }
}

# 获取脚本所在目录，保存失败的 URL 到 result.txt
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$resultPath = Join-Path $scriptDir "result.txt"
$failedUrls | Out-File -Encoding UTF8 -FilePath $resultPath
