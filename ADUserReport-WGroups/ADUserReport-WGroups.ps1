<# 
 ADUserReport-WGroups.ps1
 Created by Kristopher Roy
 Created - 26Sept18
 Updated - 
#>

#create CSVDE report for baseline
CSVDE -F c:\belltech\ADExport.csv

#deffinition for UAC codes
$lookup = @{'4096'="Workstation/Server"; '4098'="Disabled Workstation/Server"; '4128'="Workstation/Server No PWD"; 
'4130'="Disabled Workstation/Server No PWD"; '528384'="Workstation/Server Trusted for Delegation";
'528416'="Workstation/Server Trusted for Delegation"; '532480'="Domain Controller"; '66176'="Workstation/Server PWD not Expire"; 
'66178'="Disabled Workstation/Server PWD not Expire";'512'="User Account";'514'="Disabled User Account";'66048'="User Account PWD Not Expire";'66050'="Disabled User Account PWD Not Expire"}

#Timestamp for Reference
$time = Get-Date

#clean up dates and ADGroups
$userlist = import-csv C:\BellTech\ADUSerlistUpdate.csv|where-object{$_.objectClass -eq "user"}|Select-Object -Property SamAccountName,givenName,sn,telephoneNumber,mobile,mail,userAccountControl,whenCreated,whenChanged,lastlogontimestamp,dayssincelogon,description,office,City,cn,DN,memberOf,badPasswordTime,pwdLastSet,LockedOut,accountExpires
FOREACH($user in $userlist)
{
    $ADU = $user.sAMAccountName|get-aduser
    $user.memberOf = [system.String]::Join(", ", (($ADU|Get-ADPrincipalGroupMembership|select name).name))
    IF($user.whenCreated -ne $NULL){$user.whenCreated = Try{Get-Date([DateTime]::ParseExact(($user.whenCreated).split(".")[0],"yyyyMMddHHmmss", [System.Globalization.CultureInfo]::InvariantCulture))-Format "M/d/yyyy hh:mm tt"}catch{}}
    IF($user.whenChanged -ne $NULL){$user.whenChanged = Try{Get-Date([DateTime]::ParseExact(($user.whenChanged).split(".")[0],"yyyyMMddHHmmss", [System.Globalization.CultureInfo]::InvariantCulture))-Format "M/d/yyyy hh:mm tt"}catch{}}
    IF($user.lastLogonTimestamp -ne $NULL){$user.lastLogonTimestamp = ([datetime]::fromfiletime($user.lastLogonTimestamp)|Get-Date -format "M/d/yyyy hh:mm tt")}
    IF($user.badPasswordTime -ne $NULL){$user.badPasswordTime = Try{get-date ([datetime]::FromFileTime($user.badPasswordTime)) -format "M/d/yyyy hh:mm tt"}catch{}}
    IF($user.pwdLastSet -ne $NULL){$user.pwdLastSet = ([datetime]::fromfiletime($user.pwdLastSet)|Get-Date -format "M/d/yyyy hh:mm tt")}
    IF($user.accountExpires -eq "9223372036854775807"){$user.accountExpires = "Never"}
    ELSE{try{$user.accountExpires = ([datetime]::fromfiletime($user.accountExpires)|Get-Date -format "M/d/yyyy hh:mm tt")}Catch{}}
    try{$user.dayssincelogon = (New-TimeSpan -start $user.lastLogonTimestamp -end $time).days}catch{$user.dayssincelogon = "Null"}
    $user.userAccountControl = $lookup[$user.userAccountControl] 
}