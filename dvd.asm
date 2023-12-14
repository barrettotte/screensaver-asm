; TODO:

%ifdef com_file
      org 0x0100                    ; BIOS entry (COM)
%else
      org 0x7C00                    ; BIOS entry (IMG)
%endif
      cpu 8086                      ;
      bits 16                       ;

_start:                             ; ***** program entry *****
      xor ax, ax                    ; 
      ; TODO:
end:                                ; ***** end of program *****
      jmp $                         ;

%ifdef com_file
%else
                                    ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0     ; pad rest of boot sector
      dw 0xAA55                     ; magic numbers; BIOS bootable
%endif