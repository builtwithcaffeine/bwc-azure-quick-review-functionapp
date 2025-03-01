<#
.SYNOPSIS
    This script performs an Azure Quick Review scan, generates a report, and optionally sends the report via email.

.DESCRIPTION
    The script performs the following steps:
    1. Ensures the report directory exists.
    2. Downloads the latest Azure Quick Review tool.
    3. Executes the Azure Quick Review scan and generates a report.
    4. Optionally sends the generated report via email if email sending is enabled.

.PARAMETER Timer
    A parameter that can be used to trigger the script execution based on a timer.

.PARAMETER folderName
    The name of the directory where the Azure Quick Review tool and reports will be stored.

.PARAMETER azQuickReviewFilePath
    The file path of the generated Azure Quick Review report.

.FUNCTIONS
    Test-Directory
        Ensures the specified directory exists. If it does not exist, it creates the directory.

    Invoke-DownloadAzureQuickReview
        Downloads the latest release of the Azure Quick Review tool from GitHub.

    Invoke-AzureQuickReviewScan
        Executes the Azure Quick Review scan and generates a report in the specified directory.

    Send-ReportByEmail
        Sends the generated Azure Quick Review report via email if email sending is enabled.

.NOTES
    - Ensure that the necessary environment variables are set for email sending.
    - The script uses managed identity for authentication with Azure.

#>

param($Timer)

# Define Report Directory
$folderName = 'azqrReports'

# Ensure directory exists
function Test-Directory {
    param($folderPath)

    if (-Not (Test-Path -Path $folderPath -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            Write-Output "Directory '$folderPath' created successfully."
        } catch {
            Write-Error "Failed to create directory '$folderPath': $_"
            exit 1
        }
    }
}

# Download Azure Quick Review
function Invoke-DownloadAzureQuickReview {
    param($folderPath)

    Write-Output "Downloading Azure Quick Review..."
    try {
        $azQRLatestReleaseTagUrl = 'https://api.github.com/repos/Azure/azqr/releases/latest'
        $azQRLatestReleaseTag = (Invoke-RestMethod -Uri $azQRLatestReleaseTagUrl).tag_name
        $azQRDownloadUrl = "https://github.com/Azure/azqr/releases/download/$azQRLatestReleaseTag/azqr-ubuntu-latest-amd64"

        Invoke-WebRequest -Uri $azQRDownloadUrl -OutFile "$folderPath/azqr"
        chmod +x "$folderPath/azqr"
        Write-Output "Azure Quick Review downloaded successfully."
    } catch {
        Write-Error "Failed to download Azure Quick Review: $_"
        exit 1
    }
}

# Execute Azure Quick Review Scan
function Invoke-AzureQuickReviewScan {
    param($folderPath)

    Write-Output "Executing Azure Quick Review Scan..."
    try {
        $env:AZURE_ORG_NAME = (Get-MgOrganization).DisplayName
        $env:AZURE_TENANT_ID = (Get-AzContext).Tenant.Id
        $env:AZURE_CLIENT_ID = $env:managedIdentityId

        # Report Naming
        $dateTime = Get-Date -Format 'yyyy_MM_dd_HH_mm_ss'
        $reportName = "$($dateTime)_$($env:AZURE_ORG_NAME)_azure_review"

        Write-Output "Report: [$reportName]"

        # Execute Azure Quick Review
        & "$folderPath/azqr" scan --output-name "$folderPath/$reportName"

        $script:azQuickReviewFilePath = (Get-ChildItem -Path $folderPath/*.xlsx | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
        Write-Output "Azure Quick Review scan completed successfully. Report saved at $azQuickReviewFilePath."
    } catch {
        Write-Error "Azure Quick Review execution failed: $_"
        exit 1
    }
}

# Send Email with Report (if enabled)
function Send-ReportByEmail {
    param($azQuickReviewFilePath)

    if ($env:emailEnabled) {
        Write-Output "Sending the report via email..."
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
        } catch {
            Write-Error "Failed to send email: $_"
            exit 1
        }
    }
}

# Main logic
Test-Directory -folderPath $folderName
Invoke-DownloadAzureQuickReview -folderPath $folderName
Invoke-AzureQuickReviewScan -folderPath $folderName
Send-ReportByEmail -azQuickReviewFilePath $azQuickReviewFilePath