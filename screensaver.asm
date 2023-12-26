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

      mov cx, 100                              ; j = 100 (start position)
draw_row:
      mov bx, 100                              ; i = 100 (end position)
draw_col:
      mov al, 13                               ; pixel color (magenta)
      call set_pixel                           ; write pixel to screen

      inc bx                                   ; i++
      cmp bx, 125                              ; check column loop condition
      jl draw_col                              ; while i < start_x + square_width

      inc cx                                   ; j++
      cmp cx, 125                              ; check row loop condition
      jl draw_row                              ; while j < start_y + square_height

      mov ah, 0                                ; read character
      int 0x16                                 ; BIOS interrupt - keyboard services

      mov ax, 0x0003                           ; set video mode to text mode, 80x25
      int 0x10                                 ; BIOS interrupt - video services

      xor ax, ax                               ; AX = 0
      mov ds, ax                               ; reset data segment
      mov es, ax                               ; reset extra segment

      mov si, prompt                           ; load pointer to prompt
prompt_loop:
      lodsb                                    ; AL = prompt[SI]
      cmp al, 0                                ; check for null terminator
      je reset                                 ; prompt finished printing
      mov ah, 0x0E                             ; teletype output
      int 0x10                                 ; BIOS interrupt - video services

reset:                                         ; ***** reset to beginning *****
      mov ah, 0                                ; read character
      int 0x16                                 ; BIOS interrupt - keyboard services
      jmp main                                 ; loop to beginning

end:                                           ; ***** end of program *****
      jmp $                                    ; infinite loop

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
      mul cx                                   ; offset = (y * SCREEN_WIDTH)
      add ax, bx                               ; offset = (x * SCREEN_WIDTH) + x
      mov di, ax                               ; set pixel offset
      pop ax                                   ; restore pixel color
      mov [es:di], al                          ; set pixel color

      pop di                                   ;
      ret                                      ; end set_pixel subroutine

prompt: db 'Press any key to continue...', 0   ; prompt to reset
curr_x: dw 0                                   ; current x position
curr_y: dw 0                                   ; current y position

%ifdef com_file
%else
                                               ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0                ; pad rest of boot sector
      dw 0xAA55                                ; magic numbers; BIOS bootable
%endif
