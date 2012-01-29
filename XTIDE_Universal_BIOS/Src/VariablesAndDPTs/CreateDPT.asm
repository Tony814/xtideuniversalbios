; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for creating Disk Parameter Table.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Creates new Disk Parameter Table for detected hard disk.
; Drive is then fully accessible using any BIOS function.
;
; CreateDPT_FromAtaInformation
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;		DS:		RAMVARS segment
;		ES:		BDA Segment
;	Returns:
;		DL:		Drive number for new drive
;		DS:DI:	Ptr to Disk Parameter Table (if succesfull)
;		CF:		Cleared if DPT created successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, CX, DH
;--------------------------------------------------------------------
CreateDPT_FromAtaInformation:
	call	FindDPT_ForNewDriveToDSDI
	; Fall to .InitializeDPT

;--------------------------------------------------------------------
; .InitializeDPT
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.InitializeDPT:
	mov		[di+DPT.bIdevarsOffset], bp	; IDEVARS must start in first 256 bytes of ROM
	; Fall to .StoreDriveSelectAndDriveControlByte

;--------------------------------------------------------------------
; .StoreDriveSelectAndDriveControlByte
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StoreDriveSelectAndDriveControlByte:
	mov		al, bh
	and		ax, BYTE FLG_DRVNHEAD_DRV		; AL now has Master/Slave bit
	cmp		[cs:bp+IDEVARS.bIRQ], ah		; Interrupts enabled?
	jz		SHORT .StoreFlags				;  If not, do not set interrupt flag
	or		al, FLGL_DPT_ENABLE_IRQ
.StoreFlags:
	mov		[di+DPT.wFlags], ax

%ifdef MODULE_SERIAL
	cmp		byte [cs:bp+IDEVARS.bDevice], DEVICE_SERIAL_PORT
	jnz		.StoreAddressing
	or		byte [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
%endif
	; Fall to .StoreAddressing

;--------------------------------------------------------------------
; .StoreAddressing
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.StoreAddressing:
	; Check if CHS defined in ROMVARS
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	test	byte [cs:bx+DRVPARAMS.wFlags], FLG_DRVPARAMS_USERCHS    ; User specified CHS?
	jnz		SHORT .StoreUserDefinedPCHS

	; Check if LBA supported
	call	AtaID_GetPCHStoAXBLBHfromAtaInfoInESSI
	test	BYTE [es:si+ATA1.wCaps+1], A1_wCaps_LBA>>8
	jz		SHORT .StoreCHSfromAXBHBL		; Small old drive with CHS addressing only

	; Check if 48-bit LBA supported
	test	BYTE [es:si+ATA6.wSetSup83+1], A6_wSetSup83_LBA48>>8
	jz		SHORT .StoreLBA28addressing
	or		BYTE [di+DPT.bFlagsLow], ADDRESSING_MODE_LBA48<<ADDRESSING_MODE_FIELD_POSITION
.StoreLBA28addressing:
	or		BYTE [di+DPT.bFlagsLow], ADDRESSING_MODE_LBA28<<ADDRESSING_MODE_FIELD_POSITION
	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
	mov		[di+DPT.twLbaSectors], ax
	mov		[di+DPT.twLbaSectors+2], dx
	mov		[di+DPT.twLbaSectors+4], bx
	call	AtaID_GetLbaAssistedCHStoDXAXBLBH
	mov		[di+DPT.bLbaHeads], bl
	jmp		SHORT .StoreBlockMode

;--------------------------------------------------------------------
; .StoreUserDefinedPCHS
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreUserDefinedPCHS:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		ax, [cs:bx+DRVPARAMS.wCylinders]
	mov		bx, [cs:bx+DRVPARAMS.wHeadsAndSectors]
	; Fall to .StoreCHSfromAXBHBL

;--------------------------------------------------------------------
; .StoreCHSfromAXBHBL
;	Parameters:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
.StoreCHSfromAXBHBL:
	push	ax
	push	bx
	call	AccessDPT_ShiftPCHinAXBLtoLCH	; Get number of bits to shift
	pop		bx
	pop		ax
	jcxz	.StorePCHSfromAXDX				; Small drive so use L-CHS addressing

	; Store P-CHS addressing mode and number of bits to shift in L-CHS to P-CHS translation
	or		cl, ADDRESSING_MODE_PCHS<<ADDRESSING_MODE_FIELD_POSITION
	or		[di+DPT.bFlagsLow], cl
	; Fall to .StoreChsFromAXBLBH

;--------------------------------------------------------------------
; .StoreChsFromAXBLBH
;	Parameters:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StorePCHSfromAXDX:
	mov		[di+DPT.wPchsCylinders], ax
	mov		[di+DPT.wPchsHeadsAndSectors], bx
	; Fall to .StoreBlockMode

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreBlockMode:
	cmp		BYTE [es:si+ATA1.bBlckSize], 1	; Max block size in sectors
	jbe		SHORT .BlockModeTransfersNotSupported
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_BLOCK_MODE_SUPPORTED
.BlockModeTransfersNotSupported:
	; Fall to .StoreDeviceSpecificParameters

;--------------------------------------------------------------------
; .StoreDeviceSpecificParameters
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.StoreDeviceSpecificParameters:
	call	Device_FinalizeDPT
	; Fall to .StoreDriveNumberAndUpdateDriveCount

;--------------------------------------------------------------------
; .StoreDriveNumberAndUpdateDriveCount
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;		ES:		BDA Segment
;	Returns:
;		DL:		Drive number for new drive
;		CF:		Always cleared
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreDriveNumberAndUpdateDriveCount:
	mov		dl, [es:BDA.bHDCount]
	or		dl, 80h						; Set bit 7 since hard disk

	inc		BYTE [RAMVARS.bDrvCnt]		; Increment drive count to RAMVARS
	inc		BYTE [es:BDA.bHDCount]		; Increment drive count to BDA

	cmp		BYTE [RAMVARS.bFirstDrv], 0	; First drive set?
	ja		SHORT .AllDone				;  If so, return
	mov		[RAMVARS.bFirstDrv], dl		; Store first drive number
	clc
.AllDone:
	ret
