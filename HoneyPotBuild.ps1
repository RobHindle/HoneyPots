# Honey Pot Access and Write Detector !!!!!
<#  
Level 0 - Build HoneyPots
Build Corp or Admin Structure and HASH Profile the results
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

<# Get-RandomRange
.Synopsis
  Uses internal seeding process from date and time to point to new random sequence.
.Description
  Defaults own seed from the DateTime value and conforms this to valid seed.
.Parameter
  Seeder is int32 value or null for Date Time Generated
.Parameter
  MinRng is the minimum size of range.
.Parameter
  MaxRng is the maximum value of the range.
.Example
  Get-RandomRange -minrng 345 -maxrng 345678
#>
Function Get-RandomRange {
   Param ( $seeder,
           $MinRng = 0,
           $MaxRng = 100000
         )
         if ($seeder.length -le 0) {
            $seeder = get-date -Format "ssyyyyddHHMMmm"
            $seeder = [math]::IEEERemainder($seeder,2147483647) #Int32.MaxValue
            }
   $RndNo = Get-Random -SetSeed $seeder -Maximum $MaxRng -Minimum $MinRng
   $RndNO
} # Get-RandomRange

<# Make-RandomFileContent
.Synopsis
   Generates a block of random file contents either full character set or 
   numerically weighted.  Newline per machine and Hony-Pot markers are inserted. 
.Description
   Picks a range of line sizes and marker frequency and then for the randomly
   calculated file size it generates random characters taken from an english 
   charcter set or a numerical/math character set.
   Adding spaces to either letter set decrases the average word size.
.Parameter
   FileType either Numeric or Letters (Default is L)
.Parameter
   FileSize is the target file size for the pot.  Working file size ranges from 87% 
   to 117% of this number.  The random ness is to make each pot a little bit different.
.Example
   Make-RandomFileContent -FileType "N" -Filesize 45673
#>
Function Make-RandomFileContent {
  Param ($FileType = "L",
         $FileSize = 1359)
  $nl = [environment]::NewLine
  if ($FileType -eq "N") {
     $letters = "0123 456 789 -+=* &^%$ #()/"
     }
  else { # any charcter not N or n
     $letters = "0123 456789 abcdef ghi.jklm nop,qrs tuv wx;yz A:BCDE FGH IJ(KLM)NO PQRS?TUV WX!YZ"
     }
  $llen = $letters.length
  $HP = "Honey Pot <-> Cistern miel"
  [int]$fszmin = [int]$FileSize * 0.87
  [int]$fszmax = [int]$FileSize * 1.17
  $fsize = Get-RandomRange -MinRng $Fszmin -MaxRng $Fszmax
  $lnsize = Get-Random -Minimum 53 -Maximum 61
  $hpsize = Get-Random -Minimum 543 -maximum 741

  $filecnt = ""
  $c = 0
  $h = 0
For ($i = 0; $i -le $fsize; $i += 1){
 $PC = Get-Random -Maximum $llen -Minimum 0
 $filecnt += $letters[$PC]
  #put in newlines per the machine
  $c += 1
  if ($c -gt $lnsize) { 
    $c = 0
    $filecnt += $nl
    }
  #put in Hot-Pot Notice
  $d += 1
  if ($d -gt $hpsize) { 
    $d = 0
    $filecnt += $HP
    $c += $HP.length
    }
 } # for each random character of the file
  $filecnt
} # Make-RandomFileContent

<# Make-HashProfile
.Synopsis
  Calculates and records creation profile of access times and Hash values for each pot built.
.Description
  This records three different hash values, date last accessed and Date last written for an entire pot 
  as reference and baseline as built. 
.Parameter
   HashType 1 - valid Has algorithm (Default SHA256)
.Parameter
   HashType 2 - valid Has algorithm (Default MD5)
.Parameter
   HashType 2 - valid Has algorithm (Default SHA512)
.Parameter
   RootPoint - path of where to start the recursive evaluation of the pot
.Parameter
   HAshTarget - where should the results of this evaluation be written
.Example
   Make-HashProfile -Rootpoint c:\pot1 -HashTarget c:\hashprofiles
#>
Function Make-HashProfile {
    Param($HashType1 = "SHA256",
          $HashType2 = "MD5",
          $HAshType3 = "SHA512",
          $RootPoint ,
          $HASHtarget = "$RootPoint\HASH.txt")
    $GCI = Get-ChildItem -Path $RootPoint -Recurse -File
    ForEach ($Item in $GCI) {
       $H1 = Get-FileHash -Path $($Item.Fullname) -Algorithm $HashType1
       $H2 = Get-FileHash -Path $($Item.Fullname) -Algorithm $HashType2
       $H3 = Get-FileHash -Path $($Item.Fullname) -Algorithm $HashType3
       $LWT = $Item.LastWriteTime
       $LAT = $Item.LastAccessTime
       "$($Item.FullName),LWT,$LWT" >> $HashTarget
       "$($Item.FullName),$HAshType1,$($H1.Hash)" >> $HashTarget
       "$($Item.FullName),$HAshType2,$($H2.Hash)" >> $HashTarget
       "$($Item.FullName),$HAshType3,$($H3.Hash)" >> $HashTarget
       "$($ITem.FullName),LAT,$LAT" >> $HashTarget
    }
}

