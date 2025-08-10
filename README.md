# Notes Attachments Export (AppleScript)

AppleScript to export **all attachments** (including scanned PDFs) from every Apple Note in a chosen folder or single note to a user-selected destination, organized by note title.

## Features
- Saves all images, attachments, and scanned documents from the selected Notes folder or single note.
- Creates subfolders by note title.
- Handles missing file extensions (.pdf, .png, .jpg, .jpeg, .heic, .heif).
- Logs any failed saves to `export-errors.txt`.
- Supports both folder-wide export and single note export with a choice of scope.
- Falls back to exporting the entire note as a PDF if no attachments are detected but content exists (e.g., embedded scans).
- Works on macOS Sonoma/Sequoia with Apple Notes (unlocked notes only).

## Usage
1. Open **Script Editor** on macOS.
2. Paste in [`ExportNotesAttachments.applescript`](ExportNotesAttachments.applescript).
3. **Save As**:
   - File Format: **Application** (optional, for one-click use)
4. Run the script:
   - Choose Notes account.
   - Choose Notes folder to export or select a single note.
   - Select a destination folder for exported files.
5. Find results in:  
   `<Selected Destination>/Notes Export - <Folder/Note Name> <timestamp>/`

## Notes
- Locked notes must be unlocked before export.
- Some attachment types (e.g., live links, special Apple formats) may not be exportable via AppleScript.
- The script uses UI scripting for fallbacks, which may require Accessibility permissions (System Settings > Privacy & Security > Accessibility).
- Check `export-errors.txt` in the export folder for any failed saves or debugging info.

## License
This project is licensed under the [MIT License](LICENSE).
