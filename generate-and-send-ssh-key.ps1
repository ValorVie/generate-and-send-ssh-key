<#
.SYNOPSIS
  這個腳本可以在Windows上產生新的SSH金鑰,並將公鑰傳送到遠端主機上。

.PARAMETER User
  遠端主機的使用者名稱。預設值為執行此腳本的使用者名稱。

.PARAMETER FileName
  要產生的金鑰檔案名稱。預設值為~/.ssh/id_test。

.PARAMETER Host
  遠端主機名稱或IP位址。預設值為"host"。

.PARAMETER Port
  遠端主機的SSH埠號。預設值為22。

.PARAMETER KeySize
  金鑰的長度。預設值為4096。

.PARAMETER KeyType
  金鑰的類型。預設值為"ed25519"。

.PARAMETER Passphrase
  設定金鑰的密碼短語(Passphrase)。預設為空白。

.EXAMPLE
  .\Create-SSHKey.ps1 -Host myserver.com -User myusername

.EXAMPLE 
  .\Create-SSHKey.ps1 -FileName C:\Users\myuser\.ssh\id_rsa -KeyType rsa -Passphrase mypassphrase123
#>

param(
    [string]$User = (Read-Host -Prompt "Enter Remote UserName"),
    [string]$userFileName = (Read-Host -Prompt "Enter SSH FileName (id_[test])"),
    [string]$DefaultHost = (Read-Host -Prompt "Enter Host"),
    [int]$Port = 22,
    [int]$KeySize = 4096,
    [string]$KeyType = "ed25519"
)

[string]$FileName = $env:UserProfile + "\.ssh\$userFileName"

# 產生金鑰
if ($KeyType -eq "ed25519") {
        Write-Host "正在為 $($User)@$($DefaultHost) 產生新的 $($KeyType) 金鑰..."
        ssh-keygen -t $KeyType -f $FileName
} else {
        Write-Host "正在為 $($User)@$($DefaultHost) 產生新的 $($KeyType) 金鑰,長度為 $($KeySize) 位元..."
        ssh-keygen -t $KeyType -b $KeySize -f $FileName
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
Write-Host "將公鑰傳送到$($User)@$($DefaultHost):$($Port)..."
$pubKeyContent = Get-Content "$($FileName).pub"
$sesssionOptions = "-o PubkeyAuthentication=no"
$sshSessionCommand = "ssh $sesssionOptions -p $Port $User@$DefaultHost 'echo ""$pubKeyContent"" >> ~/.ssh/authorized_keys'"
Invoke-Expression $sshSessionCommand

Write-Host "完成設定,你現在可以使用以下指令連線至$($DefaultHost):
ssh -p $Port -i $FileName $User@$DefaultHost
"