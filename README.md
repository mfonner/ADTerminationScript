# ADTerminationScript
A Windows PowerShell script to Terminate AD User Objects

This script will ask the user to enter the Employee's first and last name, create a username for that user based on the first character of first name + last name convention (ex. mfonner) and then search AD for the object. It will then write the user's name and description to the shell and ask for a confirmation before starting the termination process. Next it copies the employee's AD groups to a .txt file in their user folder, copies their user folder to a terminated directory share, disables the AD object, and finally deletes the user folder. 
