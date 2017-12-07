cls

# **************************************************************************************************************
# *****                                            Warning                                                 *****
# **************************************************************************************************************
# Inspirobot will occasionally produce slogans with language not safe for work.
# Use at your own risk.
# **************************************************************************************************************
# *****                                            Variables                                               *****
# **************************************************************************************************************
  $securityToken = "SECURITY_TOKEN_GOES_HERE"
  $minDrop = 10           # Defines the minimum "size of the rain drop" - ie: minimum points that can be granted
  $maxDrop = 20           # Defines the maximum "size of the rain drop" - ie: maximum points that can be granted
  $usrBlacklist = @("ktrontell")                       # Allows the user to exclude certain people from the rain
  $messageDisplay = "text"       # Specifies if you want the inspirational message to be posted as image or text
# **************************************************************************************************************
# *****                                          Instructions                                              *****
# **************************************************************************************************************
# The first time this is run, you need to generate an API Access Token in bonus.ly
#      Go to [ https://bonus.ly/api_keys/new ] in your browser
#      Type any text in the label and click Create API key
#      Copy the text after "New Access Token Created: " above in the $securityToken variable
# Set the other variables to values you want
#
# Run the script
# If you get an error about this not being a valid cmdlet, you need to delete the __PSLockdown system variables
# The security policy will reapply this multiple times a day, so you will need to take this step each time
# **************************************************************************************************************
# *****                                       External Resources                                           *****
# **************************************************************************************************************
# *****     Inpsiration Provided by:   http://inspirobot.me/                                               *****
# *****     OCR Provided by:           https://ocr.space/ocrapi                                            *****
# **************************************************************************************************************

$webGet = New-Object System.Net.WebClient
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webGet.Headers.Add( "Authorization", $securityToken )
$thisRun = "https://bonus.ly/api/v1/users/me?access_token=$securityToken"
$myInfo = $webGet.DownloadString($thisRun)
$myInfo = ConvertFrom-Json $myInfo

$thisRun = "https://bonus.ly/api/v1/users?include_archived=false&access_token=$securityToken"
$allUsers = $webGet.DownloadString($thisRun)
$allUsers = ConvertFrom-Json $allUsers

$thisRun = "https://bonus.ly/api/v1/companies/show?access_token=$securityToken"
$companyHashtags = $webGet.DownloadString($thisRun)
$companyHashtags = ConvertFrom-Json $companyHashtags
$companyHashtags = $companyHashtags.result.company_hashtags

$myPoints = $myInfo.result.giving_balance

$randomUsers = $allUsers.result | sort{get-random}

if ( $myPoints -eq 0 ) {
    Write-Host "You have no points to hand out.  Try again next month!"
}
else {
    foreach ( $usr in $randomUsers ) {
        if ( $usr.id -ne $myInfo.result.id -and $usr.username -notin $usrBlacklist -and $usr.can_receive ) {
            # Handle points
            if ( $myPoints -lt $minDrop ) { $rainDrop = $myPoints }
            elseif ( $maxDrop -le $minDrop ) { $rainDrop = $maxDrop }
            else { $rainDrop = Get-Random -Maximum $maxDrop -Minimum $minDrop }
            # Get Inspirational Message!
            $webGet = New-Object System.Net.WebClient
            $thisRun = "http://inspirobot.me/api?generate=true"
            $inspirationURL = $webGet.DownloadString($thisRun)
            $thisRun = "https://api.ocr.space/parse/imageurl?apikey=a59bcf789c88957&url=$inspirationURL&language=eng"
            $inspirationRawText = $webGet.DownloadString($thisRun)
            $inspirationRawText = ConvertFrom-Json $inspirationRawText
            $inspirationText = ( $inspirationRawText.ParsedResults.ParsedText -replace "`n","" -replace "`r", "" ).ToString()
            # Write message with a random company value
            $manualMsg = '/give +' + $raindrop + ' @' + $usr.username + " "
            if ( $messageDisplay.ToLower() -eq "image" ) {
                $manualMsg = $manualMsg + $inspirationURL
            }
            else {
                $manualMsg = $manualMsg + '"' + $inspirationText + '" - Inspirobot ' + ( Get-Date -Format yyyy ) 
            }
            $manualMsg = $manualMsg + " " + $companyHashtags[(Get-Random -Maximum (($companyHashtags.Count)-1) -Minimum 0)] + ' #makinitrain '
            Write-Host $manualMsg
            # Deduct points from total
            $myPoints -= $rainDrop
            if ( $maxDrop -gt $myPoints ) { $maxDrop = $myPoints }
        }
        # stop loop if the user runs out of points
        if ( $myPoints -eq 0 ) { break }
    }
}
