# ADTerminationScript
A Windows PowerShell script to Terminate AD User Objects

The purpose of this script is to make the termination process faster and easier. This script prompts for the Employee's first and last name. It will then create a user name based on the first character of first name plus last name convention. (i.e. Matthew Fonner = MFonner) Then, the script write the user's AD groups to a text file in their user folder, removes them from said groups, copies their folder to a terminated users location, and will finally disable their AD object and move them into a terminated OU. 
