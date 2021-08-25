
# TODO code structure and testing
# TODO add warning - tool usage 
# TODO add actions 
# TODO settings for background mode 



# log function
function log($logMsg) {
    $timestamp = Get-Date -Format "[MM/dd/yyyy-HH:mm:ss ffff]"
    Write-Host Log $timestamp : $logMsg
}

log "tool startup"

# WinForms Icon - Create Icon Extractor Assembly - to get system icons
$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
	public class IconExtractor
	{

	 public static Icon Extract(string file, int number, bool largeIcon)
	 {
	  IntPtr large;
	  IntPtr small;
	  ExtractIconEx(file, number, out large, out small, 1);
	  try
	  {
	   return Icon.FromHandle(largeIcon ? large : small);
	  }
	  catch
	  {
	   return null;
	  }

	 }
	 [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	 private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

	}
}
"@

# Imports
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore, PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

# constants
$shortcutFileName = "NAL.lnk"
$runFile = "run.bat"
$historyStart = 6
$link = 'www.linkedin.com/in/ananduvt'

# $keys = @('{CAPSLOCK}', '{NUMLOCK}')
$time1List = @(2000, 5000, 7000, 10000, 150000)
$time2List = @(100, 300, 500, 1000, 2000, 5000)

# variables
$settingFile = $env:LOCALAPPDATA + '\NALSettings.txt'
$settings = @('delay1=1000', `
        'delay2=100', `
        'mouseMove=False', `
        'soundOn=False', `
        'autoStart=False', `
        'history', `
        "StartTime `t StopTime `t RunTime") 

$currentHistory = ''
$history = ''

$capsState = [System.Windows.Forms.Control]::IsKeyLocked( 'CapsLock' )
$numState = [System.Windows.Forms.Control]::IsKeyLocked( 'NumLock' )
$keyToUse = @('{NUMLOCK}')
$time1 = 1000
$time2 = 100
$mouseMove = $false
$soundOn = $false
$autoStart = $false
$time = 0
$jobId = ''

function createSettings {
    $null = New-Item $settingFile
    Set-Content -Path $settingFile -Value $settings
}

function updateSettings {
    Set-Content -Path $settingFile -Value $settings
    $script:history = $settings[$historyStart..$settings.Length]
}

function clearHistory() {
    Set-Content -Path $settingFile -Value $settings[0..$historyStart]
    $script:settings = Get-Content -Path $settingFile
    $script:history = $null
}

function createHistory {   
    $script:currentHistory = get-date
}

function updateHistory {
    if ($StartButton.Text -eq 'STOP') {
        $timeNow = get-date
        $duration = $timeNow - $script:currentHistory 
        $script:currentHistory = ($script:currentHistory.tostring() + "`t" + $timeNow.tostring() + "`t" + $duration.tostring().Split(".")[0])
       
        #$time = ($duration.tostring().Split(".")[0].Split(':')[1]) -as [int] 
        $script:settings += $script:currentHistory 
        updateSettings
        # if($time -gt 10){
           
        # }
    }
}

function createShortcut() {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutFile = $desktopPath + '\' + $shortcutFileName

    $ScriptName = $MyInvocation.ScriptName
    $scriptDir = Split-Path $scriptname -Parent
    $target = $scriptDir + '\' + $runFile

    if (Test-Path $shortcutFile ) {
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = 'Shorcut Available'
        $Messageboxbody = 'Shortcut to run the tool already available in your Desktop'
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        $null = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)
        Start-Process -FilePath C:\Windows\explorer.exe -ArgumentList "/select, ""$shortcutFile"""
    }
    else {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutFile) 
        $Shortcut.TargetPath = $target
        $Shortcut.WorkingDirectory = $scriptDir
        $Shortcut.Save()

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = 'Shorcut Created'
        $Messageboxbody = 'Shortcut to run the tool created and available in your Desktop'
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        $null = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)
    }
}

function initApp() {
    # check for settings file 
    if (Test-Path $settingFile) {
        log "settings available"
        $script:settings = Get-Content -Path $settingFile
    }
    else {
        log "create settings"
        createSettings
    }

    # load settings
    log "load settings"
    $script:history = $script:settings[$historyStart..$settings.Length]
    $script:time1 = $settings[0].Split('=')[1]
    $script:time2 = $settings[1].Split('=')[1]

    if ($settings[2].Split('=')[1] -eq 'True') {
        $script:mouseMove = $true
    }
    else {
        $script:mouseMove = $false
    }
    if ($settings[3].Split('=')[1] -eq 'True') {
        $script:soundOn = $true
    }
    else {
        $script:soundOn = $false
    }

    if ($settings[4].Split('=')[1] -eq 'True') {
        $script:autoStart = $true
    }
    else {
        $script:autoStart = $false
    }
}

