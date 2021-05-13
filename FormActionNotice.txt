# Handling the Results files of Manifested checks
# File, screen or Both
# Action Only Results or All Results
# Send Notice via SMTP
#
<#  Disclaimer
Author:  Robert Hindle May 12th 2021
USE AT YOUR OWN RISK.  Check the HashChecks.  Adjust to your own needs
#>

<# Present-Results
.Synopsis
    Dumps the contents of a Result file if the media form is to screen or both file and screen
.Description
    Dumps the contents of a Result file if the media form is to screen or both file and screen
.Parameter
    Media - One of Screen, Both or File(default) for present the results from a file
.Parameter
    ResultPath - Resolvable Result File Name
.Example
  Present-Results -Media Screen -ResultPath c:\scriptpath\Results\Events202102111643.csv
#>
Function Present-Results { 
   Param ($Media = "File",
          $ResultPath)
   if ($Media -eq "File") { }
   elseif (($Media -eq "Screen") -or ($Media -eq "Both")) {
      Get-Content -Path $ResultPath
   }
   else {" Media Choice not recognized "}
} # Func Present-Results

<# Generate-ActionResultsArray
.Synopsis
    It builds the Action Results array of attached files for a Notice Array
.Description
    Builds an Action Array of file paths from input arrays. 
    Heartbeats are moved straight through.
    PeriodChecks are evaluated for unexpected results and an action file and action array entry prepared.
    ResultArray, ManifestArray and StyleArray should size and activity match 
.Parameter
    ResultArray - Array of resolvable file names of results from a check
.Parameter
    ManifestArray - Array of resolvable file names of Manifests driving a check
.Parameter
    StyleArray - Array of Style names of a manifested check (Heartbeat, Periodcheck, functions)
.Example
  $AA = Generate-ActionResultsArray -ResultsArray $RArray - ManifestArray $MArray -StyleArray $SArray
#>
Function Generate-ActionResultsArray{
   Param ($ResultArray,
          $ManifestArray,
          $StyleArray)
   $ActionArray =@()
   $Tdy = Get-Date -Format "yyyyMMddHHmm"
   $Mach = [environment]::MachineName
   For ($i =0; $i -lt $StyleArray.count; $i +=1) {
      if ($Style -eq "HEARTBEAT") {
         $ActionArray += $ResultArray[$i]
      }
      elseif ($Style -eq "PERIODCHECK") {
         $ResultContents   = Import-CSV -Delimiter "," -Path "$($ResultArray[$i])"
         $ManifestContents = Import-CSV -Delimiter "," -Path "$($ManifestArray[$i])"
         $ActionContents = @()
         for ($j = 0; $j -lt $ResultContents.length ; $j +=1) {
           if ($($ResultContents[$j].Result) -eq $($manifestcontents[$j].Expect)) {
           } # Expectations Met
           else {
             $ActionContents =+ $ResultContents[$j]
           } # Expectations Not Met
         } # For j on Results
         if ($ActionContents.length -gt 0) {
           $ActionTarget = "$PSScriptRoot\Results\Actn$Mach$Tdy.csv"
           $ECSV = Export-CSV -InputObject $ActionContents -Path $ActionTarget -Delimiter "," -Append -Encoding UTF8
           $ActionArray += $ActionTarget
         } # we found some states that did not meet expectations
      }
      else { "Should Not be Here"
      } # should not get here
   } # For i on Style
   $ActionArray
} #Func Generate Action Results

<# Send-ResultsNotice
.Synopsis
   Prepares an SMTP email with attachments of the Results from a Manifested Review
.Description
   Prepares an SMTP email with attachments of the Results from a Manifested Review
.Parameter
   Subject (Default Monitoring) Lead text of Subject within Emails
.Parameter
   ActionArray - Array of resolvable file names to be attached in Notice
.Parameter
  NoticeConfig - SMTP config file for To, CC, From, Server, Port info for SMTP
.Parameter
  SMTPCred -resolved path to a CMS cred file for SMTP access
.Example
  Send-ResultsNotice -ActionArray $AArray -NoticeConfig c:\scriptpath\NoticeConfig.csv -SMTPCred c:\scriptpath\UserSMTPcred.txt
