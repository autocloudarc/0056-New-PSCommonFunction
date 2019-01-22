# PSCommonFunciton module FUNCTIONS
<#
****************************************************************************************************************************************************************************
PROGRAM:
PSCommonFunction.psm1

DESCRIPTION:
A module with a set of commonly used functions to get PowerShellGallery modules, create log files, add headers, footers, prompts and calculate elapsed time for a script.

KEYWORDS:
Write, Logs, Header, Footer, Time, Formatting

LICENSE:
The MIT License (MIT)
Copyright (c) 2019 Preston K. Parsard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

DISCLAIMER:
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive,
royalty-free right to use and modify the Sample Code and to reproduce and distribute the Sample Code, provided that You agree: (i) to not use Our name,
logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless,
and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees,
that arise or result from the use or distribution of the Sample Code.
****************************************************************************************************************************************************************************
#>

<#
	Release notes
	TASK-ITEM: 0.0.0 Notes
#>

#region FUNCTIONS

function Get-CFInputFile
{
} # end function

function Get-CFLogPath
{

} # end function

function Get-CFPSGalleryModule
{
	[CmdletBinding(PositionalBinding = $false)]
	Param
	(
		# Required modules
		[Parameter(Mandatory = $true,
				   HelpMessage = "Please enter the PowerShellGallery.com modules required for this script",
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNull()]
		[ValidateNotNullOrEmpty()]
		[string[]]$ModulesToInstall
	) #end param

    # NOTE: The newest version of the PowerShellGet module can be found at: https://github.com/PowerShell/PowerShellGet/releases
    # 1. Always ensure that you have the latest version

	$Repository = "PSGallery"
	Set-PSRepository -Name $Repository -InstallationPolicy Trusted
	Install-PackageProvider -Name Nuget -ForceBootstrap -Force
	foreach ($Module in $ModulesToInstall)
	{
        # If module exists, update it
        If (Get-Module -Name $Module -Repository $Repository)
        {
        # To avoid multiple versions of a module is installed on the same system, first uninstall any previously installed and loaded versions if they exist
            Update-Module -Name $Module -Repository $Repository -Force -ErrorAction SilentlyContinue -Verbose
        } #end if
		# If the modules aren't already loaded, install and import it
		else
		{
			# https://www.powershellgallery.com/packages/WriteToLogs
			Install-Module -Name $Module -Repository $Repository -Force -Verbose
			Import-Module -Name $Module -Repository $Repository -Verbose
		} #end If
	} #end foreach
} #end function

function New-CFLogFiles
{
	[CmdletBinding()]
	[OutputType([string[]])]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$LogDirectory,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$LogPrefix
	) # end param

	# Get curent date and time
	$TimeStamp = (get-date -format u).Substring(0,16)
	$TimeStamp = $TimeStamp.Replace(" ", "-")
	$TimeStamp = $TimeStamp.Replace(":", "")

	# Construct log file full path
	$LogFile = "$LogPrefix-LOG" + "-" + $env:computername + "-" + $TimeStamp + ".log"
	$script:Log = Join-Path -Path $LogDirectory -ChildPath $LogFile

	# Construct transcript file full path
	$TranscriptFile = "$LogPrefix-TRANSCRIPT" + "-" + $TimeStamp + ".log"
	$script:Transcript = Join-Path -Path $LogDirectory -ChildPath $TranscriptFile

	# Create log and transcript files
	New-Item -Path $Log, $Transcript -ItemType File -ErrorAction SilentlyContinue
} # end function

function New-CFHeader
{
	[CmdletBinding()]
	[OutputType([hashtable])]
	param (
		[Parameter(Mandatory=$true)]
		[string]$label,
		[Parameter(Mandatory=$true)]
		[int]$charCount
	) # end param

	$header = @{
		# Draw double line
		SeparatorDouble = ("=" * $charCount)
		Title = ("$label :" + " $(Get-Date)")
		# Draw single line
		SeparatorSingle = ("-" * $charCount)
	} # end hashtable

} # end function

function Show-CFHeader
{
	# Display header
	Write-ToConsoleAndLog -Output $header.SeparatorDouble -Log $Log
	Write-ToConsoleAndLog -Output $Header.Title -Log $Log
	Write-ToConsoleAndLog -Output $header.SeparatorSingle -Log $Log
} # end function

function New-CFPromptObjects
{
	# Create prompt and response objects
	[CmdletBinding()]
	param (
	[AllowNull()]
	[AllowEmptyCollection()]
	[PScustomObject]$PromptsObj,

	[AllowNull()]
	[AllowEmptyCollection()]
	[PScustomObject]$ResponsesObj
	) # end param

	# Create and populate prompts object with property-value pairs
	# PROMPTS (PromptsObj)
	$PromptsObj = [PSCustomObject]@{
		 pVerifySummary = "Is this information correct? [YES/NO]"
		 pAskToOpenLogs = "Would you like to open the custom and transcript logs now ? [YES/NO]"
	} #end $PromptsObj

	# Create and populate responses object with property-value pairs
	# RESPONSES (ResponsesObj): Initialize all response variables with null value
	$ResponsesObj = [PSCustomObject]@{
		 pProceed = $null
		 pOpenLogsNow = $null
	} #end $ResponsesObj
} # end function

