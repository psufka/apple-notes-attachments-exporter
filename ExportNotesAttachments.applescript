--
-- Export attachments from Apple Notes (any type, incl. scanned PDFs)
-- - Choose Folder (all notes) or Single note
-- - Choose destination folder
-- - Tries Notes' native 'save' first; if that fails, opens the attachment and UI-saves via Preview (or default app)
-- - For notes with no attachments but content (e.g., scanned docs treated as body), falls back to exporting the note as PDF via UI
-- - Creates export-errors.txt ONLY if there are failures
use AppleScript version "2.7"
use framework "Foundation"
use scripting additions
-- ===== Helpers =====
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
on dirname(p)
return do shell script "/usr/bin/dirname " & quoted form of p
end dirname
on basename(p)
return do shell script "/usr/bin/basename " & quoted form of p
end basename
-- Append a line to a file (create file if necessary)
on writeText(pathPOSIX, textToWrite)
do shell script "/bin/echo " & quoted form of textToWrite & " >> " & quoted form of pathPOSIX
end writeText
-- ===== UI fallback for attachments: open in default app and Save As to tgtPOSIX =====
on uiSaveAttachment(tgtPOSIX)
set dirPOSIX to my dirname(tgtPOSIX)
set fileName to my basename(tgtPOSIX)
my ensureDirPOSIX(dirPOSIX)
tell application "System Events"
-- wait for a frontmost app window (Preview for PDFs; could be another default app)
set maxWait to 100
repeat with i from 1 to maxWait
set frontApp to name of first process whose frontmost is true
if frontApp is not "Notes" then exit repeat
delay 0.1
end repeat
-- Duplicate the document first (⇧⌘S) to create an untitled copy
keystroke "s" using {command down, shift down}
delay 0.6  -- Increased delay for new window to appear
-- Invoke Save… (⌘S) on the duplicate, which will prompt the dialog
keystroke "s" using {command down}
delay 0.6  -- Increased for reliability
-- open "Go to the folder" (⇧⌘G), type folder, return
keystroke "G" using {command down, shift down}
delay 0.3
keystroke dirPOSIX
key code 36
delay 0.6  -- Increased
-- set file name in the standard save sheet text field (first text field)
try
if (exists sheet 1 of window 1 of process frontApp) then
set theSheet to sheet 1 of window 1 of process frontApp
else
set theSheet to window 1 of process frontApp
end if
on error
set theSheet to window 1 of process frontApp
end try
try
set value of text field 1 of theSheet to fileName
on error
-- fallback: type it
keystroke fileName
end try
delay 0.3
-- Confirm save (Return)
key code 36
end tell
-- Close the windows after save to clean up
tell application frontApp
try
close windows
end try
end tell
end uiSaveAttachment
-- ===== UI fallback for scanned notes without detected attachments: Export note as PDF =====
on uiExportNoteAsPDF(tgtPOSIX)
set dirPOSIX to my dirname(tgtPOSIX)
set fileName to my basename(tgtPOSIX)
my ensureDirPOSIX(dirPOSIX)
tell application "System Events"
tell process "Notes"
-- Click File > Export as PDF…
try
click menu item "Export as PDF…" of menu "File" of menu bar 1
on error
-- Alternative name in some locales/versions
click menu item "Export Note as PDF…" of menu "File" of menu bar 1
end try
delay 0.6
-- open "Go to the folder" (⇧⌘G), type folder, return
keystroke "G" using {command down, shift down}
delay 0.3
keystroke dirPOSIX
key code 36
delay 0.6
-- set file name
try
set value of text field 1 of sheet 1 of window 1 to fileName
on error
keystroke fileName
end try
delay 0.3
-- Confirm save (Return)
key code 36
end tell
end tell
end uiExportNoteAsPDF
-- ===== Pick account & folder =====
tell application "Notes"
activate
if (count of accounts) = 0 then error "No Notes accounts."
set accNames to (get name of accounts)
set accPick to (choose from list accNames with prompt "Choose Notes account:")
if accPick is false then return
set theAcc to first account whose name is (item 1 of accPick)
if (count of folders of theAcc) = 0 then error "No folders in that account."
set fldNames to (get name of folders of theAcc)
set fldPick to (choose from list fldNames with prompt "Choose folder:")
if fldPick is false then return
set theFld to first folder of theAcc whose name is (item 1 of fldPick)
set allNotes to notes of theFld
end tell
-- ===== Scope: folder vs. single note =====
set scopePick to (choose from list {"Folder (all notes)", "Single note"} with prompt "What do you want to export?")
if scopePick is false then return
set scopePick to item 1 of scopePick
set notesToProcess to {}
set scopeLabel to ""
if scopePick is "Single note" then
set displayNames to {}
set noteRefs to {}
tell application "Notes"
repeat with n in allNotes
set tName to ""
try
set tName to name of n
end try
if tName is missing value or tName = "" then
try
set tName to "Untitled – " & (id of n)
on error
set tName to "Untitled"
end try
end if
set end of displayNames to tName
set end of noteRefs to n
end repeat
end tell
if (count of displayNames) = 0 then error "No notes in that folder."
set pickedName to (choose from list displayNames with prompt "Choose the note to export:")
if pickedName is false then return
set pickedName to item 1 of pickedName
set chosenIndex to 0
repeat with i from 1 to (count of displayNames)
if (item i of displayNames) is pickedName then
set chosenIndex to i
exit repeat
end if
end repeat
if chosenIndex = 0 then error "Selection not found."
set theNote to item chosenIndex of noteRefs
set end of notesToProcess to theNote
set scopeLabel to pickedName
else
set notesToProcess to allNotes
set scopeLabel to (item 1 of fldPick)
end if
-- ===== Destination =====
set defaultDest to (path to downloads folder)
set destAlias to (choose folder with prompt "Choose destination folder for exported files:" default location defaultDest)
set destPOSIX to POSIX path of destAlias
-- Base output
if scopePick is "Single note" then
set baseFolderName to "Notes Export - " & (sanitizeName(scopeLabel)) & " " & (ts())
else
set baseFolderName to "Notes Export - " & (sanitizeName(item 1 of fldPick)) & " " & (ts())
end if
set baseOutPOSIX to destPOSIX & baseFolderName & "/"
ensureDirPOSIX(baseOutPOSIX)
-- ===== Export =====
set savedCount to 0
set failCount to 0
set emptyNotes to 0
set logLines to {}
-- Fallback extension guesses only for nameless items; prioritize .pdf for scans
set guessExts to {".pdf", ".png", ".jpg", ".jpeg", ".heic", ".heif"}
tell application "Notes"
repeat with n in notesToProcess
set noteTitle to ""
try
set noteTitle to name of n
end try
if noteTitle is missing value or noteTitle = "" then
try
set noteTitle to "Untitled – " & (id of n)
on error
set tName to "Untitled"
end try
end if
if scopePick is "Single note" then
set noteBasePOSIX to baseOutPOSIX
else
set noteBasePOSIX to baseOutPOSIX & my sanitizeName(noteTitle) & "/"
my ensureDirPOSIX(noteBasePOSIX)
end if
-- Show the note to ensure it's loaded
show n
delay 0.5  -- Give time to load
set atts to attachments of n
set noteBody to body of n
-- Log for debugging
set end of logLines to "Note: " & noteTitle & " | Attachments: " & (count of atts) & " | Body length: " & (length of noteBody)
set end of logLines to "Body content: " & noteBody
if (count of atts) = 0 then
-- Fallback for possible scanned notes: export note as PDF if body has any content
if length of noteBody > 10 then  -- Lowered threshold to catch embedded scans with short HTML
set tgtPOSIX to my uniquePath(noteBasePOSIX & my sanitizeName(noteTitle) & ".pdf")
try
my uiExportNoteAsPDF(tgtPOSIX)
set savedCount to savedCount + 1
on error errMsg number errNum
set end of logLines to "PDF export failed for note: " & noteTitle & " | " & errNum & " — " & errMsg
set failCount to failCount + 1
end try
else
set emptyNotes to emptyNotes + 1
end if
else
set idx to 1
repeat with a in atts
set nm to ""
try
set nm to name of a
end try
if nm is missing value or nm = "" then set nm to "attachment-" & idx
set baseNm to my sanitizeName(nm)
-- Preferred target: use original name; if no dot, try common extensions
set candidates to {baseNm}
if my hasDot(baseNm) is false then
repeat with e in guessExts
set end of candidates to (baseNm & e)
end repeat
end if
set ok to false
repeat with c in candidates
set tgtPOSIX to my uniquePath(noteBasePOSIX & (c as text))
try
-- 1) Fast path: Notes-native save
save a in (POSIX file tgtPOSIX)
set savedCount to savedCount + 1
set ok to true
exit repeat
on error errMsg number errNum
-- 2) Fallback: open then UI-save
try
open a -- opens in default app (Preview for PDFs/scans)
-- wait a beat for the new app to focus
delay 0.6
my uiSaveAttachment(tgtPOSIX)
set savedCount to savedCount + 1
set ok to true
exit repeat
on error errMsg2 number errNum2
set end of logLines to "Save failed for note: " & noteTitle & " | attachment: " & baseNm & " | " & errNum & " — " & errMsg & " | UI fallback: " & errNum2 & " — " & errMsg2
end try
end try
end repeat
if ok is false then set failCount to failCount + 1
set idx to idx + 1
end repeat
end if
end repeat
end tell
-- Create log only if errors or debugging info occurred
set logPOSIX to ""
if (count of logLines) > 0 then
set logPOSIX to baseOutPOSIX & "export-errors.txt"
set logText to ""
repeat with l in logLines
set logText to logText & l & linefeed
end repeat
do shell script "/bin/echo " & quoted form of logText & " > " & quoted form of logPOSIX
end if
-- Summary
set summaryText to "Done." & return & "Saved: " & savedCount & return & "Failed: " & failCount & return & "Notes with no attachments: " & emptyNotes & return & return & "Location:" & return & baseOutPOSIX
if logPOSIX is not "" then
set summaryText to summaryText & return & return & "If anything failed, see:" & return & logPOSIX
end if
display dialog summaryText buttons {"OK"} default button 1