#>
Function Send-ResultsNotice {
  Param ($ActionArray,
         $Subject = "Monitoring",
         $NoticeConfig,
         $SMTPCred)
         $tdy = Get-Date -format "yyyMMdd-HHmm"
         $Mach = [environment]::MachineName
  if ($actionArray -eq @()) { }
  else {
   $ICSV = Import-Csv -Delimiter "," -Path "$PSScriptRoot\$NoticeConfig" 

   $PSEmailServer = $ICSV.Server 
   $EmailID  = $ICSV.EmailID 
   $ToList   = $ICSV.To  
   $FromList = $ICSV.From
   $CCList   = $ICSV.CC
   $Port     = $ICSV.Port
   $Cert     = $ICSV.Cert
   #"$PSEmailServer,$ToList,$FromList,$Port,$EmailID"

   #NOTE:  Internal SMTP servers may not require any ID Password to receive a necessary Connection 
   if ($SMTPCred.length -gt 0) {
     $userPassword = UNProtect-CMSmessage -To "$Cert" -Path "$PSScriptRoot\$SMTPCred"
    
     [securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
     [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($EmailID, $secStringPassword)

     If ($CCList.length -le 0) {
      Send-MailMessage -Attachments $ActionArray  -Subject "$Subject for $tdy on $Mach" `
         -From $FromList `
         -To $tolist -Body "Action on attached Results of 'Negative' needed !!!"`
         -SmtpServer $PSEmailServer  -Port $Port -Credential $credObject -UseSsl
      }
      Else {
       Send-MailMessage -Attachments $ActionArray  -Subject "$Subject for $tdy on $Mach" `
         -From $FromList `
         -To $tolist -Body "Action on attached Results of 'Negative' needed !!!"`
         -Cc $cclist `
         -SmtpServer $PSEmailServer  -Port $Port -Credential $credObject -UseSsl
      }
    }
    else {
    If ($CCList.length -le 0) {
      Send-MailMessage -Attachments $ActionArray  -Subject "$Subject for $tdy on $Mach" `
         -From $FromList `
         -To $tolist -Body "Action on attached Results of 'Negative' needed !!!"`
         -SmtpServer $PSEmailServer  -Port $Port 
      }
      Else {
       Send-MailMessage -Attachments $ActionArray  -Subject "$Subject for $tdy on $Mach" `
         -From $FromList `
         -To $tolist -Body "Action on attached Results of 'Negative' needed !!!"`
         -Cc $cclist `
         -SmtpServer $PSEmailServer  -Port $Port 
      }
    }
  } # Action array contents
} #Func Send-ResultsNotice

<# Add-RandomnessStart
.Synopsis
   Calculates and seeds a wait between other runs with 3 minute & 5 minute blank to next scheduled run
.Description
   If a waitwindow is given (in hours) then a peudo-random number of seconds is waited to do a run
.Parameter
   WaitWindow - Number of hours to next scheduled run. Default = 0 for run NOW
.Example
  Add-RandomnessStart -WaitWindow 4
#>
Function Add-RandomnessStart {
    Param ( $WaitWindow )
    if ($WaitWindow.length -gt 0) {
      $seed = Get-Date -Format "ssHHyyyymmddMM"
      $seed = [Math]::IEEERemainder($seed,2147483647) # Int32.maxValue
      $maxSeconds = $($([int]$Waitwindow * 3600)-300) # (Number hours  * 3600 s/hr) less 5 minutes
      $SSeconds = Get-Random -Maximum $maxSeconds -Minimum 180 -SetSeed $seed  # minimum 3 minute wait
   }
   else {
     $SSeconds = 0
   }
   #$SSeconds
   Start-Sleep -Seconds $SSeconds  # add some randomness to when review actually done
} # Function Add-RandomnessStart

#Process-ByManifest
<# 
.Synopsis
    Works through each line of a manifest and directs to the proper function with parameters.
.Description
    Simple step through file and use comma delimited values from text line as parameters to functions
.Parameter
   ManifestFull - a fully reconcilable name of a text manifest for
.Example
    Process-ByManifest -ManifestFull c:\test\EventManifest.txt
#>
Function Process-ByManifest {
   Param ( $ManifestFull , $trgtlocn )
   $ManifestC = Get-Contents -Path $ManifestFull
   Foreach ($line in $ManifestC) {
     $lpiece = $line.split(",")
     $f = $lpiece[0]
     $p1 = $lpiece[1]
     $p2 = $lpiece[2]
     $p3 = $lpiece[3]
     $p4 = $lpiece[4]
     $result = Process-ByFunction -f $f -p1 $p1 -p2 $p2 -p3 $p3 -p4 $p4
     "$f $p1 $p2 $p3 $p4" >> $trgtlocn
     $result >> $trgtlocn
   }
} # Process-ByManifest
