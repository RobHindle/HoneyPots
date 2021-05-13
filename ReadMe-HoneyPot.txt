READMeHoney Pot

Tools to Build then Monitor Honey pots on a Computer and have results sent back to central monitoring if activity detected.

Monitoring Scheduled Task - set to happen at least 1-2 times per week ( up to about 5 minutes apart)
   Execution in Scheduled Task         %systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe
   Attributes of Scheduled Task          -executionpolicy Bypass -WindowStyle Hidden -file "yourlocation\HoneyPotMonitorControl.ps1"


HoneyPotBuild.ps1presumes running in PS ISE or PowerShell Command window.  Editting of config files can use notepad on the text files.

Hash Check Values for this Tool and its files available at http://web.ncf.ca/bv178/HashChecks.html