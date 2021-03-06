function get-webpage([string]$url,[System.Net.NetworkCredential]$cred=$null)
{
    $error = $false
    $webRequest = [System.Net.HttpWebRequest]::Create($url) 
    $webRequest.Timeout = 300000
    if($cred -eq $null)
    {
        $webRequest.Credentials = [system.Net.CredentialCache]::DefaultCredentials 
    }
    try {
    $res = $webRequest.getresponse()
    }catch{
    $error = $true
    }
}
    
Function Load-SharePoint-Powershell
{
     If ((Get-PsSnapin |?{$_.Name -eq "Microsoft.SharePoint.PowerShell"})-eq $null)
     {
              Write-Host -ForegroundColor White " - Loading SharePoint Powershell Snapin"
          Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
     }
}
Load-SharePoint-Powershell
$webapplications = Get-SPWebApplication
$AllSites = Get-SPSite -limit all
$Array = @()
$i=0
foreach ($wa in $webapplications)
{
    foreach ($windowsauth in $wa.AlternateUrls)
    {
        $authenticationprovider= Get-SPAuthenticationProvider -webapplication $wa -zone $windowsauth.Zone
        If ($authenticationprovider.UseWindowsIntegratedAuthentication)
        {
            $accessableURL = $windowsauth.IncomingUrl
        }
    }
    if (!$AccessableURL) {$accessableURL = $wa.url -replace ".$"}
    foreach ($site in $AllSites)
    {
        if ($Site.Url -and $Site.Url+"/" -match $wa.url)
        {
            $subsites = Get-SPSite $Site.Url | Get-SPWeb -Limit All
            Foreach ($subsite in $subsites)
            {
                $i++
                Write-Progress -activity "Looking up all sites" -status "Please Wait..." -PercentComplete (($i / 500) * 100)
                $PlainWaUrl = $wa.Url -replace ".$"
                $WakeUpSite = $Subsite.Url.replace($PlainWaUrl, $accessableURL)
                $Array = $Array + $WakeUpSite
                #$html=get-webpage -url "$WakeUpSite" -cred $cred;
                if ($i -eq 500){$i=0}
            }
			Remove-Variable i
        }  
    }
    Remove-Variable accessableURL
}

Foreach ($Website in $Array)
{
    $i++
    Write-Progress -activity "Waking up sites" -status "Waking: $Website" -PercentComplete (($i / $Array.Count) * 100)
    $html=get-webpage -url "$Website" -cred $cred;
}
