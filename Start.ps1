Add-Type -AssemblyName System.Windows.Forms

# Function to detect system theme
function Get-SystemTheme {
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $appsUseLightTheme = (Get-ItemProperty -Path $registryPath -Name "AppsUseLightTheme").AppsUseLightTheme
        if ($appsUseLightTheme -eq 0) {
            return "Dark"
        } else {
            return "Light"
        }
    } catch {
        # Default to Light if detection fails
        return "Light"
    }
}

# Detect theme
$systemTheme = Get-SystemTheme()

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Actions to Run"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

# Set theme colors
if ($systemTheme -eq "Dark") {
    $form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $form.ForeColor = [System.Drawing.Color]::White
} else {
    $form.BackColor = [System.Drawing.Color]::White
    $form.ForeColor = [System.Drawing.Color]::Black
}

# Create checkboxes
$checkboxes = @()

$cbEnableFeature = New-Object System.Windows.Forms.CheckBox
$cbEnableFeature.Text = "Enable .NET Framework 3.5"
$cbEnableFeature.Location = New-Object System.Drawing.Point(20,20)
$cbEnableFeature.AutoSize = $true
$cbEnableFeature.Checked = $true
$cbEnableFeature.BackColor = $form.BackColor
$cbEnableFeature.ForeColor = $form.ForeColor
$checkboxes += $cbEnableFeature

$cbInstallAppInstaller = New-Object System.Windows.Forms.CheckBox
$cbInstallAppInstaller.Text = "Install Microsoft App Installer"
$cbInstallAppInstaller.Location = New-Object System.Drawing.Point(20,50)
$cbInstallAppInstaller.AutoSize = $true
$cbInstallAppInstaller.Checked = $true
$cbInstallAppInstaller.BackColor = $form.BackColor
$cbInstallAppInstaller.ForeColor = $form.ForeColor
$checkboxes += $cbInstallAppInstaller

$cbInstallApps = New-Object System.Windows.Forms.CheckBox
$cbInstallApps.Text = "Install Applications (VSCode, vcredist, NanaZip, Shell)"
$cbInstallApps.Location = New-Object System.Drawing.Point(20,80)
$cbInstallApps.AutoSize = $true
$cbInstallApps.Checked = $true
$cbInstallApps.BackColor = $form.BackColor
$cbInstallApps.ForeColor = $form.ForeColor
$checkboxes += $cbInstallApps

# Create the Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected"
$runButton.Size = New-Object System.Drawing.Size(150,30)
$runButton.Location = New-Object System.Drawing.Point(20,120)
$runButton.BackColor = $form.BackColor
$runButton.ForeColor = $form.ForeColor

# Add controls to form
$form.Controls.AddRange($checkboxes + @($runButton))

# Timer for countdown
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 1000  # 1 second

# Variables
$secondsRemaining = 15
$initialMousePosition = [System.Drawing.Point]::new(0,0)
$mouseMovedDuringCountdown = $false

# Function to update button text
function Update-ButtonText {
    param($remaining)
    $runButton.Text = "Proceed in $remaining s"
}

# Function to run actions in separate runspaces
function Invoke-ActionInRunspace {
    param($scriptBlock)

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $pipeline = $runspace.CreatePipeline()
    $pipeline.Commands.AddScript($scriptBlock)
    $pipeline.Invoke()
    $runspace.Close()
}

# Function to perform actions
function proceedWithActions {
    # Disable button to prevent re-entry
    $runButton.Enabled = $false

    # Launch each selected action in its own runspace
    if ($cbEnableFeature.Checked) {
        Invoke-ActionInRunspace {
            try {
                Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
                Write-Output ".NET Framework 3.5 enabled"
            } catch {
                Write-Output "Error enabling .NET Framework: $_"
            }
        }
    }

    if ($cbInstallAppInstaller.Checked) {
        Invoke-ActionInRunspace {
            try {
                winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent
                Write-Output "Microsoft App Installer installed"
            } catch {
                Write-Output "Error installing App Installer: $_"
            }
        }
    }

    if ($cbInstallApps.Checked) {
        Invoke-ActionInRunspace {
            try {
                $apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "Nilesoft.Shell")
                foreach ($app in $apps) {
                    winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
                }
                Write-Output "Applications installed"
            } catch {
                Write-Output "Error installing applications: $_"
            }
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Actions launched in background runspaces.", "Info")
    $runButton.Text = "Run Selected"
}

# When form is shown, record initial mouse position and start countdown
$form.Add_Shown({
    # Record the initial mouse position
    $initialMousePosition = [System.Drawing.Point]::new([System.Windows.Forms.Cursor]::Position.X, [System.Windows.Forms.Cursor]::Position.Y)
    $secondsRemaining = 15
    Update-ButtonText $secondsRemaining
    $countdownTimer.Start()
})

# Timer tick event
$countdownTimer.Add_Tick({
    # Check current mouse position
    $currentPosition = [System.Drawing.Point]::new([System.Windows.Forms.Cursor]::Position.X, [System.Windows.Forms.Cursor]::Position.Y)
    if ($currentPosition.X -ne $initialMousePosition.X -or $currentPosition.Y -ne $initialMousePosition.Y) {
        # Mouse moved
        $mouseMovedDuringCountdown = $true
        $countdownTimer.Stop()
        $runButton.Text = "Run Selected"
        [System.Windows.Forms.MessageBox]::Show("Mouse moved. Countdown canceled. Click 'Run Selected' to proceed.", "Info")
        return
    }

    # No movement, continue countdown
    $secondsRemaining--
    if ($secondsRemaining -gt 0) {
        Update-ButtonText $secondsRemaining
    } else {
        $countdownTimer.Stop()
        $runButton.Text = "Running..."
        proceedWithActions
    }
})

# Manual run button click
$runButton.Add_Click({
    if ($countdownTimer.Enabled) {
        $countdownTimer.Stop()
    }
    if ($mouseMovedDuringCountdown) {
        $mouseMovedDuringCountdown = $false
        proceedWithActions
    }
    # Else, countdown already finished
})

# Show form
[void]$form.ShowDialog()