# main form elements
$form = New-Object System.Windows.Forms.Form
$menuSettings = New-Object System.Windows.Forms.ToolStripMenuItem
$menuAbout = New-Object System.Windows.Forms.ToolStripMenuItem
$menuHistory = New-Object System.Windows.Forms.ToolStripMenuItem
$menuAction = New-Object System.Windows.Forms.ToolStripMenuItem
$StartButton = New-Object System.Windows.Forms.Button
$ProgressBar1 = New-Object system.Windows.Forms.ProgressBar
$labelT = New-Object System.Windows.Forms.Label
$timer = New-Object System.Windows.Forms.Timer
$labelL = New-Object System.Windows.Forms.Label
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel

$keyImage1 = New-Object System.Windows.Forms.PictureBox
$keyImage2 = New-Object System.Windows.Forms.PictureBox
$mouseImage1 = New-Object System.Windows.Forms.PictureBox
$mouseImage2 = New-Object System.Windows.Forms.PictureBox
$soundImage1 = New-Object System.Windows.Forms.PictureBox
$soundImage2 = New-Object System.Windows.Forms.PictureBox

function showSettings {
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = 'No Auto Lock - Settings'
    $settingsForm.opacity = 0.85
    $settingsForm.BackColor = 'black'
    $settingsForm.Size = New-Object System.Drawing.Size(355, 230)
    $settingsForm.StartPosition = 'CenterScreen'
    $settingsForm.Topmost = $true
    $settingsForm.MinimumSize = New-Object System.Drawing.Size(365, 230)
    $settingsForm.MaximumSize = New-Object System.Drawing.Size(365, 230)
    $settingsForm.MaximizeBox = $false
    $settingsForm.MinimizeBox = $false 
    $settingsForm.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $settingsForm.Icon = [System.IconExtractor]::Extract("shell32.dll", 72, $true)

    $checkCaps = New-Object system.Windows.Forms.CheckBox
    $checkCaps.text = " Caps Lock"
    $checkCaps.AutoSize = $false
    $checkCaps.width = 95
    $checkCaps.height = 20
    $checkCaps.location = New-Object System.Drawing.Point(220, 30)
    $checkCaps.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $checkCaps.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    
    if ('{CAPSLOCK}' -in $keyToUse) {
        $checkCaps.Checked = $true
    }

    $checkCaps.Add_CheckStateChanged( {
            if ($checkCaps.Checked) {
                $keyToUse = $keyToUse += '{CAPSLOCK}'
            }
            else {
                $keyToUse = $keyToUse -ne '{CAPSLOCK}'
            }
            updateStatus
        })
    
    $checkNum = New-Object system.Windows.Forms.CheckBox
    $checkNum.text = " Num Lock"
    $checkNum.AutoSize = $false
    $checkNum.width = 95
    $checkNum.height = 20
    $checkNum.location = New-Object System.Drawing.Point(220, 60)
    $checkNum.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $checkNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")

    if ('{NUMLOCK}' -in $keyToUse) {
        $checkNum.Checked = $true
    }

    $checkNum.Add_CheckStateChanged( {
            if ($checkNum.Checked) {
                $keyToUse = $keyToUse += '{NUMLOCK}'
            }
            else {
                $keyToUse = $keyToUse -ne '{NUMLOCK}' 
            }
            updateStatus
        })

    $Label1 = New-Object system.Windows.Forms.Label
    $Label1.text = "Delay 1 : "
    $Label1.AutoSize = $true
    $Label1.width = 25
    $Label1.height = 10
    $Label1.location = New-Object System.Drawing.Point(30, 30)
    $Label1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
    $Label1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")

    $ComboBox1 = New-Object system.Windows.Forms.ComboBox
    $ComboBox1.text = ""
    $ComboBox1.width = 100
    $ComboBox1.height = 20
    $ComboBox1.location = New-Object System.Drawing.Point(95, 30)
    $ComboBox1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $ComboBox1.BackColor = 'black'
    $ComboBox1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $time1List | ForEach-Object { [void] $ComboBox1.Items.Add($_) }
    $ComboBox1.text = $script:time1
    $ComboBox1.add_SelectedIndexChanged( {
            $script:time1 = $ComboBox1.Text
            $settings[0] = 'delay1=' + $ComboBox1.Text
            updateSettings
            updateStatus
        })
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($ComboBox1, "The Delay between key press")
    $tooltip.SetToolTip($Label1, "The Delay between key press")

 
    $ComboBox2 = New-Object system.Windows.Forms.ComboBox
    $ComboBox2.text = ""
    $ComboBox2.width = 100
    $ComboBox2.height = 20
    $ComboBox2.location = New-Object System.Drawing.Point(95, 60)
    $ComboBox2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $ComboBox2.BackColor = 'black'
    $ComboBox2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $time2List | ForEach-Object { [void] $ComboBox2.Items.Add($_) }
    $ComboBox2.Text = $script:time2
    $ComboBox2.add_SelectedIndexChanged( {
            $script:time2 = $ComboBox2.Text
            $settings[1] = 'delay2=' + $ComboBox2.Text
            updateSettings
            updateStatus
        })
 
    $Label2 = New-Object system.Windows.Forms.Label
    $Label2.text = "Delay 2 : "
    $Label2.AutoSize = $true
    $Label2.width = 25
    $Label2.height = 10
    $Label2.location = New-Object System.Drawing.Point(30, 60)
    $Label2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
    $Label2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")

    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($ComboBox2, "The Delay between key toggle")
    $tooltip.SetToolTip($Label2, "The Delay between key toggle")

    $checkMM = New-Object system.Windows.Forms.CheckBox
    $checkMM.text = "Enable Mouse Move"
    $checkMM.AutoSize = $true
    #$checkMM.width = 95
    $checkMM.height = 20
    $checkMM.location = New-Object System.Drawing.Point(30, 100)
    $checkMM.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
    $checkMM.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $checkMM.Checked = $mouseMove
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($checkMM, "Enable Mouse movement")

    $checkMM.Add_CheckStateChanged( {
            $script:mouseMove = $checkMM.Checked
            $settings[2] = 'mouseMove=' + $checkMM.Checked
            updateStatus
            updateSettings
        })

    $checkES = New-Object system.Windows.Forms.CheckBox
    $checkES.text = "Enable Sound"
    $checkES.AutoSize = $true
    #$checkMM.width = 95
    $checkES.height = 20
    $checkES.location = New-Object System.Drawing.Point(220, 100)
    $checkES.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
    $checkES.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $checkES.Checked = $soundOn
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($checkES, "Enable sound notification while tool running")
    $checkES.Add_CheckStateChanged( {
            $script:soundOn = $checkES.Checked
            $settings[3] = 'soundOn=' + $checkES.Checked
            updateStatus
            updateSettings
        })
      
    $CheckBox5 = New-Object system.Windows.Forms.CheckBox
    $CheckBox5.text = "Auto run on Startup"
    $CheckBox5.AutoSize = $true
    #$checkMM.width = 95
    $CheckBox5.height = 20
    $CheckBox5.location = New-Object System.Drawing.Point(120, 130)
    $CheckBox5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
    $CheckBox5.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $CheckBox5.Checked = $autoStart
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($CheckBox5, "The tool will automatically start runnuing on tool startup")
    $CheckBox5.Add_CheckStateChanged( {
            $script:autoStart = $CheckBox5.Checked
            $settings[4] = 'autoStart=' + $CheckBox5.Checked
            updateStatus
            updateSettings
        })    

    $StartButton = New-Object System.Windows.Forms.Button
    $StartButton.Location = New-Object System.Drawing.Point(120, 160)
    $StartButton.Size = New-Object System.Drawing.Size(120, 25)
    $StartButton.Text = "Create Shortcut"
    $StartButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#333333")
    $StartButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $StartButton.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $StartButton.Add_Click( { createShortcut })

    $settingsForm.controls.AddRange(@($checkCaps, $checkNum, $ComboBox1, $ComboBox2, $Label1, $Label2, $checkMM, $checkES, $CheckBox5, $StartButton))
    function checkSettings {
        if ($checkCaps.Checked -or $checkNum.Checked -or $checkMM.Checked -or $checkES.Checked) {

        }
        else {
            $settingsForm.close() 
            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = 'Choose an Option '
            $Messageboxbody = 'Please Choose an option to run the Tool'
            $MessageIcon = [System.Windows.MessageBoxImage]::Warning
            [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)
            
            showSettings  
        }
    }

    $null = $settingsForm.ShowDialog()

    checkSettings
}

