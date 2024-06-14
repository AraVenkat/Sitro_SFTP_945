param (
    $localPath = "C:\Messaging\Test\out\Sitro\945_*.xml",
    $remotePaths = @("/testin/","/testsitro/")
)

# Load WinSCP .NET assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Setup session options (same as before)
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = $env:Sitro_SFTP_HOSTNAME
    PortNumber = 10022
    UserName = $env:Sitro_SFTP_USERNAME
    Password = $env:Sitro_SFTP_PASSWORD
    SshHostKeyFingerprint = $env:Sitro_SFTP_SSH_HOST_KEY_FINGERPRINT
}

$session = New-Object WinSCP.Session
try {
    # Connect
    $session.Open($sessionOptions)

    # Upload a file
    foreach ($remotePath in $remotePaths) {
    $transferResult = $session.PutFiles($localPath, $remotePath)
    $transferResult.Check()
     
    # Log the transfer
       foreach ($transfer in $transferResult.Transfers)
        {
             Write-Host "Upload of $($transfer.FileName) succeeded"
             "$(get-date) Upload of $($transfer.FileName) succeeded $($transfer.Destination)" | Out-File -Append "C:\Integration_Scripts\Sitro\Log\ftp-$(get-date -f yyyy-MM-dd).log"
        }

     }
     Remove-Item -Path $localPath
 }
 finally 
   {
    # Disconnect and clean up
    $session.Dispose()
   }

Write-Host "$(get-date) Run Complete"

exit 0

catch
{
     Write-Host "Error: $($_.Exception.Message)"
     "$(get-date) Error: $($_.Exception.Message) $($session.error)" | Out-File -Append "C:\Integration_Scripts\Sitro\Log\ftp-$(get-date -f yyyy-MM-dd).log"
 
    Send-MailMessage  -SmtpServer 'mail.silklogistics.com.au' -From 'Scripts@silklogistic.com.au' -To $env:Sitro_SFTP_EMAIL   -Subject 'SITRO 945 Script Error !!!!' -BodyAsHtml "SITRO 945 Script Error. <br><br>Error Message: $($_.Exception.Message). 
<br><br>Script Log Folder: C:\Users\Aravind.Venkat\Desktop\S\Log <br><br>File Folder: C:\Messaging\Test\Sitro <br><br>Archive File Folder: \\btuat02\archive\Sitro" 
    exit 1
}
