# Notes Attachments Export (AppleScript)

AppleScript to export **all attachments** from every Apple Note in a chosen folder to your **Downloads** directory, organized by note title.

## Features
- Saves all images and attachments from the selected Notes folder.
- Creates subfolders by note title.
- Handles missing file extensions (.png, .jpg, .heic).
- Logs any failed saves to `export-errors.txt`.
- Works on macOS Sonoma/Sequoia with Apple Notes (unlocked notes only).

## Usage
1. Open **Script Editor** on macOS.
2. Paste in [`ExportNotesAttachments.applescript`](ExportNotesAttachments.applescript).
3. **Save As**:
   - File Format: **Application** (optional, for one-click use)
4. Run the script:
   - Choose Notes account.
   - Choose Notes folder to export.
5. Find results in:  
   `~/Downloads/Notes Export - <Folder Name> <timestamp>/`

## Notes
- Locked notes must be unlocked before export.
- Some attachment types (e.g., live links, special Apple formats) may not be exportable via AppleScript.
- Check `export-errors.txt` for any failed saves.

## License
This project is licensed under the [MIT License](LICENSE).