function showAbout {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = 'No Auto Lock - About'
    $aboutForm.opacity = 0.85
    $aboutForm.BackColor = 'black'
    $aboutForm.Size = New-Object System.Drawing.Size(610, 400)
    $aboutForm.StartPosition = 'CenterScreen'
    $aboutForm.Topmost = $true
    $aboutForm.MinimumSize = New-Object System.Drawing.Size(610, 400)
    $aboutForm.MaximumSize = New-Object System.Drawing.Size(610, 400)
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false 
    $aboutForm.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $aboutForm.Icon = [System.IconExtractor]::Extract("shell32.dll", 80, $true)

    $aboutLabel = New-Object system.Windows.Forms.Label
    $aboutLabel.text = "No Auto Lock"
    $aboutLabel.TextAlign = 'MiddleCenter'
    #$aboutLabel.AutoSize = $true
    $aboutLabel.width = 200
    #$aboutLabel.height = 10
    $aboutLabel.location = New-Object System.Drawing.Point(200, 10)
    $aboutLabel.Font = New-Object System.Drawing.Font('Arial', 12, [System.Drawing.FontStyle]::Bold)
    $aboutLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#33e8d5")

    $aboutLabel2 = New-Object system.Windows.Forms.Label
    $aboutLabel2.text = "Hi " + $env:USERNAME + ",`n`n" `
        + "This tool helps to prevent the computer from auto-locking itself due to the auto-lock settings, especially in corporate machines."`
        + "To achieve this the tool can simulate 2 events`n`n"`
        + "1) Keyboard press event `nThe specified key is pressed twice within short time delay (Delay2) and this process repeated with a delay (Delay1)."`
        + " The keys to simulate and delay between keypress can be configured in settings. The keys which have an LED indicator is used (Num Lock / Caps Lock) "`
        + "so that it could help to quickly understand whether the Tool is running or not from the LED blinking`n`n"`
        + "2) Mouse move event `nMouse movement can be enabled from the settings. The mouse cursor will move between the 4 quadrants of the screen`n`n"`
        + "Any one of the above events or both of the events can be used. The tool has an option to make a sound notification during key press."`
        + "The history of the tool usage is also captured"

    $aboutLabel2.TextAlign = 'MiddleCenter'
    #$abouLabel2.AutoSize             = $true
    $aboutLabel2.width = 580
    $aboutLabel2.height = 300
    $aboutLabel2.location = New-Object System.Drawing.Point(10, 25)
    $aboutLabel2.Font = New-Object System.Drawing.Font('Arial', 10)
    $aboutLabel2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")

    $aboutLabel3 = New-Object system.Windows.Forms.Label
    $aboutLabel3.text = "Share your comments"
    $aboutLabel3.TextAlign = 'MiddleCenter'
    #$aboutLabel.AutoSize = $true
    $aboutLabel3.width = 200
    #$aboutLabel.height = 10
    $aboutLabel3.location = New-Object System.Drawing.Point(200, 320)
    $aboutLabel3.Font = New-Object System.Drawing.Font('Consolas', 11, [System.Drawing.FontStyle]::Regular)
    $aboutLabel3.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#398dd1")
    $aboutLabel3.add_Click( { [system.Diagnostics.Process]::start($link) })
    $aboutLabel3.Add_MouseHover( { $aboutLabel3.forecolor = [System.Drawing.ColorTranslator]::FromHtml("#9ff000") })
    $aboutLabel3.Add_MouseLeave( { $aboutLabel3.forecolor = [System.Drawing.ColorTranslator]::FromHtml("#398dd1") })
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($aboutLabel3, "Click Here")

    $aboutForm.controls.AddRange(@($aboutLabel, $aboutLabel2, $aboutLabel3))

    $null = $aboutForm.ShowDialog()
}

