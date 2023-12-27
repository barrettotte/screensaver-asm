;

%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 200

%define KEYBOARD_INTERRUPT 0x16
%define TTY_READ 0x0

%define VIDEO_INTERRUPT 0x10
%define VIDEO_TTY_OUT 0x0E
%define MODE_TEXT 0x3
%define MODE_VIDEO 0x13

%define VIDEO_SEGMENT 0xA000
%define COLOR_MAGENTA 13
%define SQUARE_WIDTH 25

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
      xor ax, ax                               ; AX = 0
      mov ds, ax                               ; set data segment
      mov es, ax                               ; set extra segment

      mov ax, MODE_VIDEO                       ; set video mode to 320x200, 256 colors
      int VIDEO_INTERRUPT                      ; BIOS interrupt

      mov cx, 100                              ; j = 100 (start position)
draw_row:                                      ; row loop
      mov bx, 100                              ; i = 100 (end position)
draw_col:                                      ; column loop
      mov al, COLOR_MAGENTA                    ; pixel color
      call set_pixel                           ; write pixel to screen

      inc bx                                   ; i++
      cmp bx, 100 + SQUARE_WIDTH               ; check column loop condition
      jl draw_col                              ; while i < x_0 + SQUARE_WIDTH

      inc cx                                   ; j++
      cmp cx, 100 + SQUARE_WIDTH               ; check row loop condition
      jl draw_row                              ; while j < y_0 + SQUARE_WIDTH

      mov ah, TTY_READ                         ; read character
      int KEYBOARD_INTERRUPT                   ; BIOS interrupt

      mov ax, MODE_TEXT                        ; set video mode to text mode, 80x25
      int VIDEO_INTERRUPT                      ; BIOS interrupt

      mov si, prompt                           ; load pointer to prompt
prompt_loop:
      lodsb                                    ; AL = prompt[SI]
      cmp al, 0                                ; check for null terminator
      je reset                                 ; prompt finished printing

      mov ah, VIDEO_TTY_OUT                    ; teletype output
      int VIDEO_INTERRUPT                      ; BIOS interrupt
      jmp prompt_loop                          ; continue printing

reset:                                         ; ***** reset to beginning *****
      mov ah, TTY_READ                         ; read character
      int KEYBOARD_INTERRUPT                   ; BIOS interrupt
      jmp main                                 ; loop to beginning

end:                                           ; ***** end of program *****
      jmp $                                    ; infinite loop

set_pixel:                                     ; ***** write a pixel to screen *****
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
