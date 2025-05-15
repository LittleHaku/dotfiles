*Capslock::
    Send {Blind}{LControl down}
    CapsDownTime := A_TickCount
    keyWait, Capslock

    Send {Blind}{LControl up}
    if A_PRIORKEY = CapsLock
    {
        if (A_TickCount - CapsDownTime) < 250
        {
            Send {Esc}
            SetCapsLockState, Off
        }
    }
return

ToggleCaps(){
    ; this is needed because by default, AHK turns CapsLock off before doing Send
    SetStoreCapsLockMode, Off
    Send {CapsLock}
    SetStoreCapsLockMode, On
    return
}
LShift & RShift::ToggleCaps()
RShift & LShift::ToggleCaps()