function showHistory {
    
    if ($script:history.Length -lt 2) {
        
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = 'No History'
        $Messageboxbody = 'Sorry, it seems you are yet to try the tool or the no history available so far'
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)

    }
    else {
        $historyForm = New-Object System.Windows.Forms.Form
        $historyForm.Text = 'No Auto Lock - History'
        $historyForm.opacity = 0.85
        $historyForm.BackColor = 'black'
        $historyForm.StartPosition = 'CenterScreen'
        $historyForm.Topmost = $true
        $historyForm.MaximizeBox = $false
        $historyForm.MinimizeBox = $false 
        $historyForm.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
        $historyForm.Icon = [System.IconExtractor]::Extract("shell32.dll", 277, $true)
       
        $mainPanel = New-Object system.Windows.Forms.Panel
        $mainPanel.AutoScroll = $true
        $mainPanel.Dock = 'Fill'
        
        $dataGridView = New-Object System.Windows.Forms.DataGridView     
        $dataGridView.Name = "History"       
        $dataGridView.ColumnCount = 4
        $dataGridView.ColumnHeadersVisible = $true
        $dataGridView.ForeColor = 'white'
        $dataGridView.AllowUserToResizeColumns = $false
        $dataGridView.AllowUserToResizeRows = $false
        $dataGridView.BackgroundColor = 'black'
                 
        $dataGridView.Columns[0].Name = "#"
        $dataGridView.Columns[0].SortMode = 'NotSortable' 
        $dataGridView.Columns[1].Name = "Start Time"
        $dataGridView.Columns[1].SortMode = 'NotSortable' 
        $dataGridView.Columns[2].Name = "Stop Time"
        $dataGridView.Columns[2].SortMode = 'NotSortable' 
        $dataGridView.Columns[3].Name = "Duration"
        $dataGridView.Columns[3].SortMode = 'NotSortable' 
        
        $dataGridView.EnableHeadersVisualStyles = $false
        $dataGridView.ColumnHeadersDefaultCellStyle.ForeColor = 'white'
        $dataGridView.ColumnHeadersDefaultCellStyle.BackColor = 'black'
        $dataGridView.RowHeadersDefaultCellStyle.ForeColor = 'white'
        $dataGridView.RowHeadersDefaultCellStyle.BackColor = 'Black'
        $dataGridView.AutoSizeColumnsMode = 'AllCells'
        $dataGridView.DefaultCellStyle.ForeColor = 'White'
        $dataGridView.DefaultCellStyle.BackColor = 'Black'
        $dataGridView.ReadOnly = $true
        $dataGridView.AllowUserToDeleteRows = $false

        for ($i = 1; $i -lt $script:history.Length; $i++) {
            $rowData = @($i) + @($script:history[$i].Split("`t"))
            $dataGridView.Rows.Add($rowData)
        }

        $totalDuration = 0
        foreach ($row in $datagridview.Rows) {
            if ($row.Cells[3].value) {
                $totalDuration += $row.Cells[3].value -as [timespan]
            }
        }

        $dataGridView.Rows.Add(@('', '', ''))
        $dataGridView.Rows.Add(@('', 'Total RunTime', '', $totalDuration))
        $i = $dataGridView.Rows.Count
        $dataGridView.Rows[$i - 2].Cells[0].style.ForeColor = 'red'
        $dataGridView.Rows[$i - 2].Cells[2].style.ForeColor = 'red'
        $dataGridView.FirstDisplayedScrollingRowIndex = ($i - 2)
        $dataGridView.Rows[$i - 2].Selected = $true
        $dataGridView.Anchor = 'Top, Left'
        $dataGridView.Dock = 'Fill'

        $mainPanel.Controls.Add($dataGridView)
        $historyForm.Controls.add($mainPanel)

        if ($dataGridView.PreferredSize.Height -gt 550) {
            $historyForm.MinimumSize = New-Object System.Drawing.Size(($dataGridView.PreferredSize.Width + 5), ($dataGridView.PreferredSize.Height + 10))
            $historyForm.MaximumSize = New-Object System.Drawing.Size(($dataGridView.PreferredSize.Width + 5), 550)
            $historyForm.Size = New-Object System.Drawing.Size(($dataGridView.PreferredSize.Width + 10), ($dataGridView.PreferredSize.Height + 10))
        }
        else {
            $historyForm.MinimumSize = New-Object System.Drawing.Size(($dataGridView.PreferredSize.Width - 10), ($dataGridView.PreferredSize.Height + 10))
            $historyForm.MaximumSize = New-Object System.Drawing.Size(($dataGridView.PreferredSize.Width - 10), ($dataGridView.PreferredSize.Height + 10))
            $historyForm.Size = New-Object System.Drawing.Size(($dataGridView.PreferredSize.Width), ($dataGridView.PreferredSize.Height + 10))
        }

        $null = $historyForm.ShowDialog()
    }
}

