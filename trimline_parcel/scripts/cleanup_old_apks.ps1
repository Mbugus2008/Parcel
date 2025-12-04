# Cleanup old APK versions - keeps last 5
$apkPath = "D:\apps\Parcel"
$pattern = "trimline_parcel_*.apk"

Get-ChildItem -Path $apkPath -Filter $pattern | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip 5 | 
    ForEach-Object { 
        Write-Host "Deleting old version: $($_.Name)"
        Remove-Item $_.FullName -Force 
    }

Write-Host "Cleanup complete. Remaining versions:"
Get-ChildItem -Path $apkPath -Filter $pattern | Sort-Object LastWriteTime -Descending | Select-Object Name
