%ifndef _TETRIS_LIB_WINDOW_
%define _TETRIS_LIB_WINDOW_

%include "lib/winapi/windows.inc"
%include "lib/vec.inc"
%include "lib/mem.inc"



section .rodata align 4
    Window_CLASS_NAME               db "window_class", 0, 0, 0, 0
    Window_DEFAULT_ICON_PATH        db "assets/icon.ico", 0



struc WindowClass
    .hinstance  resd 1
    .name       resd 1
    .sizeof     equ ALIGNED($-.hinstance)
endstruc

extern WindowClass_new, WindowClass_drop, WindowClass_with_icon



struc Window
    .hwnd           resd 1
    .msg            resb MSG.sizeof
    .class          resb WindowClass.sizeof
    ; subscribers: Vec<#[stdcall] fn(&Window, UINT, WPARAM, LPARAM)>
    .subscribers    resb Vec32.sizeof
    .width          resd 1
    .height         resd 1
    .sizeof         equ ALIGNED($-.hwnd)
endstruc

%define Window_DEFAULT_POS_X 100
%define Window_DEFAULT_POS_Y 100

extern Window_new, Window_drop, Window__window_setup_procedure
extern Window__window_procedure, Window_close, Window_process_messages
extern Window_block_on_messages, Window_request_redraw
extern Window_add_event_listener



%endif ; !_TETRIS_LIB_WINDOW_