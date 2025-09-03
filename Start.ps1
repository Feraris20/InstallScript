Add-Type -AssemblyName System.Windows.Forms

# Function to create a runspace and run a script block
function Invoke-ActionInRunspace {
    param($scriptBlock)

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $pipeline = $runspace.CreatePipeline()
    $pipeline.Commands.AddScript($scriptBlock)
    $pipeline.Invoke()
    $runspace.Close()
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Actions to Run"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

# Checkboxes
$checkboxes = @()

$cbEnableFeature = New-Object System.Windows.Forms.CheckBox
$cbEnableFeature.Text = "Enable .NET Framework 3.5"
$cbEnableFeature.Location = New-Object System.Drawing.Point(20,20)
$cbEnableFeature.AutoSize = $true
$cbEnableFeature.Checked = $true
$checkboxes += $cbEnableFeature

$cbInstallAppInstaller = New-Object System.Windows.Forms.CheckBox
$cbInstallAppInstaller.Text = "Install Microsoft App Installer"
$cbInstallAppInstaller.Location = New-Object System.Drawing.Point(20,50)
$cbInstallAppInstaller.AutoSize = $true
$cbInstallAppInstaller.Checked = $true
$checkboxes += $cbInstallAppInstaller

$cbInstallApps = New-Object System.Windows.Forms.CheckBox
$cbInstallApps.Text = "Install Applications (VSCode, vcredist, NanaZip, Shell)"
$cbInstallApps.Location = New-Object System.Drawing.Point(20,80)
$cbInstallApps.AutoSize = $true
$cbInstallApps.Checked = $true
$checkboxes += $cbInstallApps

# Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected"
$runButton.Size = New-Object System.Drawing.Size(150,30)
$runButton.Location = New-Object System.Drawing.Point(20,120)

# Add controls
$form.Controls.AddRange($checkboxes + @($runButton))

# Timer for countdown
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 1000

# State variables
$secondsRemaining = 15
$mouseMovedDuringCountdown = $false

# Function to update button text
function Update-ButtonText {
    param($remaining)
    $runButton.Text = "Proceed in $remaining s"
}

# Mouse move event handler
$mouseMoved = {
    if ($countdownTimer.Enabled) {
        $mouseMovedDuringCountdown = $true
        $countdownTimer.Stop()
        $runButton.Text = "Run Selected"
        [System.Windows.Forms.MessageBox]::Show("Mouse moved. Countdown canceled. Click 'Run Selected' to proceed.", "Info")
    }
}
$form.Add_MouseMove($mouseMoved)
$form.Add_MouseDown($mouseMoved)
$form.Add_MouseHover($mouseMoved)

# When form shown
$form.Add_Shown({
    $secondsRemaining = 15
    Update-ButtonText $secondsRemaining
    $countdownTimer.Start()
})

# Timer tick
$countdownTimer.Add_Tick({
    $secondsRemaining--
    if ($secondsRemaining -gt 0) {
        Update-ButtonText $secondsRemaining
    } else {
        $countdownTimer.Stop()
        $runButton.Text = "Running..."
        # Run actions in separate runspaces
        proceedWithActions
    }
})

# Function to run actions in separate runspaces
function proceedWithActions {
    $actions = @()

    # For each selected action, spawn a runspace
    if ($cbEnableFeature.Checked) {
        Invoke-ActionInRunspace {
            # Action script block
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

    # Optionally, wait for all runspaces to complete or do more management
    # For simplicity, we just launch them and don't wait here
    [System.Windows.Forms.MessageBox]::Show("Actions launched in background runspaces.", "Info")
    $runButton.Text = "Run Selected"
}

# Manual run
$runButton.Add_Click({
    if ($countdownTimer.Enabled) {
        $countdownTimer.Stop()
    }
    if ($mouseMovedDuringCountdown) {
        $mouseMovedDuringCountdown = $false
        proceedWithActions
    } else {
        # Already proceeded if countdown finished
    }
})

# Show form
[void]$form.ShowDialog()


exit


Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All
# msg * /time:15 "✅ .NET Framework 3.5 installed successfully."
Write-Output "*****************************************"
Write-Output "Winget version: $(winget --version)"
winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent
Write-Output "*****************************************"
Write-Output "Winget version: $(winget --version)"


$apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "Nilesoft.Shell")
foreach ($app in $apps) { winget install --id=$app --accept-source-agreements --accept-package-agreements --silent }
Write-Output "Winget version: $(winget --version)"
