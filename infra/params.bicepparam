using './main.bicep'

// Default Values
param location = ''
param locationShortCode = ''
param environmentType = 'dev'
param deployedBy = ''
param userAccountGuid = ''

//
param customerName = ''

// Email - SMTP Configuration
@description('Enable Email Notifications')
param emailEnabled = false

@description('Configure SMTP Server Address')
param emailSMTPServer = ''

@description('Configure SMTP Server Port')
param emailSMTPPort = 587

@description('Configure SMTP Server Username')
param emailSMTPAuthUserName = ''

@description('Configure SMTP Server Password')
param emailSMTPAuthPassword = ''

@description('Configure Email Sender')
param emailSender = ''

@description('Configure Email Recipient')
param emailRecipient = ''
