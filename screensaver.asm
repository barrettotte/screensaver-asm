; A bouncing square screensaver-like thing

%define SQUARE_WIDTH 25

%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 200
%define COLOR_BLACK 0
%define COLOR_MAGENTA 13

%define VIDEO_INTERRUPT 0x10
%define VIDEO_TTY_OUT 0x0E
%define MODE_TEXT 0x3
%define MODE_VIDEO 0x13

%define MISC_INTERRUPT 0x15
%define MISC_WAIT 0x86

%define KEYBOARD_INTERRUPT 0x16
%define TTY_READ 0x0

%define VIDEO_SEGMENT 0xA000
%define ORIGIN 0x7C00

      org ORIGIN                               ; set boot sector origin
      cpu 386                                  ;
      bits 16                                  ;

_start:                                        ; ***** program entry *****

main:                                          ; ***** main program loop *****
      xor ax, ax                               ; AX = 0
      mov ds, ax                               ; reset data segment
      mov es, ax                               ; reset extra segment

draw:                                          ; ***** draw ******
      mov ax, MODE_VIDEO                       ; set video mode to 320x200, 256 colors
      int VIDEO_INTERRUPT                      ; BIOS interrupt

; ===== TEMP =====
%define x_0 25
%define y_0 25
; ================

      mov word [curr_x], x_0
      mov word [curr_y], y_0
      mov cx, 1
draw_loop:
      push cx
      cmp cx, 1
      je square                                ; don't erase on first frame

erase:
      mov ax, [curr_x]
      mov bx, [curr_y]

      push SQUARE_WIDTH                        ; height
      push SQUARE_WIDTH                        ; width
      push bx                                  ; y = curr_y
      push ax                                  ; x = curr_x
      push COLOR_BLACK                         ; color 
      call draw_rect                           ; draw rectangle
      add sp, 2*5                              ; remove args from stack

square:
      mov dx, [curr_x]                         ; load current x
      add dx, 8                                ; move x direction
      mov [curr_x], dx                         ; save current x

      mov dx, [curr_y]                         ; load current y
      add dx, 8                                ; move y direction
      mov [curr_y], dx                         ; save current y

      ; TODO: change direction when screen bounds hit

      mov ax, [curr_color]                     ; load current color
      inc ax                                   ; change color
      cmp ax, 8                                ; check if color wrap needed
      jle skip_color_wrap                      ; skip color wrap if not needed
      mov ax, 1                                ; wrap colors around
skip_color_wrap:
      mov [curr_color], ax                     ; update current color

      push SQUARE_WIDTH                        ; height
      push SQUARE_WIDTH                        ; width
      mov dx, [curr_y]                         ; load current y
      push dx                                  ; y position
      mov dx, [curr_x]                         ; load current x
      push dx                                  ; x position
      push ax                                  ; color 
      call draw_rect                           ; draw rectangle
      add sp, 2*5                              ; remove args from stack

      mov cx, 3
      mov dx, 500
      ; mov cx, 18                               ; NOTE: This interrupt seems to behave strangely in emulated environments.
      ; mov dx, 500                              ;   I just plugged in arbitrary numbers in here until I got 1s delay. 
      mov ah, MISC_WAIT                        ; wait (for 1 second)
      int MISC_INTERRUPT                       ; BIOS interrupt

draw_next:
      pop cx                                   ; restore i
      inc cx                                   ; i++
      cmp cx, 16+1                             ; check loop condition
      jl draw_loop                             ; continue drawing

wait_0:                                        ; ***** wait for keypress *****
      mov ah, TTY_READ                         ; read character
      int KEYBOARD_INTERRUPT                   ; BIOS interrupt
      mov ax, MODE_TEXT                        ; set video mode to text mode, 80x25
      int VIDEO_INTERRUPT                      ; BIOS interrupt

print_prompt:                                  ; ***** print prompt to console *****
      mov si, prompt                           ; load pointer to prompt
prompt_loop:                                   ;
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

draw_rect:                                     ; ***** draw rectangle *****
                                               ; input [bp+4]  - color
                                               ; input [bp+6]  - x_0
                                               ; input [bp+8]  - y_0
                                               ; input [bp+10] - width
                                               ; input [bp+12] - height
                                               ;
      push bp                                  ; save base pointer
      mov bp, sp                               ; setup stack frame

      mov cx, [bp+8]                           ; y = y_0
.draw_row:                                     ; row loop
      mov bx, [bp+6]                           ; x = x_0
.draw_col:                                     ; column loop
      mov al, [bp+4]                           ; pixel color
      call set_pixel                           ; write pixel to screen
.next_col:                                     ; iterate to next column
      inc bx                                   ; x++
      mov ax, [bp+6]                           ; x_0
      add ax, [bp+10]                          ; x_0 + width
      cmp bx, ax                               ; check column loop condition
      jl .draw_col                             ; while x < x_0 + width
.next_row:                                     ; iterate to next row
      inc cx                                   ; y++
      mov ax, [bp+8]                           ; y_0
      add ax, [bp+12]                          ; y_0 + height
      cmp cx, ax                               ; check row loop condition
      jl .draw_row                             ; while y < y_0 + height
.end:                                          ;
      mov sp, bp                               ; tear down stack frame
      pop bp                                   ; restore base pointer
      ret                                      ; end draw_rect subroutine

set_pixel:                                     ; ***** write a pixel to screen *****
                                               ; input AL - pixel color
                                               ; input BX - x coordinate
                                               ; input CX - y coordinate
      push di                                  ;
      push ax                                  ; store pixel color

      mov ax, VIDEO_SEGMENT                    ; graphics video memory segment
      mov es, ax                               ; set extra segment to video memory

      mov ax, SCREEN_WIDTH                     ; offset = SCREEN_WIDTH
      mul cx                                   ; offset = (y * SCREEN_WIDTH)
      add ax, bx                               ; offset = (y * SCREEN_WIDTH) + x
      mov di, ax                               ; set pixel offset

      pop ax                                   ; restore pixel color
      mov ah, 0x0C                             ; video page
      mov [es:di], al                          ; set color attribute

      pop di                                   ;
      ret                                      ; end set_pixel subroutine

prompt: db 'Press any key to continue...', 0   ; prompt to reset
curr_x: dw 0                                   ; current x coordinate
curr_y: dw 0                                   ; current y coordinate
curr_color: db 0                               ; current color of square

%ifdef skip_fill
%else
                                               ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0                ; pad rest of boot sector
      dw 0xAA55                                ; magic numbers; BIOS bootable
%endif
