;

%define SCREEN_WIDTH  320
%define SCREEN_HEIGHT 200
%define VIDEO_SEGMENT 0xA000

%ifdef com_file
  %define ORIGIN 0x0100
%else
  %define ORIGIN 0x7C00
%endif

      org ORIGIN                               ; set boot sector origin
      cpu 386                                  ;
      bits 16                                  ;

_start:                                        ; ***** program entry *****
      mov ax, ORIGIN                           ; 
      mov ds, ax                               ; init data segment

main:                                          ; ***** main program loop *****
      xor ax, ax                               ; ax=0
      mov ds, ax                               ; set data segment
      mov es, ax                               ; set extra segment

      mov ax, 0x13                             ; set video mode to 320x200, 256 colors
      int 0x10                                 ; BIOS interrupt - video services

      mov al, 13                               ; pixel color (magenta)
      mov bx, 100                              ; x coordinate
      mov cx, 100                              ; y coordinate
      call set_pixel                           ; write pixel to screen

      mov ah, 0                                ; read character
      int 0x16                                 ; BIOS interrupt - keyboard services

      mov ax, 0x0003                           ; set video mode to text mode, 80x25
      int 0x10                                 ; BIOS interrupt - video services

      xor ax, ax                               ; ax=0
      mov ds, ax                               ; reset data segment
      mov es, ax                               ; reset extra segment
      mov si, prompt                           ; load pointer to prompt
      call print_str                           ; print prompt to console

reset:                                         ; ***** reset to beginning *****
      mov ah, 0                                ; read character
      int 0x16                                 ; BIOS interrupt - keyboard services
      jmp main                                 ; loop to beginning

end:                                           ; ***** end of program *****
      jmp $                                    ; infinite loop

print_str:                                     ; ***** print string to console *****
                                               ; input SI - pointer to string
.ps_loop:                                      ;
      lodsb                                    ; load byte into AL from string (SI)
      cmp al, 0                                ; check for string null terminator
      je .ps_done                              ; while not null terminator
      call print_char                          ; print a single char to console
      jmp .ps_loop                             ; continue loop
.ps_done:                                      ;
      ret                                      ; end print_str subroutine

print_char:                                    ; ***** print single char to console *****
                                               ; input AL - char to print, clobbers AH
      push bx                                  ;
      mov ah, 0x0E	                       ; teletype output function
      mov bx, 0x000F	                       ; BH page zero and BL color (graphic mode only)
      int 0x10		                       ; BIOS interrupt - display one char
      and ah, 0x00                             ; clear AH
      pop bx                                   ; 
      ret                                      ; end print_char subroutine

set_pixel:                                     ; ***** write a pixel to screen *****
                                               ; assumes ES is already set correctly
                                               ;
                                               ; input AL - pixel color
                                               ; input BX - x coordinate
                                               ; input CX - y coordinate
      push di                                  ;
      push ax                                  ; store pixel color

      mov ax, VIDEO_SEGMENT                    ; graphics video memory segment
      mov es, ax                               ; set extra segment to video memory

      mov ax, SCREEN_WIDTH                     ; offset = SCREEN_WIDTH
      mul bx                                   ; offset = (x * SCREEN_WIDTH)
      add ax, cx                               ; offset = (x * SCREEN_WIDTH) + y
      mov di, ax                               ; set pixel offset
      pop ax                                   ; restore pixel color
      mov [es:di], al                          ; set pixel color

      pop di                                   ;
      ret                                      ; end set_pixel subroutine

prompt: db 'Press any key to continue...', 0   ; prompt to reset

%ifdef com_file
%else
                                               ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0                ; pad rest of boot sector
      dw 0xAA55                                ; magic numbers; BIOS bootable
%endif
