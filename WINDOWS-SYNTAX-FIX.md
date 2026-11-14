# Fix: Windows zip is missing `translations\syntax`

Handoff notes for a Claude Code session on the Windows build machine. Written 14 Nov 2026
from the macOS build session.

## The problem

Fritzing's code editor (Arduino / PICAXE tabs) reads its syntax highlighting rules from
`translations\syntax\` next to the exe: `arduino.xml`, `picaxe.xml`, `styles.xml`.
`build-scripts\package.bat` only ran `lrelease` on `translations\*.ts`, so that folder was never
copied. On macOS, launching with `-d` logged:

```
Unable to open :<app>/translations/syntax/styles.xml
```

The released `Fritzing-1.0.7-unofficial-win64.zip` (SHA-256 `5cdaf08a…0934`) is very likely
missing it too. `package.bat` on `main` is already fixed (commit 37c5d6c): it now xcopies the folder.

## Steps

1. `git pull` in this repo.
2. **Confirm the problem first.** List the released zip's contents and look for `translations/syntax/`.
   If it is already there, stop and tell Phillip; nothing else is needed.
3. **Patch the existing package; don't rebuild everything.** The packaged folder should still be at
   `D:\fritzing-build\dist\Fritzing-1.0.7-unofficial-win64`. Copy in just the missing folder:
   ```
   xcopy /E /I /Y D:\fritzing-build\fritzing-app\translations\syntax D:\fritzing-build\dist\Fritzing-1.0.7-unofficial-win64\translations\syntax
   ```
   If the dist folder is gone, run the full `package.bat` instead (then redo README steps 4–5:
   copy `fritzing-parts\.git` and rebuild `parts.db`).
4. **Check it.** Run `Fritzing.exe -d %TEMP%\fz.log`, close it after it starts, and confirm the log has
   no `Unable to open ... syntax\styles.xml`. Then open a new Arduino code tab
   (Window → Code, or the Code view) and check that keywords like `void` and `digitalWrite` are coloured.
5. **Re-zip** with the same layout as the released zip: compare the top-level folder name and
   structure against the old zip before zipping. Note the new size and SHA-256.
6. **Ask Phillip before replacing the release asset.** Then:
   ```
   gh release upload 1.0.7-unofficial Fritzing-1.0.7-unofficial-win64.zip --clobber
   ```
   and check the digest GitHub reports matches your local SHA-256.
7. Update README.md: the Windows zip size (currently "114 MB") and its SHA-256. Commit on a branch,
   open a PR, and ask Phillip before merging.

## Report back

Whether the old zip really lacked the folder, that the log and colouring check passed, and the new
zip's size and SHA-256.
