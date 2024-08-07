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
