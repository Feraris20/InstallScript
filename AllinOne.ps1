# Combined PowerShell Script with Menu and '0' Return Option
Clear-Host
function Write-Color {
    param (
        [string]$Message,
        [ConsoleColor]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

# Names for the scheduled tasks
$shutdownTaskName = "ScheduledShutdown"
$appStartTaskName = "ScheduledAppStart"

# Function to schedule shutdown
function Schedule-Shutdown {
    # Prompt for time
    while ($true) {
        Write-Color "Enter shutdown time in HH:MM (24-hour format), or 0 to return to main menu:" 'Cyan'
        $timeInput = Read-Host
        if ($timeInput -eq '0') {
            return
        }
        if ($timeInput -match '^(?:[01]\d|2[0-3]):[0-5]\d$') {
            break
        } else {
            Write-Color "Invalid format. Please try again." 'Red'
        }
    }
    # Remove existing task if exists
    if (Get-ScheduledTask -TaskName $shutdownTaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $shutdownTaskName -Confirm:$false
    }
    # Create action
    $action = New-ScheduledTaskAction -Execute "shutdown" -Argument "/s /f /t 0"
    # Create trigger
    $trigger = New-ScheduledTaskTrigger -Daily -At $timeInput
    # Create principal
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    # Register task
    Register-ScheduledTask -TaskName $shutdownTaskName -Action $action -Trigger $trigger -Principal $principal
    Write-Color "Shutdown scheduled at $timeInput." 'Green'
}

# Function to delete shutdown schedule
function Delete-ShutdownSchedule {
    if (Get-ScheduledTask -TaskName $shutdownTaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $shutdownTaskName -Confirm:$false
        Write-Color "Shutdown schedule deleted." 'Green'
    } else {
        Write-Color "No shutdown schedule found." 'Yellow'
    }
}

# Function to schedule app start
function Schedule-AppStart {
    # Prompt for executable path
    do {
        Write-Color "Enter full path to the executable, or 0 to return to main menu:" 'Cyan'
        $inputPath = Read-Host
        if ($inputPath -eq '0') {
            return
        }
        if ($inputPath.StartsWith('"') -and $inputPath.EndsWith('"')) {
            $exePath = $inputPath.Trim('"')
        } else {
            $exePath = $inputPath
        }
        if (-not (Test-Path -Path $exePath -PathType Leaf)) {
            Write-Color "File does not exist. Please try again." 'Red'
            Write-Color "Example: C:\Program Files\MyApp\app.exe" 'Yellow'
            $valid = $false
        } else {
            $valid = $true
        }
    } while (-not $valid)
    # Remove existing task if exists
    if (Get-ScheduledTask -TaskName $appStartTaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $appStartTaskName -Confirm:$false
    }
    # Create trigger and action
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $action = New-ScheduledTaskAction -Execute $exePath
    # Register task
    Register-ScheduledTask -TaskName $appStartTaskName -Trigger $trigger -Action $action -RunLevel Highest
    Write-Color "App start scheduled on logon." 'Green'
}

# Function to delete app start schedule
function Delete-AppStartSchedule {
    if (Get-ScheduledTask -TaskName $appStartTaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $appStartTaskName -Confirm:$false
        Write-Color "App start schedule deleted." 'Green'
    } else {
        Write-Color "No app start schedule found." 'Yellow'
    }
}

# Main menu loop
while ($true) {    
    Write-Color "`n=== Main Menu ===" 'Cyan'
    Write-Color "1) Schedule Shutdown"
    Write-Color "2) Delete Schedule"
    Write-Color "3) Schedule App Start"
    Write-Color "4) Delete Schedule App Start"
    Write-Color "0) Exit (go back on 1 and 3)" 'Blue'
    $choice = Read-Host "Enter your choice (0-4)"

    switch ($choice) {
        '1' {
            Schedule-Shutdown
        }
        '2' {
            Delete-ShutdownSchedule
        }
        '3' {
            Schedule-AppStart
        }
        '4' {
            Delete-AppStartSchedule
        }
        '0' {
            Write-Color "bye bye" 'Cyan'
            # exit
            Break
        }
        default {
            Write-Color "Invalid selection. Please try again." 'Red'
        }
    }
}