<# Pot-Machine
.Synopsis
   Evaluates the drive profile of the current machine and triggers pot builds on all FileSystems.
.Description
   Finds machine FileSystems that have space for a pot and creates the requested pots profile.
.Parameter
   CorpAdm - Either Admin or Corp (default is Corp) pot types
.Example
   Pot-Machine -CorpAdm Admin
.Future
Think of making a persistant B: drive and pot that.
#> 
Function Pot-Machine {
  Param ($CorpAdm = "Corp")
  $GPSD = Get-PSDrive
  Foreach ($Drv in $GPSD) {
     if ($($Drv.Provider.Name) -eq "FileSystem") {
        if ($($Drv.Free) -gt 1000000000) { 
        $Drv.Root
        if ($CorpAdm -eq "Admin") {
           Make-AdmPot -RootLevel $drv.Root
           }
        elseif ($CorpAdm -eq "Corp") {
           Make-CorpPot -RootLevel $drv.root
           }
        else { "Invalid Entry Provided to CorpAdm" } 
        } #BigEnough
     } # FileSystem
  } # for all Drives
} # Function Pot-Machine

<# Make-CorpPot
.Synopsis
   Pulls the configuration information from the Corporate Profile files and in a 
   layered way builds the folders and places the files as specified.  An As Built profile is 
   then calculated and stored.
.Description
   Takes profile information from HPCDocSets.txt, HPYears.txt and HPNamesOrg.txt 
   or your own files to build a composite of long lived corporate profiles filled with
   gibberish content.
.Parameter
   CorpPath - Path to the list of Coporate names to be used in potting
   1-2 Names start with 0 (Zero) to be high on any filestructure
   1-2 Names start with Z (Zed/Zee) to be low on any filestructure
   1-n Names in the rest of the alphabet to provide aditional "interest"
.Parameter
   YearsPath - Path to the list of years to be presented in "faked history"
   1965 to 2022 with a variable start and end and potentially missing years
   Adjust this to be the total size that you are comfortable with.
   1965-2022 generatees about 4500 files and 8GB space used.
.Parameter
   DocsPath - Path to the config file of documents you wish "faked"
   these represent areas of "interest" like HR, executive, sales, legal
.Parameter
   RootLevel - The Path where you wish the Corporate Pot built
.Example
   Make-Pot -RootLevel "c:\Customers"
