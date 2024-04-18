<#
.SYNOPSIS
  這個腳本可以在Windows上產生新的SSH金鑰,並將公鑰傳送到遠端主機上。

.PARAMETER user
  遠端主機的使用者名稱。

.PARAMETER userfilename
  要產生的金鑰檔案名稱，建議使用目標的別稱。

.PARAMETER windowshost
  遠端主機名稱或IP位址。

.PARAMETER port
  遠端主機的SSH埠號。預設值為22。

.PARAMETER keysize
  金鑰的長度。預設值為4096。

.PARAMETER keytype
  金鑰的類型。預設值為"ed25519"。

.EXAMPLE
  .\Create-SSHKey.ps1 -host myserver.com -user myusername

.EXAMPLE 
  .\Create-SSHKey.ps1 -userfilename id_testmachine -keytype rsa
#>

param(
    [string]$user = (Read-Host -Prompt "Enter Remote UserName"),
    [string]$userfilename = (Read-Host -Prompt "Enter SSH FileName (id_[SSH FileName])"),
    [string]$windowshost = (Read-Host -Prompt "Enter Host"),
    [int]$port = 22,
    [int]$keysize = 4096,
    [string]$keytype = "ed25519"
)

[string]$FileName = $env:UserProfile + "\.ssh\$userfilename"

# 產生金鑰
if ($keytype -eq "ed25519") {
        Write-Host "正在為 $($user)@$($windowshost) 產生新的 $($keytype) 金鑰..."
        ssh-keygen -t $keytype -f $FileName
} else {
        Write-Host "正在為 $($user)@$($windowshost) 產生新的 $($keytype) 金鑰,長度為 $($keysize) 位元..."
        ssh-keygen -t $keytype -b $keysize -f $FileName
}

if (-not (Test-Path $FileName)) {
  Write-Error "金鑰產生失敗"
  return
}

# 設定權限
Write-Host "設定金鑰檔案權限..."
$acl = Get-Acl $FileName
$acl.SetAccessRuleProtection($True, $False)
$administratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "None", "None", "Allow")
$acl.SetAccessRule($administratorsRule)
$currentUserRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERDOMAIN\$env:USERNAME", "ReadAndExecute", "None", "None", "Allow")
$acl.SetAccessRule($currentUserRule)
Set-Acl $FileName $acl

# 將公鑰傳送到遠端主機
Write-Host "將公鑰傳送到$($user)@$($windowshost):$($port)..."
$pubKeyContent = Get-Content "$($FileName).pub"
$sessionOptions = "-o PubkeyAuthentication=no"
$sshSessionCommand = "ssh $sessionOptions -p $port $user@$windowshost 'echo ""$pubKeyContent"" >> ~/.ssh/authorized_keys'"
Invoke-Expression $sshSessionCommand

# 調整遠端主機權限
Write-Host "調整權限以避免ssh-daemon中的錯誤，這可能需要再次輸入密碼。"
$permissionOptions = "chmod go-w ~ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
$sshSessionCommand = "ssh $sessionOptions -p $port $user@$windowshost '""$permissionOptions""'"
Invoke-Expression $sshSessionCommand

Write-Host "完成設定,你現在可以使用以下指令連線至$($windowshost):
ssh -p $port -i $FileName $user@$windowshost
"