

function Send-PagerMessage {

    <#

    To generate the emailargs.xml : 

    @{
        From = 'OutBound@MyDomain.com'
        To = 'Page@MyDomain.com'
        SMTPServer = 'smtp.MyDomain.com'
        UseSSL = $True
        Port = 587
        Credential = Get-Credential -Message 'SMTP Password' -UserName 'Outbound@MyDomain.com'
    } | Export-Clixml $profile\..\emailargs.xml

    #>


    param(
        $Subject = 'Update',
        $Body = 'Status'
    )

    if ( Test-Path $profile\..\emailargs.xml ) {

        $SendArgs = Import-Clixml -Path $profile\..\emailargs.xml
        Write-Verbose "Send Status to: $($SendArgs.To)"
        Send-MailMessage @PSBoundParameters @SendArgs

    }
    else {
        write-warning "$Profile\..\EmailArgs.xml is not present no mail sent!"
    }

}
