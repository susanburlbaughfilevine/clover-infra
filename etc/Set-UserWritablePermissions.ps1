function Set-UserWritablePermissions
{
    [cmdletbinding()]
    Param
    (
        [string]$filepath,
        [string]$user = "Users",
        [string]$Rights = "Write, Read, ReadAndExecute",
        [string]$PropogationSettings = "None",
        [string]$RuleType = "Allow" 
    )

    $acl = Get-Acl $filepath
    $perm = $user, $Rights, $RuleType
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
    $acl.SetAccessRule($rule)
    $acl | Set-Acl -Path $filepath
}