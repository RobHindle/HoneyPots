# Honey Pot Access and Write Detector !!!!!
<#  
Level 1 - Detect activity
Check through a manifest of folders on a machine to detect if a Last Access Time for a file in a HoneyPot is less than 7 days old.
Report that if one is discovered.  Should be HEARTBEAT and PERIODCHECK.
Level 1.5 - Detect tampering
Check through the manifest the Changes, Additions and Deletions and report changes.
Level 2 - Detect Perpetrator (Assuming File Usage logging is ON)
Level 3 - Perform initial lock-out of perpetrator with Notification and non-Alerting message.
#>
<#  Disclaimer
Author:  Robert Hindle May 12th 2021
USE AT YOUR OWN RISK.  Check the HashChecks.  Adjust to your own needs
#>

<# Check-L1LastAccessTime
.Synopsis
   Checks for recent access times against files which should not be accessed.
.Description
   Checks for recent access times of files present within the pot file systems.
.Parameter
   PathGiven - drive location where you wish to ploace the pots
.Parameter
   LATVTolerance - int for number of discrepancies to be tolerated in run (default 3)
.Example
   Check-L1LastAccessTime -PathGiven c:\Admin
#>
Function Check-L1LastAccessTime {
   Param ($PathGiven,
          $LATVTolerance = 3)
           
   $LATVCount = 0

   $GCI = Get-ChildItem -Path $PathGiven -Recurse 
   $tdy = Get-Date
   Foreach ($Item in $GCI) {
    $DaysDiff = $($tdy - $Item.LastAccessTime).TotalDays
    $DaysDiff
    if ($DaysDiff -lt 7) { #Report this File
     $LATVCount += 1
     # This will pick up some added files.  We are not checking against Hash profile
     # to detect any deleted files.
     "$($Item.FullName),LAT,$($item.LastAccessTime)"
     # a Hash will give an indication if the file was altered during access
     # a Hash Changes the LastAccessTime on the file in order to do the hash.
     #$hash = Get-FileHash -Path $($Item.Fullname) -Algorithm MD5 
     #"$($Item.Fullname),MD5,$($Hash.hash)"
    }
   }
   # So LastaccessTime  Violation Tolerance can be 1or0 in which even an accidental look 
   # will trigger investigation and action as breach (possibly appropriate).
   # A tolerance of up to three means the snooping is further reaching and past a
   # simple slip up.
   if ($LATVCount -gt $LATVTolerance) { #Declare Breach
      "BREACH DECLARED = YES AccessCount = $LATVCount"
   }
} # Function Check-LastAccessTime

<# Check-L15WriteDelAdd
.Synopsis
   Check the Modifications, Additions and Deletions which have occurred within a Pot
.Description
   Detects and matches Last Write Time, Profile Matches and detects for additions or deletions
.Parameter
   PathGiven - drive location where you wish to ploace the pots
.Parameter
   WDATolerance - int for number of discrepancies to be tolerated in run (Default 3)
.Example
   Check-L1LastAccessTime -PathGiven c:\Admin
#>
Function Check-L15WriteDelAdd {
   Param($PathGiven,
         $WDATolerance = 3)
   $WDACount = 0

   $GCI = Get-ChildItem -Path $PathGiven -Recurse -File
   $tdy = Get-Date

   $PAthGiven
   $HashPaths = @()
   $PotHash = "$PathGiven\Hash.txt"
   #$Pothash
   $HashContents = Get-Content -Path $PotHash
   #$HASHContents

   Foreach ($Line in $HashContents) {
      $Pieces = $Line.split(",")
      if ($Pieces[1] -eq "LWT") {
         $HashPaths += $($Pieces[0])
         #$HASHPaths.count
         if (Test-Path -Path $($Pieces[0])) {         #Check not deleted
            $LWT = $(get-Item -Path $($Pieces[0])).LastWriteTime
            if ([string]$LWT -ne [string]$($Pieces[2])) {             #Check not modified
               $WDACount += 1
               "$Line, LWT=$LWT"
            } #LWT testing +-
         } #Test-Path found
         else { #Test-Path not found Thr4 File deleted
            $WDACount += 1  # This could be a three
            "$Line, FileNotFound"
         } #Test-Path file Deleted
      } #LWT Record in Hash.txt
   } # For every line in Hash.txt

   # Sort both $CGI and $HashContents then do While Comparison  SB equal
   $SGCI = Sort-Object -InputObject $GCI
   $SGCIf = $SGCI.FullName
   $SHashCont = Sort-Object -InputObject $HashPaths -Unique
   #"Current=$($SGCIf.count) Hash=$($SHashCont.count)"
   $Spntr = 0
   $HPntr = 0
   Do {
   if ($($SGCIf[$Spntr]) -eq $($SHashCont[$HPntr])) {
      $Spntr += 1
      $Hpntr += 1
   }
   elseif ($($SGCIf[$Spntr]) -gt $($SHashCont[$HPntr])){
      "$($SGCIf[$Spntr]) NEWgt"
      $Spntr += 1
      $WDACount += 1
   }
   elseif ($($SGCIf[$Spntr]) -lt $($SHashCont[$HPntr])){
      $Hpntr += 1
      $WDACount += 1
      "$($SGCIf[$Spntr]) NEWlt"
   }
   } While ($Spntr -le $SGCIf.count)

   # So WriteDeleteAdd Violation Tolerance can be 1 or 0 in which even an accidental look 
   # will trigger investigation and action as breach (possibly appropriate).
   # A tolerance of up to three means the snooping is further reaching and past a
   # simple slip up.  Three also considers noise.  It also builds in time because we
   # are going against the AS BUILT Hash Profiles.
   # WDACount will be minimmum 1 with the HASH File being located in the Pot Folder structure
   if ($WDACount -gt $WDATolerance) { #Declare Breach
      "BREACH DECLARED = YES WriteDeleteAddCount = $WDACount"
   }

} # Function Check-L15WriteDelAdd
<# Check-Pots
.Synopsis
   Uses the Manifest generated of Pots to point for reviews and monitoring.
.Description
   Uses the manifest of the build process to guide the Last Access Time review 
   and the Modify, Delete or Add Review
.Parameter
   ManifestPath - Full file location of where the manifest file is located
.Example
   Check-Pots -ManifestPath "$PSScriptRoot\HPManifest"
#>
Function Check-Pots {
 Param (
    $ManifestPath = "$PSScriptRoot\HPManifest.txt")

 $Pots = Get-Content -Path $ManifestPath

 Foreach ($Pot in $Pots){
   Check-L1LastAccessTime -PathGiven $Pot
 }

 Foreach ($Pot in $Pots) {
   Check-L15WriteDelAdd -PathGiven $Pot
 }
}