$mirror_url = "https://mirrors.nju.edu.cn"
$ubuntu_version = "jammy"
Write-Host "    Ubuntu构建脚本 by WSLab"
Write-Host "-- Dist: $ubuntu_version"

$build_dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "-- Build Dir: $build_dir"

# Download rootfs
$dl_url = "$mirror_url/ubuntu-cloud-images/wsl/$ubuntu_version/current/ubuntu-$ubuntu_version-wsl-amd64-ubuntu.rootfs.tar.gz"
$dl_target = "$build_dir\linux.wsl.tar.gz"
if (Test-Path $dl_target) {
    # 文件存在，询问用户是否跳过下载
    $skipDownload = Read-Host ">> linux.wsl.tar.gz 镜像文件已存在，是否跳过下载？ (y/n)"

    if ($skipDownload -eq 'y' -or $skipDownload -eq 'Y') {
        Write-Host "-- 跳过下载官方wsl镜像文件"
    } else {
        Write-Output "-- 下载官方wsl镜像文件"
        Invoke-WebRequest -Uri $dl_url -OutFile $dl_target -ErrorAction Stop
        Write-Host "-- linux.wsl.tar.gz 文件下载成功"
    }
} else {
    Write-Output "-- 下载官方wsl镜像文件"
    Invoke-WebRequest -Uri $dl_url -OutFile $dl_target -ErrorAction Stop
    Write-Host "-- linux.wsl.tar.gz 文件下载成功"
}

# Import
$wsl_dist = "wslab-build-$ubuntu_version"
# 检测是否存在 test_build 发行版
$wslList = wsl -l -q
if ($wslList -contains "$wsl_dist") {
    # 存在 test_build 发行版，执行注销操作
    try {
        wsl --unregister $wsl_dist -ErrorAction Stop
        Write-Host "-- 删除旧的实例 $wsl_dist"
    } catch {
        Write-Host "-- 删除 $wsl_dist 发行版失败: $($_.Exception.Message)"
    }
}
Write-Host "-- 准备新的构建实例"
try {
    wsl --import $wsl_dist $build_dir $dl_target --version 2
} catch {
    Write-Host "-- WSL 导入失败：$($_.Exception.Message)"
}

# Copy sh Files into wsl
$wslRoot = "\\wsl$\$wsl_dist"
wsl -d $wsl_dist -e mkdir -- /wslab
$wslabDir = "$wslRoot\wslab"
$shFiles = Get-ChildItem -Path $build_dir -Filter *.sh
foreach ($file in $shFiles) {
    $destinationPath = Join-Path $wslabDir $file.Name
    Copy-Item -Path $file.FullName -Destination $destinationPath -Force
    Write-Host "-- 复制 $($file.Name) -> $destinationPath"
}
Copy-Item -Path "$build_dir\toolbox" -Destination "\\wsl$\$wsl_dist\" -Recurse

# call init.sh
wsl -d $wsl_dist -u root --shell-type standard --cd /wslab -e sh -- ./init.sh
# locale
Write-Host "-- WSL 强制关机，3s后重启"
wsl -t $wsl_dist
Start-Sleep -Seconds 3
Write-Output "-- WSL 设置本地化：中文简体"
wsl -d $wsl_dist -u root --shell-type standard -e localectl -- set-locale zh_CN.utf-8
wsl -d $wsl_dist -e fastfetch
Write-Output "-- WSL 强制关机，3s后重启"
wsl -t $wsl_dist
Start-Sleep -Seconds 3
Write-Host "-- WSL 导出构建镜像"
wsl --export $wsl_dist "Ubuntu-$ubuntu_version-wslab-build.wsl.tar"
Write-Host "-- 删除 WSL $wsl_dist"
wsl --unregister $wsl_dist
Write-Host "-- 7z压缩构建镜像"
7z a -tgzip "Ubuntu-$ubuntu_version-wslab-build.wsl.tar.gz" "Ubuntu-$ubuntu_version-wslab-build.wsl.tar"
if (Test-Path "Ubuntu-$ubuntu_version-wslab-build.wsl.tar") {
    Remove-Item "Ubuntu-$ubuntu_version-wslab-build.wsl.tar"
}