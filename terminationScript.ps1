<#
.SYNOPSIS
  A simple(ish) termination script for Active Directory users
  
.DESCRIPTION
  Asks for user's first and last name and creates userName from that by extracting first character of firstName concatenating it with lastName
  Then, it searches AD for an object matching userName and writes the user's name and title to the Host for clarification that you have the correct user.
  A prompt is displayed, via Get-Confirmation, that this is indeed the user you want to delete. 
  The script then copies the user's security groups to a text file, groups.txt, in their profile folder, copies their profile folder to the term share, 
  disables their AD account/object, and deletes their Citrix profile as well as old user profile

.NOTES
  File Name: terminationScript.ps1
  Author: Matthew Fonner - matt@matthewfonner.com
  Requires: PowerShell V2 as well as an Active Directory (script already imports the module)
  
.PARAMETER $firstName, $lastName
  Prompted input for the first name and last name of user to be terminated
  
.PARAMETER $userName
  The extracted first character of $firstName concatenated with $lastName
  Standard convention for AD Object user names
  
.PARAMETER $userNameGroups
  Used just to select $userName's AD groups and write them to the screen
#>

import-module activedirectory

Do
{
    # Prompt the user to input Employees' first and last name
    Write-Host "Welcome to the NorthStar Termination Script."
    $firstName = Read-Host "Please input the Employees' first name"
    $lastName = Read-Host "Please input the Employees' last name"

    # Extract first character of $firstName 
    $firstName = $firstName.Substring(0,1)

    # Concatenate firstName with lastName to new variable userName
    $userName = ($firstName + $lastName)

    # Just in case the user wants to search by first and last name instead of userName
    $searchName = ($firstName + " " + $lastName)

    Try
    {
        # Check if it's in AD
        $checkUsername = Get-ADUser -Identity $userName -ErrorAction Stop
    }
    Catch
    {
        # Couldn't be found
        Write-Warning -Message "Could not find a user with the username: $userName. Please check the spelling and try again."

        # Loop de loop (Restart)
        $userName = $null
    }
}
While ($userName -eq $null)

# Do-While succeeded so username is correct
# Put script to run if input is correct here

# Searches AD for userName and prints the user's fullName and title 
$fullName = Get-ADUser -Identity $userName -Properties * | Select -Property Name, Title
Write-Output $fullName

# Get $userName's AD groups
$userNameGroups = Get-ADUser -Identity $userName -Properties memberOf
$groups = $userNameGroups.memberOf | ForEach-Object { Get-ADGroup $_ }
# Debugging to ensure that groups are being selected properly
Write-Output ""
Write-Output $groups

$logFilePath = "\\\path\to\user\folder\groups.txt"

# Copy user's security groups to $groups.txt in their user folder
Out-File $logFilePath -InputObject $userNameGroups.memberOf -Encoding utf8

# TODO: Remove $userName's security groups from AD Object
# Remove-ADGroupMember -Identity $_ -Members $userNameGroups -Confirm:$false

# FYI: The backtick after the end quotes continues this command to the line directly after it because it's a really long line
Copy-Item -Path "\\path\to\active\user\folder" `
    -Destination "\\path\to\terminated\user\folder"
    

### DEBUGGING CODE ###
Read-Host -Prompt "Press Enter to exit"
# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "Press any key to close..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
### END DEBUGGING ###