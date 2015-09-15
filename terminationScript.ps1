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

# Prompts the script user to confirm that the account from $userName is indeed the one they want to Terminate
function Get-Confirmation 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $userName
    )

    $confirmMessage = 'Are you sure that {0} is the user that you want to terminate?' -f $userName

    $PSCmdlet.ShouldContinue($confirmMessage, 'Terminate User?')
}

# Code that populates $userName and starts the Termination process
if (Get-Confirmation -User $userName) {
    # If  confirmation == True: start Termination
    
    # Copy user's security groups to groups.txt in their user folder
    # Old Way
	#Get-ADPrincipalGroupMembership -Identity $userName | Out-File -FilePath "\\path\to\user\folder\groups.txt"
    
    # Copy user's security groups to $groups.txt in their user folder
    # New way -> Better formatting
    Out-File $logFilePath -InputObject $userNameGroups.memberOf -Encoding utf8
    
    # TODO: Remove $userName's security groups from AD Object
    # Remove-ADGroupMember -Identity $_ -Members $userNameGroups -Confirm:$false
    
    # FYI: The backtick after the end quotes continues this command to the line directly after it because it's a really long line
    #Copy-Item -Path "\\path\to\active\user\folder" ` 
    #-Destination "\\path\to\terminated\user\folder"
    
} else {
    # Don't Terminate
    # TODO: Restart script to select another user
}

<# OLD SWITCH STATEMENT
# Switch statement to start here
$switchTitle = "Terminate User"
$confirmMessage = "Are you sure that " + $fullName + " is the user that you want to terminate?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",
   "Starts the termination process for the selected user"

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",
   "Cancels the termination process and, eventually, will prompt for another user selection"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($switchTitle, $confirmMessage, $options, 0)

switch ($result)
   {
      # TODO: Copy Folder Redirection (\\roamingprofiles$\FolderRedirection$\userName) to term, delete Citrix Profile, disable AD Account
      0 {"You have selected Yes. The Termination Script will now start."
           Copy-Item -Path "Microsoft.PowerShell.Core\FileSystem::\\path\to\user\folder" ` 
           -Destination "Microsoft.PowerShell.Core\FileSystem::\\path\to\terminated\user\share" -Recurse -Force
        }
      1 {"You have selected No. Please choose another user."}
   }
   
#>

### DEBUGGING CODE ###
Read-Host -Prompt "Press Enter to exit"
# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "Press any key to close..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
### END DEBUGGING ###
