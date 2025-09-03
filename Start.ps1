# Function to detect system theme
function Get-SystemTheme {
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $appsUseLightTheme = (Get-ItemProperty -Path $registryPath -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
        if ($appsUseLightTheme -eq 0) {
            return "Dark"
        } else {
            return "Light"
        }
    } catch {
        return "Light" # Default to Light if detection fails
    }
}

# Variables
$secondsRemaining = 15
$mouseMoved = $false

# Create form
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Actions to Run"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

# Theme colors
$systemTheme = Get-SystemTheme
if ($systemTheme -eq "Dark") {
    $form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $form.ForeColor = [System.Drawing.Color]::White
} else {
    $form.BackColor = [System.Drawing.Color]::White
    $form.ForeColor = [System.Drawing.Color]::Black
}

# Checkboxes
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

# Run button
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

# Update button text
function Update-ButtonText($remaining) {
    $runButton.Text = "Proceed in $remaining s"
}

# Mouse move event to stop countdown
$form.Add_MouseMove({
    $mouseMoved = $true
})

# When form shown, start countdown
$form.Add_Shown({
    $secondsRemaining = 15
    $mouseMoved = $false
    Update-ButtonText $secondsRemaining
    $countdownTimer.Start()
})

# Timer tick: countdown
$countdownTimer.Add_Tick({
    if ($mouseMoved) {
        # Mouse moved, stop countdown and do not proceed
        $countdownTimer.Stop()
        $runButton.Text = "Countdown Stopped"
        return
    }

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
    if ($countdownTimer.Enabled) { $countdownTimer.Stop() }
    proceedWithActions
})

# Helper for background execution
function Invoke-ActionInRunspace {
    param([scriptblock]$scriptBlock)
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    try {
        $pipeline = $runspace.CreatePipeline()
        $pipeline.Commands.AddScript($scriptBlock)
        $pipeline.Invoke()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error executing action: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $runspace.Close()
    }
}

# Actions to perform
function proceedWithActions {
    $runButton.Enabled = $false
    try {
        if ($cbEnableFeature.Checked) {
            Invoke-ActionInRunspace {
                Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop
            }
        }
        if ($cbInstallAppInstaller.Checked) {
            Invoke-ActionInRunspace {
                winget install --id=Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements --silent
            }
        }
        if ($cbInstallApps.Checked) {
            Invoke-ActionInRunspace {
                $apps = @("Microsoft.VisualStudioCode", "abbodi1406.vcredist", "M2Team.NanaZip", "Nilesoft.Shell")
                foreach ($app in $apps) {
                    winget install --id=$app --accept-source-agreements --accept-package-agreements --silent
                }
            }
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $runButton.Text = "Run Selected"
    }
}

# Show form
[void]$form.ShowDialog()