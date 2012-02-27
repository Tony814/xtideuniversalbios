; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=0h, Disk Controller Reset.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=0h, Disk Controller Reset.
;
; Note: We handle all AH=0h calls, even for drives handled by other
; BIOSes!
;
; AH0h_HandlerForDiskControllerReset
;	Parameters:
;		DL:		Translated Drive number (ignored so all drives are reset)
;				If bit 7 is set all hard disks and floppy disks reset.
;		DS:DI:	Ptr to DPT (only if DL is our drive)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status (from drive requested in DL)
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_HandlerForDiskControllerReset:
	eMOVZX	bx, dl						; Copy requested drive to BL, zero BH to assume no errors
	call	ResetFloppyDrivesWithInt40h

%ifdef MODULE_SERIAL_FLOPPY
;
; "Reset" emulatd serial floppy drives, if any.  There is nothing to actually do for this reset,
; but record the proper error return code if one of these floppy drives is the drive requested.
;
	call	RamVars_UnpackFlopCntAndFirstToAL
	cbw													; Clears AH (there are flop drives) or ffh (there are not)
														; Either AH has success code (flop drives are present)
														; or it doesn't matter because we won't match drive ffh

	cwd													; clears DX (there are flop drives) or ffffh (there are not)

	adc		dl, al										; second drive (CF set) if present
														; If no drive is present, this will result in ffh which 
														; won't match a drive
	call	BackupErrorCodeFromTheRequestedDriveToBH
	mov		dl, al										; We may end up doing the first drive twice (if there is
	call	BackupErrorCodeFromTheRequestedDriveToBH	; only one drive), but doing it again is not harmful.
%endif

	test	bl, bl										; If we were called with a floppy disk, then we are done,
	jns		SHORT .SkipHardDiskReset					; don't do hard disks.
		
	call	ResetForeignHardDisks

	; Resetting our hard disks will modify dl and bl such that this call must be the last in the list
	call	GetDriveNumberForForeignHardDiskHandlerToDL	; Load DPT for our drive
	jc		SHORT .SkipHardDiskReset					; Our drive not requested so let's not reset them
	call	ResetHardDisksHandledByOurBIOS			

.SkipHardDiskReset:
	mov		ah, bh
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


;--------------------------------------------------------------------
; ResetFloppyDrivesWithInt40h
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL, DI
;--------------------------------------------------------------------
ResetFloppyDrivesWithInt40h:
	call	GetDriveNumberForForeignHardDiskHandlerToDL
	and		dl, 7Fh						; Clear hard disk bit
	xor		ah, ah						; Disk Controller Reset
	int		BIOS_DISKETTE_INTERRUPT_40h
	jmp		SHORT BackupErrorCodeFromTheRequestedDriveToBH


;--------------------------------------------------------------------
; ResetForeignHardDisks
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL, DI
;--------------------------------------------------------------------
ResetForeignHardDisks:
	call	GetDriveNumberForForeignHardDiskHandlerToDL
	xor		ah, ah						; Disk Controller Reset
	call	Int13h_CallPreviousInt13hHandler
;;; fall-through to BackupErrorCodeFromTheRequestedDriveToBH


;--------------------------------------------------------------------
; BackupErrorCodeFromTheRequestedDriveToBH
;	Parameters:
;		AH:		Error code from the last resetted drive
;		DL:		Drive last resetted
;		BL:		Requested drive (DL when entering AH=00h)
;	Returns:
;		BH:		Backuped error code
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
BackupErrorCodeFromTheRequestedDriveToBH:
	cmp		dl, bl				; Requested drive?
	eCMOVE	bh, ah
	ret


;--------------------------------------------------------------------
; GetDriveNumberForForeignHardDiskHandlerToDL
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT if our drive
;		DL:		BL if foreign drive
;				80h if our drive
;		CF:		Set if foreign drive
;				Cleared if our drive
;	Corrupts registers:
;		(DI)
;--------------------------------------------------------------------
GetDriveNumberForForeignHardDiskHandlerToDL:
	mov		dl, bl
	call	FindDPT_ForDriveNumberInDL
	jc		SHORT .ReturnWithForeignDriveInDL
	mov		dl, 80h				; First possible Hard Disk should be safe value
.ReturnWithForeignDriveInDL:
	ret


;--------------------------------------------------------------------
; AH0h_ResetAllOurHardDisksAtTheEndOfDriveInitialization
;	Parameters:
;		DS:		RAMVARS segment
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
AH0h_ResetAllOurHardDisksAtTheEndOfDriveInitialization:
	mov		bl, [RAMVARS.bFirstDrv]
	call	GetDriveNumberForForeignHardDiskHandlerToDL
	; Fall to ResetHardDisksHandledByOurBIOS

;--------------------------------------------------------------------
; ResetHardDisksHandledByOurBIOS
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:DI:	Ptr to DPT for requested drive
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ResetHardDisksHandledByOurBIOS:
	mov		bl, [di+DPT.bIdevarsOffset]					; replace drive number with Idevars pointer for cmp with dl
	mov		dl, ROMVARS.ideVars0						; starting Idevars offset

	call	RamVars_GetIdeControllerCountToCX			; get count of ide controllers
	jcxz	.done										; just in case bIdeCnt is zero (shouldn't be)
.loop:
	call	FindDPT_ForIdevarsOffsetInDL				; look for the first drive on this controller, if any
	jc		.notFound

	call	AHDh_ResetDrive								; reset master and slave on that controller
	call	BackupErrorCodeFromTheRequestedDriveToBH	; save error code if same controller as drive from entry

.notFound:
	add		dl, IDEVARS_size							; move Idevars pointer forward
	loop	.loop

.done:
	ret
