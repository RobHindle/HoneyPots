# Honey Pot Monitor Control

<#  Disclaimer
Author:  Robert Hindle May 12th 2021
USE AT YOUR OWN RISK.  Check the HashChecks.  Adjust to your own needs
#>

<# Assumptions - Positionings
  FormActionNotice.ps1 and HoneyPotAccessDetect.ps1 in a folder -Read & Execute needed
  HoneyPotMonitorControl.ps1 in same folder - Read & Execute needed
  HPADocSets.txt  HPCDocSets.txt in same folder    - Read needed by process
  HPNamesADM.txt HPNamesOrg.txt in same folder     - Read needed by process
  HPYears.txt in same folder                       - Read needed by process
  HPNamesOrg-Run.txt and HPYears-Run.txt in same folder modified from above manually
  HPsmtpConfig.txt and Mailcred.txt in same folder -Read Neededd by process
  Subfolder Results exists          - create, read, write needed by process

  Once a Day ScheduledTask set up as ...
  %systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe 
  Attributes of ...
  -executionpolicy Bypass -Windowstyle Hidden -file "<yourPath>\HoneyP{otMonitorControl.ps1"
#>
<#
This can be always be a HEARTBEAT or PERIODCHECK with/Without Random 
Args[0] is ManifestPath
Args[1] is target of results (default is .\results\HPMonitor<DtTm>.txt)
Args[2] is HEARTBEAT, PERIODCHECK or RANDOM
   It only sends a PeriodCheck or Random Email if there is content generated.
#>

# Common Functions for Notification and 
. "$PSScriptRoot\FormActionNotice.ps1"

# Functions to assess the HoneyPots
 . "$PSScriptRoot\HoneyPotAccessDetect.ps1"

$tdy = Get-Date -Format "yyyyMMddHHmm"
$HPMout = "$PSScriptRoot\Results\HPMonitor$tdy.txt"

if ($args[0].length -le 0) { Check-Pots >> $HPMout }
else { 
   if ($args[1].length -le 0) { Check-Pots -ManifestPath $args[0] >> $HPMout }
   else {
         $HPMout = $args[1]
         Check-Pots -ManifestPath $args[0] >> $HPMout 
      } # Manifest set
   } # Output set

if ($Args[2].length -le 0) { $Args[2] = "PERIODCHECK" }

$HPC = Get-item -Path $HPMout

if (($($Args[2]) -eq "HEARTBEAT") -or ($($HPC.length) -gt 0)) {
  $Mach = [environment]::MachineName
  $SubjectText = "Honey Pot $($Args[2]) on $Mach at $tdy"
  $AArray = @("$HPMout")
  $NoticeConfig = "$PSScriptRoot\HPSMTPConfig.txt"
  $SMTPCred = "$PSScriptRoot\MailCred.txt"
  Send-ResultsNotice -Subject -ActionArray $AArray -NoticeConfig $NoticeConfig -SMTPCred $SMTPCred
  }