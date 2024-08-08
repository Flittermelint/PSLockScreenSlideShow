
$Script:ModuleName = (Get-Item -Path $PSCommandPath).BaseName

<#
.SYNOPSIS

Get PSLockScreenSlideShow images from path

.DESCRIPTION

Get PSLockScreenSlideShow images from path and return a list of objects with Path, Time, Unit properties.

The result can directly be piped to Start-PSLockScreenSlideShow (e.g. see PSLockScreenSlideShow.ps1)

.PARAMETER Path

Specifiy the path where to load the LockScreen images from

Defaults to C:\ProgramData\PSLockScreenSlideShow

Files are NOT loaded recursively, but sorted by name to force a consistent order

.PARAMETER Time

The time each slideshow image will be shown if no time can be extracted from filename by parameter TimeRegEx

Defaults to "5s"

.PARAMETER TimeRegEx

Defaults to "^.*\W(?<Time>\d{1,})(?<Unit>ms|s)$" which means:

^               start of line (line=file.Basename)
.*              0 to n any characters
\W              one any non digit or letter (means special character)
(?<Time>\d{1,}) one or more digits (this pattern must be named 'Time' to be used internally to fill the result objects property "Time")
(?<Unit>ms|s)   'ms' or 's', unit of the afore mentioned Time (this pattern must be named 'Unit' to be used internally to fill the result objects property "Unit")
$               end of line (line= file.Basename)

.INPUTS

None. Right now you cannot pipe objects to Get-PSLockScreenSlideShow

.OUTPUTS

a list of PSCustomObjects 

[PSCustomObject]@{
    Path = ...
    Time = ...
    Unit = ...
}

.EXAMPLE

Get-PSLockScreenSlideShow

Path                                                    Time Unit
----                                                    ---- ----
C:\ProgramData\PSLockScreenSlideShow\00-Show.jpg           5 s
C:\ProgramData\PSLockScreenSlideShow\01-Show-5s.jpg        5 s
C:\ProgramData\PSLockScreenSlideShow\02-Show-10s.jpg      10 s
C:\ProgramData\PSLockScreenSlideShow\03-Show-5000ms.jpg 5000 ms

assumed C:\ProgramData\PSLockScreenSlideShow contains the following files

00-Show.jpg    
01-Show-5s.jpg 
02-Show-10s.jpg
03-Show-5000ms.jpg 
#>

function Get-PSLockScreenSlideShow
{
    [CmdletBinding()]
	Param (
	    [Parameter()][string]$Path      =  "$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData))\$($Script:ModuleName)",
	    [Parameter()][string]$Time      = "5s",
	    [Parameter()][string]$TimeRegEx = "^.*\W(?<Time>\d{1,})(?<Unit>ms|s)$"
    )

    Begin
    {
        $Default = Get-PSLockScreenSlideShowTime $Time
    }

    Process
    {
        Get-ChildItem -Path $Path | Sort-Object -Property FullName | ForEach-Object {

            $Result = [PSCustomObject]@{

                Path = $_.FullName

                Time = $Default.Time
                Unit = $Default.Unit
            }

            if($TimeRegEx)
            {
                if($_.BaseName -match $TimeRegEx)
                {
                    if($Matches.Time) { $Result.Time = [Convert]::ToInt32($Matches.Time) }
                    if($Matches.Unit) { $Result.Unit =                    $Matches.Unit  }
                }
            }

            $Result
        }
    }
}

function Get-PSLockScreenSlideShowTime($Time)
{
    if($Time -match "^(\d{1,})(ms|s)$")
    {
        [PSCustomObject]@{

            Time = [Convert]::ToInt32($Matches[1])
            Unit =                    $Matches[2]
        }
    }
    else
    {
        [PSCustomObject]@{

            Time = 5
            Unit = "s"
        }
    }
}

function Wait-PSLockScreenSlideShow
{
    [CmdletBinding()]
	Param (
	    [Parameter(ValueFromPipelineByPropertyName)]$Time,
	    [Parameter(ValueFromPipelineByPropertyName)]$Unit
    )

    Process 
    {
        $Sleep = @{

            @{
                           "s" =      "Seconds"
                          "ms" = "Milliseconds"

                     "Seconds" =      "Seconds"
                "Milliseconds" = "Milliseconds"

            }[$Unit] = $Time
        }

        Start-Sleep @Sleep
    }
}


<#
.SYNOPSIS

Set LockScreen image

.DESCRIPTION

Set LockScreen image

.PARAMETER Path

Specifiy the image filename to set as LockScreen image

.INPUTS

Image filename that should be set as LockScreen image

.OUTPUTS

None.

.EXAMPLE

"C:\ProgramData\PSLockScreenSlideShow\00-Show.jpg" | Set-PSLockScreenSlideShowImage 

Set "C:\ProgramData\PSLockScreenSlideShow\00-Show.jpg" via pipeline as the actual LockScreen image

.EXAMPLE

Set-PSLockScreenSlideShowImage "C:\ProgramData\PSLockScreenSlideShow\00-Show.jpg"

Set "C:\ProgramData\PSLockScreenSlideShow\00-Show.jpg" via parameter as the actual LockScreen image
#>

