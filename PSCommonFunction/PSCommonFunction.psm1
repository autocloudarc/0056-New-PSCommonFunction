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

#region FUNCTIONS
function Get-CFPSGalleryModule
{
<#
.SYNOPSIS
Installs or updates required modules.

.DESCRIPTION
Installs or updates the required PowerShell modules for the calling script

.PARAMETER ModuleToInstall
The required list of modules to install.

.EXAMPLE
Get-CFPSGalleryModule -ModuleToInstall <module1>,<module2>,<module3>

.NOTES
The MIT License (MIT)
Copyright (c) 2018 Preston K. Parsard

#>
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
        If (Get-Module -Name $Module)
        {
        # To avoid multiple versions of a module is installed on the same system, first uninstall any previously installed and loaded versions if they exist
            Update-Module -Name $Module -Force -ErrorAction SilentlyContinue -Verbose
        } #end if
		# If the modules aren't already loaded, install and import it
		else
		{
			# https://www.powershellgallery.com/packages/WriteToLogs
			Install-Module -Name $Module -Repository $Repository -Force -Verbose
			Import-Module -Name $Module -Verbose
		} #end If
	} #end foreach
} #end function

function New-CFLogFiles
{

<#
.SYNOPSIS
Create log files

.DESCRIPTION
Creates a transcript and a custom log file to record script activity.

.EXAMPLE
New-CFLogFiles
The log file prefix will be the name of the calling script and a time-stamp will be used in the log and transcript file names with the following formats:
Custom log file: <ScriptName>-LOG-<localhost>-<time-stamp>.log
Transcript file: <ScriptName>-TRANSCRIPT-<localhost>-<time-stamp>.log

.NOTES
The MIT License (MIT)
Copyright (c) 2018 Preston K. Parsard
#>

# Get curent date and time
	$TimeStamp = (get-date -format u).Substring(0,16)
	$TimeStamp = $TimeStamp.Replace(" ", "-")
	$TimeStamp = $TimeStamp.Replace(":", "")

	$LogPrefix = "PSCommonFunction"
	New-Item -Path $env:USERPROFILE\$LogPrefix -ItemType Directory -Verbose
	$LogDirectory = Join-Path $env:USERPROFILE -ChildPath $LogPrefix
	# Construct log file full path
	$LogFile = "$LogPrefix-LOG" + "-" + $env:computername + "-" + $TimeStamp + ".log"
	$Log = Join-Path -Path $LogDirectory -ChildPath $LogFile

	# Construct transcript file full path
	$TranscriptFile = "$LogPrefix-TRANSCRIPT" + "-" + $env:computername + $TimeStamp + ".log"
	$Transcript = Join-Path -Path $LogDirectory -ChildPath $TranscriptFile

	# Create log and transcript files
	New-Item -Path $Log, $Transcript -ItemType File -ErrorAction SilentlyContinue -Verbose
} # end function

function New-CFHeader
{

<#
.SYNOPSIS
Creates a new header.

.DESCRIPTION
Creates a new header with the format:
=====================================
<Header title> <time-stamp>
=====================================

.EXAMPLE
New-CFHeader -label <Header title> -charCount ##
In this example, the label parameter is used to for the header title, and the -charCount parameter indicates the number of "=" that will be created for the double line separator

.NOTES
The MIT License (MIT)
Copyright (c) 201 Preston K. Parsard
#>
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

	# Show header
	$header.SeparatorDouble
	$header.Title
	$header.SeparatorDouble
	$header.SeparatorSingle

} # end function

function Install-CFAdModuleIfRequired
{
<#
.SYNOPSIS
Install the ActiveDirectory module feature if required

.DESCRIPTION
This function will install the ActiveDirectory PowerShell feature so that PowerShell cmdlets can be used for the remainder of the script.
It will test if the module is already installed, and if not, will install it.

.EXAMPLE
Install-CFAdModuleIfRequired

.NOTES
The MIT License (MIT)
Copyright (c) 2018 Preston K. Parsard
#>
	# Add the RSAT-AD-PowerShell feature so that the ActiveDirectory modules can be used in the remainder of the script.
	if (-not((Get-WindowsFeature -Name "RSAT-AD-PowerShell").InstallState))
	{
		Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature -IncludeManagementTools -Verbose
	} # end if
} # end function

#endregion FUNCTIONs

Export-ModuleMember -Function *-CF*