function showActions {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = 'No Auto Lock - actions '
    $aboutForm.opacity = 0.85
    $aboutForm.BackColor = 'black'
    $aboutForm.Size = New-Object System.Drawing.Size(610, 400)
    $aboutForm.StartPosition = 'CenterScreen'
    $aboutForm.Topmost = $true
    $aboutForm.MinimumSize = New-Object System.Drawing.Size(610, 400)
    $aboutForm.MaximumSize = New-Object System.Drawing.Size(610, 400)
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false 
    $aboutForm.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $aboutForm.Icon = [System.IconExtractor]::Extract("shell32.dll", 80, $true)

    $checkDo = New-Object system.Windows.Forms.CheckBox
    $checkDo.text = "Do"
    $checkDo.AutoSize = $false
    $checkDo.width = 95
    $checkDo.height = 20
    $checkDo.location = New-Object System.Drawing.Point(220, 30)
    $checkDo.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $checkDo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $checkDo.Add_CheckStateChanged( {

        })
    # Shutdown tool at 
    # when - after time or at time  
    # action- log off, shutdown , lock , 


    # $cmd = 'pwd'
    # & $cmd

    # lock machine 
    # rundll32.exe user32.dll,LockWorkStation  

    $aboutForm.controls.AddRange(@( $checkDo))
    $null = $aboutForm.ShowDialog()
}

function updateStatus {
    $statusMsg = "Keys: " 
    foreach ($key in $keyToUse) {

        $key = $key -replace '{' -replace '}'
        if ($statusMsg -eq "Keys: " ) {
            $statusMsg += $key 
        }
        else {
            $statusMsg += ' && ' + $key
        }
    }

    if ($statusMsg -eq "Keys: " ) {
        $statusMsg = ""
    }
    else {
        $statusMsg += "  && "
    }

    $statusLabel.Text = $statusMsg + "Delays : " + $time1 + ' , ' + $time2 

    if ($keyToUse.Length -gt 0) {
        $keyImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 101, $true).ToBitmap()
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($keyImage1, "key Press Enabled")
    }
    else {
        $keyImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 93, $true).ToBitmap()
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($keyImage1, "key Press Disabled")
    }

    if ($mouseMove) {
        $mouseImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 101, $true).ToBitmap()
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($mouseImage1, "Mouse Move Enabled")
    }
    else {
        $mouseImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 93, $true).ToBitmap()
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($mouseImage1, "Mouse Move Disabled")
    }

    if ($soundOn) {
        $soundImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 101, $true).ToBitmap()
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($soundImage1, "Sound Enabled")
    }
    else {
        $soundImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 93, $true).ToBitmap()
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($soundImage1, "Sound Disabled")
    }
}

function notifyMinRun {
    $balloon = New-Object System.Windows.Forms.NotifyIcon
    $balloon.Icon = [System.IconExtractor]::Extract("shell32.dll", 265, $true)
    $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $balloon.BalloonTipText = '"No Auto Lock" tool is still running minimized'
    $balloon.BalloonTipTitle = "Attention $Env:USERNAME"
    $balloon.Visible = $true 
    $balloon.ShowBalloonTip(5000)
    $balloon.Dispose()
}

