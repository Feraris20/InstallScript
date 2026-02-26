Clear-Host

function Write-Color {
    param (
        [string]$Message,
        [ConsoleColor]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

# Helper: Removes task if it exists
function Remove-ScheduledTaskIfExists {
    param (
        [string]$TaskName
    )
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Color "Removed existing task: $TaskName" 'Yellow'
        return $true
    }
    return $false
}

# Reusable names
$shutdownTaskName = "ScheduledShutdown"
$appStartTaskName = "ScheduledAppStart"

function Schedule-Shutdown {
    while ($true) {
        Write-Color "Enter shutdown time in HH:MM (24-hour format), or 0 to return to main menu:" 'Cyan'
        $timeInput = Read-Host
        if ($timeInput -eq '0') { return }

        if ($timeInput -match '^(?:[01]\d|2[0-3]):[0-5]\d$') { break }
        else { Write-Color "Invalid time format. Try again." 'Red' }
    }

    Remove-ScheduledTaskIfExists -TaskName $shutdownTaskName | Out-Null

    $action = New-ScheduledTaskAction -Execute "shutdown" -Argument "/s /f /t 0"
    $trigger = New-ScheduledTaskTrigger -Daily -At $timeInput
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    Register-ScheduledTask -TaskName $shutdownTaskName -Action $action -Trigger $trigger -Principal $principal
    Write-Color "Shutdown scheduled at $timeInput." 'Green'
}

function Delete-ShutdownSchedule {
    if (-not (Remove-ScheduledTaskIfExists -TaskName $shutdownTaskName)) {
        Write-Color "No shutdown schedule found." 'Yellow'
    }
}

function Schedule-AppStart {
    while ($true) {
        Write-Color "Enter full path to executable, or 0 to return:" 'Cyan'
        $inputPath = Read-Host
        if ($inputPath -eq '0') { return }

        # Trim quotes and whitespaces
        $exePath = $inputPath.Trim('"').Trim()

        if (-not (Test-Path $exePath -PathType Leaf)) {
            Write-Color "Invalid path or file not found." 'Red'
            Write-Color 'Example: "C:\Program Files\MyApp\app.exe"' 'Yellow'
        } else {
            break
        }
    }

    Remove-ScheduledTaskIfExists -TaskName $appStartTaskName | Out-Null

    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $action = New-ScheduledTaskAction -Execute $exePath

    Register-ScheduledTask -TaskName $appStartTaskName -Trigger $trigger -Action $action -RunLevel Highest
    Write-Color "App start scheduled on logon." 'Green'
}


function Delete-AppStartSchedule {
    if (-not (Remove-ScheduledTaskIfExists -TaskName $appStartTaskName)) {
        Write-Color "No app start schedule found." 'Yellow'
    }
}

# Main Menu Loop
function Show-MainMenu {
    while ($true) {
        Write-Color "`n=== Main Menu ===" 'Cyan'
        Write-Color "1) Schedule Shutdown"
        Write-Color "2) Delete Shutdown Schedule"
        Write-Color "3) Schedule App Start"
        Write-Color "4) Delete App Start Schedule"
        Write-Color "0) Exit" 'Blue'

        $choice = Read-Host "Enter your choice (0-4)"
        switch ($choice) {
            '1' { Schedule-Shutdown }
            '2' { Delete-ShutdownSchedule }
            '3' { Schedule-AppStart }
            '4' { Delete-AppStartSchedule }
            '0' {
                Write-Color "Goodbye!" 'Cyan'
                return
            }
            default {
                Write-Color "Invalid selection. Please try again." 'Red'
            }
        }
    }
}

Show-MainMenu
