; Alternative Lock Screen Hotkey for Komorebi Users
; Since Win+L is disabled for Komorebi, this provides Win+Ctrl+L as an alternative
; Place this in your AutoHotkey startup folder or include in your main AHK script
; Note: Win+Shift+L is reserved for Komorebi window management (move up)

; Win + Ctrl + L to lock the screen
#^l::
    DllCall("LockWorkStation")
return