$timerJob = {

    $script:time = $script:time + 1
    $hr = [System.Math]::Floor($script:time / (60 * 60))
    $min = [System.Math]::Floor($script:time / 60)
    $min = $min - ($hr * 60)
    $sec = ($script:time - (($hr * 60 * 60) + ($min * 60)))

    if ($hr -gt 0) {
        $labelT.Text = 'Hour: ' + $hr + '  Minutes: ' + $min + '  Seconds: ' + $sec   
    }
    elseif ($min -gt 0) {
        $labelT.Text = 'Minutes: ' + $min + '  Seconds: ' + $sec   
    }
    else {
        $labelT.Text = 'Seconds: ' + $sec 
    }

    if ($sec -eq 59) {
        if ($form.WindowState -eq 'Minimized') {
            log "send notification"
            notifyMinRun
        }
    }


    # $val = get-Job | Receive-job
    # if ($val -gt 0) {
    #     $mouseImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 93, $true).ToBitmap()
    # }
    # else {
    #     $mouseImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 101, $true).ToBitmap()
    # }
}

$job = {

    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

    function makeSound {
        [console]::beep(1500, 40)
        # [console]::beep(2000, 30)
        [console]::beep(2500, 40)
    }

    $pos = [System.Windows.Forms.Cursor]::Position 
    $mmDelay = 0
    $mmDelayVal = 5
    Function moveMouse {
        $script:posEx = [System.Windows.Forms.Cursor]::Position
        $mmDelay
        if ($script:pos -eq $script:posEx) {
            if ($script:mmDelay -le 0) {
                $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
                $xVal = $screen.width / 2
                $yVal = $screen.height / 2     
                $delta = $screen.Height / 4

                if ($script:mmDelay -eq 0) {        
                    $script:mmDelay --
                }
                else {
                    switch ([Math]::Abs($script:mmDelay % 4)) {
                        0 {
                            $xVal += $delta
                            $yVal += $delta  
                        }
                        1 {
                            $xVal += $delta
                            $yVal -= $delta 
                        }
                        2 {
                            $xVal -= $delta
                            $yVal -= $delta
                        }
                        3 {
                            $xVal -= $delta
                            $yVal += $delta
                        }
                    }
                    $script:mmDelay --
                }
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($xVal , $yVal)
                $script:pos = New-Object System.Drawing.Point($xVal , $yVal)           
            }
            else {
                $script:mmDelay--
            }
        }
        else {
            $script:mmDelay = $script:mmDelayVal
            $script:pos = [System.Windows.Forms.Cursor]::Position
        }
    }

    $wshell = New-Object -ComObject wscript.shell;
    while ($TRUE) {

        foreach ($key in $args[0]) {
            $wshell.SendKeys($key)
        }
        Start-Sleep -Milliseconds $args[2]
        foreach ($key in $args[0]) {
            $wshell.SendKeys($key)
        }

        if ($args[3]) {
            moveMouse
        }
        if ($args[4]) {
            makeSound
        }  
   
        Start-Sleep -Milliseconds $args[1] 
    }
}