#>
Function Make-CorpPot {
   Param ($CorpPath  = "$PSScriptRoot\HPNamesOrg.txt",
          $YearsPath = "$PSScriptRoot\HPYears.txt",
          $DocsPath  = "$PSScriptRoot\HPCDocSets.txt",
          $RootLevel )
        $YrMth = @("Year","Month")
        # Potentially translate if you operate non-English
        $MnthAry = @("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

     $CorpList  = Import-CSV  -Path $CorpPath
     $YearsList = Import-CSV  -Path $YearsPath
     $DocsList  = Import-CSV  -Path $DocsPath
     $CDocsList  = $DocsList | Where-Object DocGroup -notIn $YrMth
     $YDocsList  = $DocsList | Where-Object DocGroup -eq "Year"
     $MDocsList  = $DocsList | Where-Object DocGroup -eq "Month"
      
     Foreach ($Corp in $CorpList) {
          $OrgFldr = "$RootLevel\$($Corp.OrgName)"
          if (Test-Path -Path $OrgFldr) { }
          else { New-Item -ItemType Directory -Path $OrgFldr -Force }
         Foreach ($Doc in $CDocsList) {
               $CFldr = "$OrgFldr\$($Doc.DocGroup)"
               if (Test-Path -Path $CFldr) { } 
              else { New-Item -ItemType Directory -Path $CFldr -Force } 
              $Cdoc = "$($Doc.ShortForm)$($Corp.Initial).$($Doc.FType)"
              $CDocP = "$CFldr\$Cdoc"   
              if (Test-Path -Path $CDocP) {}
              else { 
              New-Item -ItemType File -Path $CdocP -Force 
              $FileContents = Make-RandomFileContent -FileType $($Doc.DType) -FileSize $($Doc.Size)
              $FileContents > $CdocP
              }
         } #Doc in CDoc
         Foreach ($Yr in $YearsList) {
             $YFldr = "$RootLevel\$($Corp.Orgname)\$($Yr.Year)"
             if (Test-Path -Path $YFldr) { } 
             else { New-Item -ItemType Directory -Path $YFldr -Force } 

           Foreach ($Doc in $YDocsList) {
              $Ydoc = "$($Doc.ShortForm)$($Corp.Initial).$($Doc.FType)"
              $YdocP = "$YFldr\$Ydoc"     
              if (Test-Path -Path $YdocP) {}
              else { 
              New-Item -ItemType File -Path $YdocP -Force 
              $FileContents = Make-RandomFileContent -FileType $($Doc.DType) -FileSize $($Doc.Size)
              $FileContents > $YdocP
              }
              Foreach ($Mnth in $MnthAry) {
                 $MFldr = "$YFldr\$Mnth"
                  if (Test-Path -Path $MFldr) { } 
                 else { New-Item -ItemType Directory -Path $MFldr -Force } 
                 Foreach ($Doc in $MDocsList) {
                       $Mdoc = "$($Doc.ShortForm)$($Corp.Initial).$($Doc.FType)"
                       $MdocP = "$MFldr\$Mdoc"     
                       if (Test-Path -Path $MdocP) {}
                       else { 
                           New-Item -ItemType File -Path $MdocP -Force 
                           $FileContents = Make-RandomFileContent -FileType $($Doc.DType) -FileSize $($Doc.Size)
                           $FileContents > $MdocP
                           }
                      } #Doc in MDoc
                  } # Each month
           } # Doc in YDoc
       } #Enumerated Year
       $CorpHash = "$OrgFldr\HASH.txt"
       Make-HashProfile -RootPoint $OrgFldr -HASHtarget $CorpHash
       "$($Corp.OrgName) $CorpHash"
       $MonitorManifest = "$RootLevel\HPManifest.txt"
       $OrgFldr >> $MonitorManifest
     } #Corp
} #Function Make-CorpPot

<# Make-AdmPot
.Synopsis
   Make honey pots that are "Attractive" to administration and preferences looking for tools
   to bypass internal systems or learn about the structures of the current installation.
.Description
.Parameter
   AdminPath - list of "administrator pots" to be generated.
   0ConOps and Zsop are provided to capture the "ends" of a file heirarchy.  
   Others "look" like personal stockpiles. Add more names to add to these sets.  Each set
   is about 275K +- of pot space.
.Parameter
   DocPath - list of docs and folders which hold an administrators person tool kits
.Parameter
   RootLevel - drive location where you wish to ploace the pots
.Example
   Make-AdmPot -RootLevel c:\Admin
#>
Function Make-AdmPot {
   Param (  $AdminPath  = "$PSScriptRoot\HPNamesAdm.txt",
                   $DocsPath  = "$PSScriptRoot\HPADocSets",
                   $RootLevel )

     $AdminList  = Import-CSV  -Path $AdminPath
     $DocsList   = Import-CSV  -Path $DocsPath
      
     Foreach ($Admin in $AdminList) {
          $AdmFldr = "$RootLevel\$($Admin.Name)"
          if (Test-Path -Path $AdmFldr) { }
          else { New-Item -ItemType Directory -Path $AdmFldr -Force }
         Foreach ($Doc in $DocsList) {
               $CFldr = "$AdmFldr\$($Doc.Group)"
               if (Test-Path -Path $CFldr) { } 
              else { New-Item -ItemType Directory -Path $CFldr -Force } 
              $Cdoc = "$($Doc.ShortCode)$($Corp.ShortName).$($Doc.Type)"
              $CDocP = "$CFldr\$Cdoc"   
              if (Test-Path -Path $CDocP) {}
              else { 
              New-Item -ItemType File -Path $CdocP -Force 
              $FileContents = Make-RandomFileContent -FileType $($Doc.DType) -FileSize $($Doc.Size)
              $FileContents > $CdocP
              }
         } #Doc in CDoc
       $CorpHash = "$AdmFldr\HASH.txt"
       Make-HashProfile -RootPoint $AdmFldr -HASHtarget $CorpHash
       "$($Adm.Name) $CorpHash"
       $MonitorManifest = "$RootLevel\HPManifest.txt"
       $AdmFldr >> $MonitorManifest
     } #Corp
} #Function Make-AdmPot

####### MAIN #######
" Build Honey Pots"
"1 - Make a Corporate Like Pots on a location"
"	Will need to know the Root location (i.e., c:\ or d:\dataarea\protected...)
"2 - Make and Admin Tolls like Pots on a location
" 	Will need to know the Root location (i.e., c:\ or d:\dataarea\protected...)             
"3 - Make Pots on a Machine
"	Will need to know Corp or Admin (Corporate Like or Adminstator Like)"
" "
$formvals = @("1","2","3")
$Form = Read-Host -Prompt "Enter 1, 2, 3 or X" as your Choice or Exit
if ($Form -in  $formvals) {
   $RootVals = @("1","2")
   if ($Form -in $RootVals) {
      $RootPoint = Read-Host -Prompt "Enter a Full Path to your desired Root Point"
      if ($Form -eq "1") {
          Make-CorpPot -RootLevel $RootPoint
          } # = 1
      elseif ($Form -eq "2") {
          Make-AdmPot  -RootLevel $RootPoint
          } # = 2
     } # in RootVals
   else {
      $PotTypes = @("Corp", "Admin")
      $PotT = Read-Host -Prompt "Enter either Corp or Admin (Default is Corp)"
      Pot-Machine -CorpAdm $PotT
   } # = 3
} # in FormVals