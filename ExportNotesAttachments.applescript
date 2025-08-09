-- Export ALL attachments from every note in a chosen Apple Notes folder
-- Output: ~/Downloads/Notes Export - <Folder Name> <timestamp>/<Note Title>/
-- Writes errors to export-errors.txt

use AppleScript version "2.7"
use framework "Foundation"
use scripting additions

on sanitizeName(t)
	if t is missing value then set t to ""
	set t to t as text
	set AppleScript's text item delimiters to {":", "/", "\\", (linefeed as string), (return as string)}
	set t to (text items of t) as text
	set AppleScript's text item delimiters to ""
	set t to (do shell script "/bin/echo " & quoted form of t & " | /usr/bin/awk '{$1=$1;print}'")
	if t = "" then set t to "Untitled"
	return t
end sanitizeName

on ensureDirPOSIX(p)
	do shell script "/bin/mkdir -p " & quoted form of p
end ensureDirPOSIX

on hasDot(fname)
	return (fname contains ".")
end hasDot

on uniquePath(basePOSIX)
	set p to basePOSIX
	set i to 1
	repeat while (do shell script "/bin/test -e " & quoted form of p & " ; echo $?") is "0"
		set p to basePOSIX & "-" & i
		set i to i + 1
	end repeat
	return p
end uniquePath

on ts()
	set df to current date
	set hhmmss to do shell script "date +%H%M%S"
	return (year of df as text) & my pad2(month of df as integer) & my pad2(day of df as integer) & "-" & hhmmss
end ts

on pad2(x)
	if x < 10 then return "0" & x
	return x as text
end pad2

on appendLine(pathPOSIX, lineText)
	do shell script "/bin/echo " & quoted form of lineText & " >> " & quoted form of pathPOSIX
end appendLine

-- Pick account/folder
tell application "Notes"
	activate
	if (count of accounts) = 0 then error "No Notes accounts."

	set accNames to (get name of accounts)
	set accPick to (choose from list accNames with prompt "Choose Notes account:")
	if accPick is false then return
	set theAcc to first account whose name is (item 1 of accPick)

	if (count of folders of theAcc) = 0 then error "No folders in that account."
	set fldNames to (get name of folders of theAcc)
	set fldPick to (choose from list fldNames with prompt "Choose folder to export ALL attachments from:")
	if fldPick is false then return
	set theFld to first folder of theAcc whose name is (item 1 of fldPick)

	set theNotes to notes of theFld
end tell

-- Output
set downloadsPOSIX to POSIX path of ((path to downloads folder) as text)
set baseOutPOSIX to downloadsPOSIX & "Notes Export - " & (sanitizeName(item 1 of fldPick)) & " " & (ts()) & "/"
ensureDirPOSIX(baseOutPOSIX)
set logPOSIX to baseOutPOSIX & "export-errors.txt"
do shell script "/usr/bin/touch " & quoted form of logPOSIX

set savedCount to 0
set failCount to 0

tell application "Notes"
	repeat with n in theNotes
		set noteTitle to name of n
		if noteTitle is missing value or noteTitle = "" then set noteTitle to "Untitled Note"
		set noteDirPOSIX to baseOutPOSIX & my sanitizeName(noteTitle) & "/"
		my ensureDirPOSIX(noteDirPOSIX)

		set atts to attachments of n
		if (count of atts) > 0 then
			set idx to 1
			repeat with a in atts
				set nm to name of a
				if nm is missing value or nm = "" then set nm to "attachment-" & idx
				set nm to my sanitizeName(nm)

				-- build candidate filenames
				if my hasDot(nm) then
					set candidates to {nm}
				else
					set candidates to {nm & ".png", nm & ".jpg", nm & ".heic"}
				end if

				set ok to false
				repeat with c in candidates
					set tgtPOSIX to my uniquePath(noteDirPOSIX & (c as text))
					try
						-- IMPORTANT FIX: pass a file spec, NOT an alias
						save a in (POSIX file tgtPOSIX)
						set savedCount to savedCount + 1
						set ok to true
						exit repeat
					on error errMsg number errNum
						my appendLine(logPOSIX, "Save failed for note: " & noteTitle & " | attachment: " & nm & " | " & errNum & " — " & errMsg)
					end try
				end repeat
				if ok is false then set failCount to failCount + 1
				set idx to idx + 1
			end repeat
		end if
	end repeat
end tell

display dialog "Done." & return & "Saved: " & savedCount & return & "Failed: " & failCount & ¬
	return & return & "Location:" & return & baseOutPOSIX & return & return & "If anything failed, see:" & return & logPOSIX buttons {"OK"} default button 1
