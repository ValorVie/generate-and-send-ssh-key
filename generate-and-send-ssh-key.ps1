<#
.SYNOPSIS
  �o�Ӹ}���i�H�bWindows�W���ͷs��SSH���_,�ñN���_�ǰe�컷�ݥD���W�C

.PARAMETER User
  ���ݥD�����ϥΪ̦W�١C�w�]�Ȭ����榹�}�����ϥΪ̦W�١C

.PARAMETER FileName
  �n���ͪ����_�ɮצW�١C�w�]�Ȭ�~/.ssh/id_test�C

.PARAMETER Host
  ���ݥD���W�٩�IP��}�C�w�]�Ȭ�"host"�C

.PARAMETER Port
  ���ݥD����SSH�𸹡C�w�]�Ȭ�22�C

.PARAMETER KeySize
  ���_�����סC�w�]�Ȭ�4096�C

.PARAMETER KeyType
  ���_�������C�w�]�Ȭ�"ed25519"�C

.PARAMETER Passphrase
  �]�w���_���K�X�u�y(Passphrase)�C�w�]���ťաC

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

# ���ͪ��_
if ($KeyType -eq "ed25519") {
        Write-Host "���b�� $($User)@$($DefaultHost) ���ͷs�� $($KeyType) ���_..."
        ssh-keygen -t $KeyType -f $FileName
} else {
        Write-Host "���b�� $($User)@$($DefaultHost) ���ͷs�� $($KeyType) ���_,���׬� $($KeySize) �줸..."
        ssh-keygen -t $KeyType -b $KeySize -f $FileName
}

if (-not (Test-Path $FileName)) {
  Write-Error "���_���ͥ���"
  return
}

# �]�w�v��
Write-Host "�]�w���_�ɮ��v��..."
$acl = Get-Acl $FileName
$acl.SetAccessRuleProtection($True, $False)
$administratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "None", "None", "Allow")
$acl.SetAccessRule($administratorsRule)
$currentUserRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERDOMAIN\$env:USERNAME", "ReadAndExecute", "None", "None", "Allow")
$acl.SetAccessRule($currentUserRule)
Set-Acl $FileName $acl

# �N���_�ǰe�컷�ݥD��
Write-Host "�N���_�ǰe��$($User)@$($DefaultHost):$($Port)..."
$pubKeyContent = Get-Content "$($FileName).pub"
$sesssionOptions = "-o PubkeyAuthentication=no"
$sshSessionCommand = "ssh $sesssionOptions -p $Port $User@$DefaultHost 'echo ""$pubKeyContent"" >> ~/.ssh/authorized_keys'"
Invoke-Expression $sshSessionCommand

Write-Host "�����]�w,�A�{�b�i�H�ϥΥH�U���O�s�u��$($DefaultHost):
ssh -p $Port -i $FileName $User@$DefaultHost
"