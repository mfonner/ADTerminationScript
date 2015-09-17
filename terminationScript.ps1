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
  
.PARAMETER $checkUsername
  Error checking that $userName exists in AD
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

        # Restart the loop
        $userName = $null
    }
}

While ($userName -eq $null)

# Do-While succeeded so username is correct

# Searches AD for userName and prints the user's fullName and title 
$fullName = Get-ADUser -Identity $userName -Properties * | Select -Property Name, Title
Write-Output $fullName

# Get $userName's AD groups
$userNameGroups = Get-ADUser -Identity $userName -Properties memberOf
$groups = $userNameGroups.memberOf | ForEach-Object { Get-ADGroup $_ }

# Write AD groups for clarification that it is the correct user 
Write-Output `n
Write-Output $groups `n

# Confirm before starting termination
$confirmation = Read-Host "Are you sure that you want to terminate"$userName "(y or n)"

if ($confirmation -eq 'y') 
{
	$logFilePath = "\\path\to\user\folder\groups.txt"
    
    Write-Host `n
    Write-Host "Disabling user's AD object..." `n
    Disable-ADAccount -Identity $userName

	# Copy user's security groups to $groups.txt in their user folder
	Write-Host `n
	Write-Host "Copying AD groups to file..." `n
	Out-File $logFilePath -InputObject $userNameGroups.memberOf -Encoding utf8
	
	Write-Host "Removing user from AD groups..." `n
	$groups |ForEach-Object { Remove-ADGroupMember -Identity $_ -Members $userName -Confirm:$false}
	
	Write-Host "Copying user folder to Terminated Share..." `n
	Copy-Item -Path "\\path\to\user\folder\$userName" `
		-Destination "\\path\to\terminated\directory" -Recurse -Force -ErrorAction SilentlyContinue
	
	Write-Host "Termination complete." `n
    
} else {
	
    Write-Host "Cancelled" `n
}