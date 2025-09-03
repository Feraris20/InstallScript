Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Actions to Run"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

# Create checkboxes
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

# Create the Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected"
$runButton.Size = New-Object System.Drawing.Size(150,30)
$runButton.Location = New-Object System.Drawing.Point(20,120)

# Add controls to form
$form.Controls.AddRange($checkboxes + @($runButton))

# Timer for countdown
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 1000  # 1 second

# Variables
$secondsRemaining = 15
$mouseMovedDuringCountdown = $false
$proceedAutomatically = $false

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
        # [System.Windows.Forms.MessageBox]::Show("Mouse moved. Countdown canceled. Please click 'Run Selected' to proceed.", "Info")
    }
}

# Attach mouse events to form
$form.Add_MouseMove($mouseMoved)
$form.Add_MouseDown($mouseMoved)
$form.Add_MouseHover($mouseMoved)

# When form loads (shown), start countdown
$form.Add_Shown({
    $secondsRemaining = 15
    Update-ButtonText $secondsRemaining
    $countdownTimer.Start()
})

# Timer tick event
$countdownTimer.Add_Tick({
    $secondsRemaining--
    if ($secondsRemaining -gt 0) {
        Update-ButtonText $secondsRemaining
    } else {
        $countdownTimer.Stop()
        $runButton.Text = "Running..."
        # Automatically proceed
        proceedWithActions
    }
})

# Function to perform actions
function proceedWithActions {
    # Disable button to prevent re-entry
    $runButton.Enabled = $false

    # Collect actions
    $actions = @()

    if ($cbEnableFeature.Checked) {
        try {
            [System.Windows.Forms.MessageBox]::Show("Enabling .NET Framework 3.5...", "Info")
            Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
            $actions += ".NET Framework 3.5 enabled"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error enabling .NET Framework: $_", "Error")
        }
    }

    if ($cbInstallAppInstaller.Checked) {
        try {
            [System.Windows.Forms.MessageBox]::Show("Installing Microsoft App Installer...", "Info")
            winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent
            $actions += "Microsoft App Installer installed"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error installing App Installer: $_", "Error")
        }
    }

    if ($cbInstallApps.Checked) {
        try {
            $apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "Nilesoft.Shell")
            foreach ($app in $apps) {
                winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
            }
            $actions += "Applications installed"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error installing applications: $_", "Error")
        }
    }

    if ($actions.Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show("Actions completed:`n" + ($actions -join "`n"), "Done")
    } else {
        [System.Windows.Forms.MessageBox]::Show("No actions were performed.", "Info")
    }
    # Reset button text
    $runButton.Text = "Run Selected"
    $runButton.Enabled = $true
}

# Click event for manual run
$runButton.Add_Click({
    # If countdown active, stop it
    if ($countdownTimer.Enabled) {
        $countdownTimer.Stop()
    }
    if ($mouseMovedDuringCountdown) {
        # User moved mouse, wait for manual click
        $mouseMovedDuringCountdown = $false
        proceedWithActions
    } else {
        # Countdown finished, already proceeded
        proceedWithActions
    }
})

# Show the form
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
