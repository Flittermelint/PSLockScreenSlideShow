
<#
.SYNOPSIS

Run lockscreen slideshow

.DESCRIPTION

Run lockscreen slideshow with images from path

This is the default script, installed as scheduled task by "Register-PSLockScreenSlideShowScheduledTask"
The scheduled task is located in the task scheduler folder "PSLockScreenSlideShow" as "PSLockScreenSlideShow"
which is triggered "on workstation lock" and runs in the context of the current logged on user.

.PARAMETER Path

Same as "Path" from "Get-PSLockScreenSlideShow"

Specifiy the path where to load the LockScreen images from

Defaults to C:\ProgramData\PSLockScreenSlideShow

Files are NOT loaded recursively, but sorted by name to force a consistent order

.PARAMETER Time

Same as "Time" from "Get-PSLockScreenSlideShow"

The time each slideshow image will be shown if no time can be extracted from filename by parameter TimeRegEx

Defaults to "5s"

.PARAMETER TimeRegEx

Same as "TimeRegEx" from "Get-PSLockScreenSlideShow"

Defaults to "^.*\W(?<Time>\d{1,})(?<Unit>ms|s)$" which means:

^               start of line (line=file.Basename)
.*              0 to n any characters
\W              one any non digit or letter (means special character)
(?<Time>\d{1,}) one or more digits (this pattern must be named 'Time' to be used internally to fill the result objects property "Time")
(?<Unit>ms|s)   'ms' or 's', unit of the afore mentioned Time (this pattern must be named 'Unit' to be used internally to fill the result objects property "Unit")
$               end of line (line= file.Basename)

.INPUTS

None, since this script is only provisoned to run as scheduled task

.OUTPUTS

None, since this script is only provisoned to run as scheduled task

#>

[CmdletBinding()]
Param (
	[Parameter()][string]$Path,
	[Parameter()][string]$Time,
	[Parameter()][string]$TimeRegEx
)

Import-Module PSLockScreenSlideShow -Force

$ArgsGet  = @{}; $ParmsGet  = (Get-Command  Get-PSLockScreenSlideShow).Parameters.Keys
$ArgsShow = @{}; $ParmsShow = (Get-Command Show-PSLockScreenSlideShow).Parameters.Keys

foreach($key in $PSBoundParameters.Keys)
{
    if($key -in $ParmsGet ) { $ArgsGet[ $key] = $PSBoundParameters[$key] }
    if($key -in $ParmsShow) { $ArgsShow[$key] = $PSBoundParameters[$key] }
}

Get-PSLockScreenSlideShow @ArgsGet | Start-PSLockScreenSlideShow @ArgsShow -Forever