function Show-CFPromptToContinue
{
	Do {
		$ResponsesObj.pProceed = read-host $PromptsObj.pVerifySummary
		$ResponsesObj.pProceed = $ResponsesObj.pProceed.ToUpper()
	} # end do
	Until ($ResponsesObj.pProceed -eq "Y" -OR $ResponsesObj.pProceed -eq "YES" -OR $ResponsesObj.pProceed -eq "N" -OR $ResponsesObj.pProceed -eq "NO")
} # end function

function Install-CFAdModuleIfRequired
{
	# Add the RSAT-AD-PowerShell feature so that the ActiveDirectory modules can be used in the remainder of the script.
	if (-not((Get-WindowsFeature -Name "RSAT-AD-PowerShell").InstallState))
	{
		Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature -IncludeManagementTools -Verbose
	} # end if
} # end function

#endregion FUNCTIONs

#region INITIALIZE VALUES

# function: Get any PowerShellGallery.com modules required for this script.
Get-PSGalleryModule -ModulesToInstall "WriteToLogs"

# Create Log file
[string]$Log = $null
[string]$Transcript = $null

$scriptName = $MyInvocation.MyCommand.name
# Use script filename without exension as a log prefix
$LogPrefix = $scriptName.Split(".")[0]

# funciton: Create log files for custom logging and transcript
New-LogFiles -LogDirectory $LogDirectory -LogPrefix $LogPrefix

Start-Transcript -Path $Transcript -IncludeInvocationHeader

# Create prompt and response objects for continuing script and opening logs.
$PromptsObj = $null
$ResponsesObj = $null

# function: Create prompt and response objects
New-PromptObjects -PromptsObj $PromptsObj -ResponsesObj $ResponsesObj

$BeginTimer = Get-Date -Verbose

Install-AdModuleIfRequired

# Initialize index
$i = 0

# Populate summary display object
# Add properties and values
 $SummObj = [PSCustomObject]@{
     Log = $Log
     Transcript = $Transcript
 } #end $SummObj

 # funciton: Create new header
 $label = "<HEADER TITLE>"
 New-Header -label $label

 # function: Create prompt and responses objects ($PromptsObj, ResponsesObj)
 New-PromptObjects

 #endregion INITIALIZE VALUES

#region MAIN


# Display Summary of initial parameters and constructed values
Write-ToConsoleAndLog -Output $SummObj -Log $Log
Write-ToConsoleAndLog -Output $header.SeparatorDouble -Log $Log



# Record prompt and response in log
Write-ToLogOnly -Output $PromptsObj.pVerifySummary -Log $Log
Write-ToLogOnly -Output $ResponsesObj.pProceed -Log $Log

# Exit if user does not want to continue
if ($ResponsesObj.pProceed -eq "N" -OR $ResponsesObj.pProceed -eq "NO")
{
	Write-ToConsoleAndLog -Output "Script terminated by user..." -Log $Log
	PAUSE
	EXIT
} #end if ne Y
else
{

} # end else
#endregion MAIN

#region SUMMARY

# Calculate statistics
$score = [PScustomObject]@{
} # end count objects

# Display count statistics
$countObj | Format-Table -AutoSize | Tee-Object -FilePath $log -Append
# Display score
$score | Format-Table -AutoSize | Tee-Object -FilePath $log -Append

# Calculate elapsed time
Write-WithTime -Output "Calculating script execution time..." -Log $Log
Write-WithTime -Output "Getting current date/time..." -Log $Log
$StopTimer = Get-Date
$EndTime = (((Get-Date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")
Write-WithTime -Output "Calculating elapsed time..." -Log $Log
$ExecutionTime = New-TimeSpan -Start $BeginTimer -End $StopTimer

$Footer = "SCRIPT COMPLETED AT: "
$EndOfScriptMessage = "End of script!"

Write-ToConsoleAndLog -Output $header.SeparatorDouble -Log $Log
Write-ToConsoleAndLog -Output "$Footer $EndTime" -Log $Log
Write-ToConsoleAndLog -Output "TOTAL SCRIPT EXECUTION TIME[hh:mm:ss]: $ExecutionTime" -Log $Log
Write-ToConsoleAndLog -Output $header.SeparatorDouble -Log $Log

# Review deployment logs
# Prompt to open logs
Do
{
 $ResponsesObj.pOpenLogsNow = read-host $PromptsObj.pAskToOpenLogs
 $ResponsesObj.pOpenLogsNow = $ResponsesObj.pOpenLogsNow.ToUpper()
}
Until ($ResponsesObj.pOpenLogsNow -eq "Y" -OR $ResponsesObj.pOpenLogsNow -eq "YES" -OR $ResponsesObj.pOpenLogsNow -eq "N" -OR $ResponsesObj.pOpenLogsNow -eq "NO")

# Exit if user does not want to continue
If ($ResponsesObj.pOpenLogsNow -in 'Y','YES')
{
    Start-Process -FilePath notepad.exe $Log -Verbose
    Start-Process -FilePath notepad.exe $Transcript -Verbose
	# Invoke-Item -Path $resultsPathCsv -Verbose
    Write-WithTime -Output $EndOfScriptMessage -Log $Log
} #end condition
ElseIf ($ResponsesObj.pOpenLogsNow -in 'N','NO')
{
    Write-WithTime -Output $EndOfScriptMessage -Log $Log
    Stop-Transcript -Verbose -ErrorAction SilentlyContinue
} #end condition

#endregion SUMMARY

Stop-Transcript -ErrorAction SilentlyContinue -Verbose