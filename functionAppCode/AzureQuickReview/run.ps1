<#
.SYNOPSIS
    Automates the process of downloading, executing, and emailing an Azure Quick Review report.

.DESCRIPTION
    This script performs the following tasks:
    1. Downloads the latest Azure Quick Review tool release from GitHub.
    2. Extracts the downloaded release.
    3. Executes the Azure Quick Review scan for a specified Azure subscription.
    4. Generates a report file with a timestamp and organization name.
    5. Sends the generated report via email using SMTP, with configuration provided via environment variables.
    6. Cleans up temporary files after sending the email.

.PARAMETER Timer
    (Optional) Parameter for scheduling or timing purposes (not used in the script body).

.FUNCTIONS
    Send-ReportByEmail
        Sends the generated Azure Quick Review report as an email attachment using SMTP.
        Requires SMTP and email configuration to be set in environment variables.
        Cleans up the report file after sending.

    Get-AzureQuickReview
        Downloads and extracts the latest Azure Quick Review tool release from GitHub.

    Invoke-AzureQuickReviewScan
        Executes the Azure Quick Review scan using the downloaded tool.
        Sets required environment variables and generates a uniquely named report file.

.ENVIRONMENT VARIABLES
    emailEnabled             - Enables/disables email sending (any value enables).
    emailSMTPServer          - SMTP server address.
    emailSMTPServerPort      - SMTP server port.
    emailSMTPAuthUserName    - SMTP authentication username.
    emailSMTPAuthPassword    - SMTP authentication password.
    emailSender              - Email sender address.
    emailRecipient           - Email recipient address.
    AZURE_ORG_NAME           - Azure organization name (set during scan).
    AZURE_TENANT_ID          - Azure tenant ID (set during scan).
    managedIdentityId        - Azure managed identity client ID.

.NOTES
    - Requires PowerShell 5.1+ and necessary Azure/AzureAD modules.
    - Assumes the script is run in an environment with required permissions and environment variables set.
    - The Azure subscription ID is hardcoded and should be updated as needed.

#>

param($Timer)

function Send-ReportByEmail {
    param($azQuickReviewFilePath)

    if ($env:emailEnabled) {
        Write-Output `r "Sending the report via email..."
        try {
            # Fetch environment variables
            $smtpServer = $env:emailSMTPServer
            $smtpPort = $env:emailSMTPServerPort
            $smtpUser = $env:emailSMTPAuthUserName
            $smtpPassword = $env:emailSMTPAuthPassword

            # Email details
            $from = $env:emailSender
            $to = $env:emailRecipient
            $date = Get-Date -Format 'MMMM yyyy'
            $subject = "[Azure Quick Review] - New Advisory Report - $date"
            $body = @"
Hello,

This is your Azure Quick Review report.
Tenant Name: $env:AZURE_ORG_NAME
Tenant ID: $env:AZURE_TENANT_ID

Please find the detailed findings in the attached report.

Best regards,
Azure Quick Review Automation
"@

            # Create email message
            $emailMessage = New-Object System.Net.Mail.MailMessage($from, $to, $subject, $body)
            $emailMessage.IsBodyHtml = $false
            $emailMessage.Priority = [System.Net.Mail.MailPriority]::High

            # Add attachment if available
            if ($azQuickReviewFilePath) {
                $attachment = New-Object System.Net.Mail.Attachment -ArgumentList $azQuickReviewFilePath
                $emailMessage.Attachments.Add($attachment)
            }

            # Configure SMTP client
            $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
            $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassword)
            $smtpClient.EnableSsl = $true

            # Send email
            $smtpClient.Send($emailMessage)
            Write-Output "Email sent successfully."

            # Cleanup
            $emailMessage.Dispose()
            if ($attachment) { $attachment.Dispose() }

            #
            # File Clean Up
            Remove-Item -Path $fileName
        }
        catch {
            Write-Error "Failed to send email: $_"
            exit 1
        }
    }
}

function Get-AzureQuickReview {

    # Download Azure Quick Review
    Write-Output `r "Checking for Azure Quick Review Release..."
    $releaseName = 'azqr-linux-amd64.zip'
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/azure/azqr/releases/latest"
    $downloadUrl = $($release.assets | Where-Object { $_.name -eq $releaseName }).browser_download_url

    Write-Output "Downloading $downloadUrl"
    Invoke-WebRequest -Method 'Get' -Uri $downloadUrl -OutFile ./$releaseName

    Write-Output "Extracting $releaseName"
    Expand-Archive -Path ./$releaseName -DestinationPath . -Force

    # Clean Up
    Remove-Item -Path ./$releaseName
}

function Invoke-AzureQuickReviewScan {
    #
    # Execute Azure Quick Review
    $env:AZURE_TOKEN_CREDENTIALS = 'prod'
    $env:AZURE_ORG_NAME = (Get-MgOrganization).DisplayName
    $env:AZURE_TENANT_ID = (Get-AzContext).Tenant.Id
    $env:AZURE_CLIENT_ID = $env:managedIdentityId

    # Report Naming
    $dateTime = Get-Date -Format 'yyyy_MM_dd_HH_mm_ss'
    $Script:reportName = "$($dateTime)_$($env:AZURE_ORG_NAME)_Azure_Review"

    Write-Output `r "Starting Azure Quick Review Report..."
    & "./bin/linux_amd64/azqr" scan --subscription-id b67e1026-b589-41e2-b41f-73f8803f71a0 --xslx --output-name ./$reportName 2>&1
}

#
# Get Azure Quick Review
Get-AzureQuickReview

#
# Invoke Azure Quick Review Scan
Invoke-AzureQuickReviewScan

#
# Send Email
$fileName = "$($reportName).xlsx"
Send-ReportByEmail -azQuickReviewFilePath ./$fileName
