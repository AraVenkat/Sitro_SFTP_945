param (
    $localPath = "C:\Messaging\Test\out\Sitro\945_*.xml",
    $remotePaths = @("/testin/", "/testsitro/")
)

# Load WinSCP .NET assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Function to set up and open the WinSCP session
function Open-Session {
    param (
        $sessionOptions
    )
    $session = New-Object WinSCP.Session
    try {
        $session.Open($sessionOptions)
        return $session
    }
    catch {
        Handle-Exception -message "Unable to open session" -exception $_.Exception
        exit 1
    }
}

# Function to upload files
function Send-Files {
    param (
        $session,
        $localPath,
        $remotePaths
    )
    try {
        foreach ($remotePath in $remotePaths) {
            $transferResult = $session.PutFiles($localPath, $remotePath)
            $transferResult.Check()
            # Log the transfer
            foreach ($transfer in $transferResult.Transfers) {
                Write-Host "Upload of $($transfer.FileName) succeeded"
                "$(Get-Date) Upload of $($transfer.FileName) succeeded $($transfer.Destination)" | Out-File -Append "C:\Integration_Scripts\Sitro\Log\ftp-$(Get-Date -f yyyy-MM-dd).log"
            }
        }
        # Remove the uploaded files
        Remove-Item -Path $localPath
    }
    catch {
        Handle-Exception -message "Error during file transfer" -exception $_.Exception
        exit 1
    }
}

# Function to handle exceptions
function Handle-Exception {
    param (
        $message,
        $exception
    )
    Write-Host "Error: ${message}: $($exception.Message)"
    "$(Get-Date) Error: ${message}: $($exception.Message)" | Out-File -Append "C:\SFTPLogs\Sitro\Log\ftp-$(Get-Date -f yyyy-MM-dd).log"
    Send-MailMessage -SmtpServer 'mail.silklogistics.com.au' -From 'Scripts@silklogistics.com.au' -To $env:Sitro_SFTP_EMAIL -Subject "SITRO 945 Script Error: $message" -BodyAsHtml "SITRO 945 Script Error. <br><br>Error Message: $($exception.Message). <br><br>Script Log Folder: C:\Users\Piet.Pompies\Desktop\S\Log <br><br>File Folder: C:\Messaging\Test\Mitro <br><br>Archive File Folder: [/btuat02/archive/Sitro]\\btuat02\archive\Sitro"
}

# Get credentials and other sensitive data from environment variables
$hostname = $env:Sitro_SFTP_HOSTNAME
$username = $env:Sitro_SFTP_USERNAME
$password = $env:Sitro_SFTP_PASSWORD
$sshHostKeyFingerprint = $env:Sitro_SFTP_SSH_HOST_KEY_FINGERPRINT
 
# Setup session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = $hostname
    PortNumber = 10022
    UserName = $username
    Password = $password
    SshHostKeyFingerprint = $sshHostKeyFingerprint
}

# Open session
$session = Open-Session -sessionOptions $sessionOptions

# Upload files
Send-Files -session $session -localPath $localPath -remotePaths $remotePaths