function Set-PSLockScreenSlideShowImage
{
    [CmdletBinding()]
	Param (
	    [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)][string]$Path
    ) 
    
    Begin
    {
        [void]([Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime])
        [void]([Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime])

        Add-Type -AssemblyName System.Runtime.WindowsRuntime

        $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

        function Await($WinRtTask, $ResultType)
        {
            $asTask  = $asTaskGeneric.MakeGenericMethod($ResultType)
            $netTask = $asTask.Invoke($null, @($WinRtTask))
            $netTask.Wait(-1) | Out-Null
            $netTask.Result
        }

        function AwaitAction($WinRtAction)
        {
            $asTask  = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
            $netTask = $asTask.Invoke($null, @($WinRtAction))
            $netTask.Wait(-1) | Out-Null
        }
    }

    Process
    {
		$image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)) ([Windows.Storage.StorageFile])
        
        AwaitAction ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($image))
    }
}

function Start-PSLockScreenSlideShow
{
    [CmdletBinding()]
	Param (
	    [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)][string[]]$Path,

	    [Parameter(ValueFromPipelineByPropertyName)]                  [int]     $Time,
	    [Parameter(ValueFromPipelineByPropertyName)]                  [string]  $Unit,

	    [Parameter()]                                                 [switch]  $Forever
    ) 

    Begin
    {
        $Slides = [System.Collections.Generic.List[object]]::new()
    }

    Process
    {
        foreach($p in $Path)
        {
            $Slides.Add([PSCustomObject]@{

                Path = $p
                Time = $Time
                Unit = $Unit
            })

            Set-PSLockScreenSlideShowImage -Path $p

            Wait-PSLockScreenSlideShow -Time $Time -Unit $Unit
        }
    }

    End
    {
        if($Forever)
        {
            $Slides | ForEach-Object {

                Set-PSLockScreenSlideShowImage -Path $_.Path

                Wait-PSLockScreenSlideShow -Time $_.Time -Unit $_.Unit
            }
        }
    }
}

function Register-PSLockScreenSlideShowScheduledTask
{
    [CmdletBinding()]
	Param (
	    [Parameter()][string]$Path,
	    [Parameter()][string]$Time,
	    [Parameter()][string]$TimeRegEx
    )

    Unregister-PSLockScreenSlideShowScheduledTask

    @(
        @{
            TaskPath  = "\$($Script:ModuleName)\"
            TaskName  = "Lock"

            Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" # VORDEFINIERT\Benutzer = Builtin\Users

            Trigger   = . {

                $class = Get-CimClass MSFT_TaskSessionStateChangeTrigger Root/Microsoft/Windows/TaskScheduler
    
                $instance = $class | New-CimInstance -ClientOnly

                $instance.Enabled = $true

                $instance.StateChange = 7 # Lock

                $instance
            }

            Action    = . {

                $ActionExe  = (([System.Environment]::GetCommandLineArgs() | Select-Object -First 1) -replace "_ISE", "")

                $ActionArgs = . {

                    "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$([System.IO.Path]::ChangeExtension($PSCommandPath, ".ps1"))"""

                    foreach($key in $PSBoundParameters.Keys)
                    {
                        "-$($key) $($PSBoundParameters[$key])"
                    }
                }

                New-ScheduledTaskAction -Execute $ActionExe -Argument ($ActionArgs -join ' ')
            }

            Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit "00:00:00"
        }

        @{
            TaskPath  = "\$($Script:ModuleName)\"
            TaskName  = "Unlock"

            Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" # VORDEFINIERT\Benutzer = Builtin\Users

            Trigger   = . {

                $class = Get-CimClass MSFT_TaskSessionStateChangeTrigger Root/Microsoft/Windows/TaskScheduler
    
                $instance = $class | New-CimInstance -ClientOnly

                $instance.Enabled = $true

                $instance.StateChange = 8 # Unlock

                $instance
            }

            Action    = . {

                $ActionExe  = (([System.Environment]::GetCommandLineArgs() | Select-Object -First 1) -replace "_ISE", "")

                $ActionArgs = . {

                    "-ExecutionPolicy Bypass -WindowStyle Hidden -Command ""Stop-ScheduledTask -TaskPath '\$($Script:ModuleName)\' -TaskName 'Lock' -ErrorAction SilentlyContinue"""
                }

                New-ScheduledTaskAction -Execute $ActionExe -Argument ($ActionArgs -join ' ')
            }

            Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit "00:00:00"
        }

    ) | ForEach-Object { Register-ScheduledTask @_ -ErrorAction SilentlyContinue }
}

function Unregister-PSLockScreenSlideShowScheduledTask
{
    Unregister-ScheduledTask -TaskPath "\$($Script:ModuleName)\" -TaskName "Lock"   -Confirm:$false -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskPath "\$($Script:ModuleName)\" -TaskName "Unlock" -Confirm:$false -ErrorAction SilentlyContinue

    try
    {
        $taskScheduler = New-Object -ComObject Schedule.Service

        $taskScheduler.Connect()
        $taskScheduler.GetFolder("\").DeleteFolder($Script:ModuleName, $null)
    }
    catch
    {
    }
}
