<#
.SYNOPSIS
  �o�Ӹ}���i�H�bWindows�W���ͷs��SSH���_,�ñN���_�ǰe�컷�ݥD���W�C

.PARAMETER user
  ���ݥD�����ϥΪ̦W�١C

.PARAMETER userfilename
  �n���ͪ����_�ɮצW�١A��ĳ�ϥΥؼЪ��O�١C

.PARAMETER windowshost
  ���ݥD���W�٩�IP��}�C

.PARAMETER port
  ���ݥD����SSH�𸹡C�w�]�Ȭ�22�C

.PARAMETER keysize
  ���_�����סC�w�]�Ȭ�4096�C

.PARAMETER keytype
  ���_�������C�w�]�Ȭ�"ed25519"�C

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

# ���ͪ��_
if ($keytype -eq "ed25519") {
        Write-Host "���b�� $($user)@$($windowshost) ���ͷs�� $($keytype) ���_..."
        ssh-keygen -t $keytype -f $FileName
} else {
        Write-Host "���b�� $($user)@$($windowshost) ���ͷs�� $($keytype) ���_,���׬� $($keysize) �줸..."
        ssh-keygen -t $keytype -b $keysize -f $FileName
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
Write-Host "�N���_�ǰe��$($user)@$($windowshost):$($port)..."
$pubKeyContent = Get-Content "$($FileName).pub"
$sessionOptions = "-o PubkeyAuthentication=no"
$sshSessionCommand = "ssh $sessionOptions -p $port $user@$windowshost 'echo ""$pubKeyContent"" >> ~/.ssh/authorized_keys'"
Invoke-Expression $sshSessionCommand

# �վ㻷�ݥD���v��
Write-Host "�վ��v���H�קKssh-daemon�������~�A�o�i��ݭn�A����J�K�X�C"
$permissionOptions = "chmod go-w ~ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
$sshSessionCommand = "ssh $sessionOptions -p $port $user@$windowshost '""$permissionOptions""'"
Invoke-Expression $sshSessionCommand

Write-Host "�����]�w,�A�{�b�i�H�ϥΥH�U���O�s�u��$($windowshost):
ssh -p $port -i $FileName $user@$windowshost
"