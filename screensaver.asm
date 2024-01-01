; A bouncing square screensaver-like thing

%define PX_0 10
%define PY_0 10
%define VX_0 1
%define VY_0 1
%define SPEED 2
%define SQUARE_WIDTH 25

%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 200

%define COLOR_BLACK 0
%define COLOR_RED 4
%define COLOR_MAGENTA 13

%define VIDEO_SEGMENT 0xA000

%define VIDEO_INTERRUPT 0x10
%define MODE_VIDEO 0x13

%define MISC_INTERRUPT 0x15
%define MISC_WAIT 0x86

      org 0x7C00                               ; set boot sector origin
      cpu 386                                  ;
      bits 16                                  ;
_start:                                        ; ***** program entry *****

main:                                          ; ***** main program loop *****
      xor ax, ax                               ;
      mov ds, ax                               ; reset data segment
      mov es, ax                               ; reset extra segment

      mov ax, MODE_VIDEO                       ; set video mode to 320x200, 256 colors
      int VIDEO_INTERRUPT                      ; BIOS interrupt
      mov ax, VIDEO_SEGMENT                    ; graphics video memory segment
      mov es, ax                               ; set extra segment to video memory

.draw_loop:                                    ; draw a frame
      push SQUARE_WIDTH                        ; arg: height
      push SQUARE_WIDTH                        ; arg: width
      mov ax, [py]                             ; load current y position
      push ax                                  ; arg: y
      mov ax, [px]                             ; load current x position
      push ax                                  ; arg: x
      mov ax, [color]                          ; load current color
      push ax                                  ; arg: color
      call draw_rect                           ; draw rectangle
      add sp, 2*5                              ; remove args from stack

.wait:                                         ; wait to allow animation
      mov cx, 1                                ; NOTE: This interrupt seems to behave strangely in emulated environments.
      mov dx, 100                              ;   I just plugged in arbitrary numbers in here until I got a smoothish delay.  
      mov ah, MISC_WAIT                        ; wait
      int MISC_INTERRUPT                       ; BIOS interrupt

.check_bounds:                                 ; check left, right, top, and bottom bounds
      mov cx, [px]                             ; load current x position
      mov dx, [py]                             ; load current y position
.check_top:                                    ; check top bound
      cmp dx, 0                                ;
      jle .do_bounce                           ; bounce if top bound hit (py <= 0)
.check_left:                                   ; check left bound
      cmp cx, 0                                ;
      jle .do_bounce                           ; bounce if left bound hit (px <= 0)
.check_right:                                  ; check right bound
      cmp cx, SCREEN_WIDTH-SQUARE_WIDTH        ;
      jge .do_bounce                           ; bounce if right bound hit (px >= SCREEN_WIDTH-SQUARE_WIDTH)
.check_bottom:                                 ; check bottom bound
      cmp dx, SCREEN_HEIGHT-SQUARE_WIDTH       ;
      jge .do_bounce                           ; bounce if bottom bound hit (py >= SCREEN_HEIGHT-SQUARE_WIDTH)
.no_bounce:                                    ; no bounds hit
      jmp .draw_next                           ; skip bouncing

.do_bounce:                                    ; change direction depending on wall hit
      ; TODO:
      nop
      ; if left or right bound hit, reverse x velocity
      ; if top or bottom bound hit, reverse y velocity
      ; x++ if x == 1, else x--
      ; y++ if y == 1, else y--
.update_color:
      inc ax                                   ; change color
      cmp ax, 15                               ; check if color wrap needed
      jle .skip_color_wrap                     ; skip color wrap if not needed
      mov ax, 1                                ; wrap colors around
.skip_color_wrap:                              ;
      mov [color], ax                          ; update current color

.draw_next:                                    ; continue to next iteration

.erase_prev:                                   ; clear previous square
      push SQUARE_WIDTH                        ; arg: height
      push SQUARE_WIDTH                        ; arg: width
      mov bx, [py]                             ; load current y position
      push bx                                  ; arg: y
      mov ax, [px]                             ; load current x position
      push ax                                  ; arg: x
      push COLOR_BLACK                         ; arg: color
      call draw_rect                           ; draw rectangle
      add sp, 2*5                              ; remove args from stack

.update_pos:                                   ; update square position
      mov ax, [px]                             ; load current x position
      add ax, SPEED                            ; move x direction
      ; TODO: x velocity
      mov [px], ax                             ; save current x position

      mov ax, [py]                             ; load current y position
      add ax, SPEED                            ; move y direction
      ; TODO: y velocity
      mov [py], ax                             ; save current y position

      jmp .draw_loop                           ; continue drawing

.end:                                          ; end of program
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

      mov cx, [bp+8]                           ; arg: y = y_0
.draw_row:                                     ; row loop
      mov bx, [bp+6]                           ; arg: x = x_0
.draw_col:                                     ; column loop
      mov al, [bp+4]                           ; arg: pixel color
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
      push ax                                  ; save pixel color

      mov ax, SCREEN_WIDTH                     ; offset = SCREEN_WIDTH
      mul cx                                   ; offset = (y * SCREEN_WIDTH)
      add ax, bx                               ; offset = (y * SCREEN_WIDTH) + x
      mov di, ax                               ; set pixel offset
      pop ax                                   ; restore pixel color
      mov ah, 0x0C                             ; video page
      mov [es:di], al                          ; set color attribute

      pop di                                   ;
      ret                                      ; end set_pixel subroutine

px:   dw PX_0                                  ; x position
py:   dw PY_0                                  ; y position
vx:   db VX_0                                  ; x velocity (1=right, 0=left)
vy:   db VY_0                                  ; y velocity (1=down, 0=up)
color:                                         ;
      db COLOR_RED                             ; color of square (init red)

%ifdef SKIP_FILL
%else
                                               ; ***** complete boot sector *****
      times 510 - ($ - $$) db 0                ; pad rest of boot sector
      dw 0xAA55                                ; magic numbers; BIOS bootable
%endif