function loadUI () {
 
    # Main form 
    $form.Text = 'No Auto Lock '
    $form.opacity = 0.8
    $form.BackColor = 'black'
    $form.Size = New-Object System.Drawing.Size(300, 290)
    $form.StartPosition = 'CenterScreen'
    $form.Topmost = $true
    $form.MinimumSize = New-Object System.Drawing.Size(300, 290)
    $form.MaximumSize = New-Object System.Drawing.Size(300, 290)
    $Form.MaximizeBox = $false
    # $Form.MinimizeBox = $false 
    $form.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $Form.Icon = [System.IconExtractor]::Extract("shell32.dll", 265, $true)
   
    $menuMain = New-Object System.Windows.Forms.MenuStrip
    $menuMain.BackColor = 'black'
    $Form.Controls.Add($menuMain)

    $menuSettings.Text = "&Settings"
    $menuSettings.ForeColor = 'white'
    $menuSettings.BackColor = 'black'
    $menuSettings.Add_MouseHover( { $menuSettings.ForeColor = 'black' })
    $menuSettings.Add_MouseLeave( { $menuSettings.ForeColor = 'white' })
    $menuSettings.Add_Click( { log "show settings"
            showSettings })
    [void]$menuMain.Items.Add($menuSettings)

    $menuAbout.Text = "&About"
    $menuAbout.ForeColor = 'white'
    $menuAbout.BackColor = 'black'
    $menuAbout.Add_MouseHover( { $menuAbout.ForeColor = 'black' })
    $menuAbout.Add_MouseLeave( { $menuAbout.ForeColor = 'white' })
    $menuAbout.Add_Click( { log "show about"
            showAbout })
    [void]$menuMain.Items.Add($menuAbout)

    $menuHistory.Text = "&History"
    $menuHistory.ForeColor = 'white'
    $menuHistory.BackColor = 'black'
    $menuHistory.Add_MouseHover( { $menuHistory.ForeColor = 'black' })
    $menuHistory.Add_MouseLeave( { $menuHistory.ForeColor = 'white' })
    $menuHistory.Add_Click( { 
            log "show history"
            showHistory })
    $historyCheck = 0
    $menuHistory.Add_MouseUP( {
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) {
                if ($historyCheck -gt 4) {
                    $script:historyCheck = 0
                    $ButtonType = [System.Windows.MessageBoxButton]::OKCancel
                    $MessageboxTitle = 'Delete History'
                    $Messageboxbody = 'Do you want to clear the History of tool usage ?'
                    $MessageIcon = [System.Windows.MessageBoxImage]::Warning
                    $val = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)

                    if ($val -eq 'OK' ) {
                        clearHistory
                    }

                }
                $script:historyCheck++
            } })
    [void]$menuMain.Items.Add($menuHistory)

    $menuAction.Text = "&Actions"
    $menuAction.ForeColor = 'white'
    $menuAction.BackColor = 'black'
    $menuAction.Add_MouseHover( { $menuAction.ForeColor = 'black' })
    $menuAction.Add_MouseLeave( { $menuAction.ForeColor = 'white' })
    $menuAction.Add_Click( {
            log "show actions"
            showActions })
    [void]$menuMain.Items.Add($menuAction)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, (20))
    $label.Size = New-Object System.Drawing.Size(265, 35)
    $label.TextAlign = 'MiddleCenter'
    $label.ForeColor = 'white'
    # $label.BackColor = 'Moccasin'
    $label.Text = "Prevents the Computer from Auto Lock"
    $form.Controls.Add($label)
    $tooltip = New-Object System.Windows.Forms.ToolTip
    $tooltip.SetToolTip($label, "Tool simulates keystrokes on specific time period to prevent the machine from being idle")

    $labelL1 = New-Object System.Windows.Forms.Label
    $labelL1.Location = New-Object System.Drawing.Point(10, (50))
    $labelL1.Size = New-Object System.Drawing.Size(265, 20)
    $labelL1.TextAlign = 'MiddleCenter'
    $labelL1.ForeColor = 'white'
    # $labelT.BackColor = 'Magenta'
    $labelL1.Text = '___________________________________________'
    $form.Controls.Add($labelL1)

    $labelL.Location = New-Object System.Drawing.Point(10, (70))
    $labelL.Size = New-Object System.Drawing.Size(265, 20)
    $labelL.TextAlign = 'MiddleCenter'
    $labelL.ForeColor = 'white'
    # $labelT.BackColor = 'Magenta'
    $labelL.Text = 'Press START'
    $form.Controls.Add($labelL)

    $labelT.Location = New-Object System.Drawing.Point(10, (95))
    $labelT.Size = New-Object System.Drawing.Size(265, 20)
    $labelT.TextAlign = 'MiddleCenter'
    $labelT.ForeColor = 'white'
    # $labelT.BackColor = 'Magenta'
    $labelT.Text = ''
    $form.Controls.Add($labelT)

    
    $StartButton.Location = New-Object System.Drawing.Point(95, 130)
    $StartButton.Size = New-Object System.Drawing.Size(95, 30)
    $StartButton.Text = "START"
    $StartButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4DEE56")
    $StartButton.Font = New-Object System.Drawing.Font("Lucida Console", 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($StartButton)

    $StartButton.Add_Click( {    
            if ($StartButton.Text -eq 'START') {
                log "start tool"
                startNAL
            }
            else {
                log "stop tool"
                stopNAL
            }
        }) 

    $clickCount = 0
    $StartButton.Add_MouseUP( {
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) {
                if ($this.text -eq 'START') {
                    if ($clickCount -gt 3) {
                        $script:clickCount = 0
                        $ButtonType = [System.Windows.MessageBoxButton]::OKCancel
                        $MessageboxTitle = 'Background Mode'
                        $Messageboxbody = 'Run the tool in Background Mode ? (uses settings which won''t affect working in the machine) ? '
                        $MessageIcon = [System.Windows.MessageBoxImage]::Question
                        $null = [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)
                    }
                    else {
                        $script:clickCount ++
                    }
                }
            }
        })

    $ProgressBar1.width = 250
    $ProgressBar1.height = 10
    $ProgressBar1.location = New-Object System.Drawing.Point(20, 170)
    $ProgressBar1.Style = "Marquee"
    $ProgressBar1.BackColor = 'black'
    $ProgressBar1.MarqueeAnimationSpeed = 25
    $ProgressBar1.Visible = $false
    $Form.controls.AddRange(@($ProgressBar1))

    $xVal = 145

    $keyImage1.Image = [System.IconExtractor]::Extract("accessibilitycpl.dll", 5, $true).ToBitmap()
    $keyImage1.Location = New-Object System.Drawing.Point(($xval - 104), 190)
    $keyImage1.Size = "32, 32"
    $keyImage1.SizeMode = "StretchImage"
    $keyImage1.BackColor = [System.Drawing.Color]::FromName("Transparent")
    $Form.Controls.Add($keyImage1)

    $keyImage2.Image = [System.IconExtractor]::Extract("imageres.dll", 101, $true).ToBitmap()
    # $keyImage2.Image    = [System.IconExtractor]::Extract("imageres.dll", 93, $true).ToBitmap()
    $keyImage2.Location = New-Object System.Drawing.Point(($xval - 72), 190)
    $keyImage2.Size = "16, 16"
    $keyImage2.SizeMode = "StretchImage"
    $keyImage2.BackColor = [System.Drawing.Color]::FromName("Transparent")
    $Form.Controls.Add($keyImage2)

    $mouseImage1.Image = [System.IconExtractor]::Extract("accessibilitycpl.dll", 4, $true).ToBitmap()
    $mouseImage1.Location = New-Object System.Drawing.Point(($xval - 16), 190)
    $mouseImage1.Size = "32, 32"
    $mouseImage1.SizeMode = "StretchImage"
    $mouseImage1.BackColor = [System.Drawing.Color]::FromName("Transparent")
    $Form.Controls.Add($mouseImage1)

    $mouseImage2.Location = New-Object System.Drawing.Point(($xval + 16), 190)
    $mouseImage2.Size = "16, 16"
    $mouseImage2.SizeMode = "StretchImage"
    $mouseImage2.BackColor = [System.Drawing.Color]::FromName("Transparent")
    $Form.Controls.Add($mouseImage2)

    $soundImage1.Image = [System.IconExtractor]::Extract("shell32.dll", 168, $true).ToBitmap()
    $soundImage1.Location = New-Object System.Drawing.Point(($xval + 62), 190)
    $soundImage1.Size = "32, 32"
    $soundImage1.SizeMode = "StretchImage"
    $soundImage1.BackColor = [System.Drawing.Color]::FromName("Transparent")
    $Form.Controls.Add($soundImage1)

    $soundImage2.Location = New-Object System.Drawing.Point(($xval + 94), 190)
    $soundImage2.Size = "16, 16"
    $soundImage2.SizeMode = "StretchImage"
    $soundImage2.BackColor = [System.Drawing.Color]::FromName("Transparent")
    $Form.Controls.Add($soundImage2)

    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $statusStrip.BackColor = 'black'

    $statusLabel.forecolor = 'white'
    #$statusLabel.AutoSize = $true
    $statusLabel.TextAlign = 'MiddleCenter'
    $statusLabel.Text = ''
    $statusLabel.Font = New-Object System.Drawing.Font("Arial", 7, [System.Drawing.FontStyle]::Regular)
    [void]$statusStrip.Items.Add($statusLabel)
    $form.Controls.Add($statusStrip)

    updateStatus

    $timer.Interval = 1000
    $timer.add_Tick($timerJob)

    $form.Add_Closing( {
            log "stop tool"
            stopNAL
            $timer.Dispose()
            get-Job | Remove-Job
        })

    if ($autoStart) {
        log "start tool"
        startNAL
    }
}
function startNAL {
    if ($mouseMove -or $soundOn -or ($keyToUse.length -gt 0)) {
        $StartButton.Text = 'STOP'
        $StartButton.BackColor = 'Red'
        $timer.Start()
        $script:jobId = Start-Job -Name "RandomKeysend" $job -ArgumentList $keyToUse, $script:time1, $script:time2, $mouseMove, $soundOn
        $labelL.Text = "Tool Running"
        $ProgressBar1.Visible = $true
        $menuSettings.Enabled = $false
        $menuAction.Enabled = $false
        # $Form.MinimizeBox = $false
        createHistory
    }
    else {
        $ButtonType = [System.Windows.MessageBoxButton]::Warning 
        $MessageboxTitle = 'No Option Selected'
        $Messageboxbody = 'Please select one of the option to be performed from settings '
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $messageicon)
    }
}

function stopNAL {

    updateHistory

    $StartButton.Text = 'START'
    $StartButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4DEE56")
    $timer.Stop()
    $script:time = 0
    if ($script:jobId) {
        Stop-job -Job $script:jobId
    }
    $labelL.Text = "Stopped at"
    $ProgressBar1.Visible = $false
    $menuSettings.enabled = $true
    $menuAction.Enabled = $true
    # $Form.MinimizeBox = $true

    if ($capsState -bxor ([System.Windows.Forms.Control]::IsKeyLocked( 'CapsLock' ))) {
        #log "state different"
        $wshell = New-Object -ComObject wscript.shell;
        $wshell.SendKeys('{CAPSLOCK}')
    }
    if ($numState -bxor ([System.Windows.Forms.Control]::IsKeyLocked( 'NumLock' ))) {
        #log "state different"
        $wshell = New-Object -ComObject wscript.shell;
        $wshell.SendKeys('{NUMLOCK}')
    }

    get-job | stop-job
}

log "init app"
initApp

log "load main UI"
loadUI

# actions
$null = $form.ShowDialog()

#Receive-Job -Name RandomKeysend
