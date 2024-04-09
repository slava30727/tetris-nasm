%include "src/game.inc"
%include "lib/mem.inc"
%include "lib/debug/print.inc"

extern printf



section .rodata align 4
    float_fmt db "%f", 10, 0

section .text


; #[stdcall]
; fn GameField::new() -> Self
GameField_new:
    push ebp
    push edi
    mov ebp, esp

    .argbase            equ 12
    .return             equ .argbase+0

    .args_size          equ .return-.argbase+4

    ; return := edi
    mov edi, dword [ebp+.return]

    DEBUGLN `GameField::new()`

    %assign i 0
    %rep GameField_N_CELLS
        ; return.cells[i] = mem::zeroed()
        MEM_ZEROED Cell, edi + GameField.cells + i * Cell.sizeof
    %assign i i+1
    %endrep

    pop edi
    pop ebp
    ret .args_size


; #[stdcall]
; fn GameField::draw(&self, image: &mut ScreenImage)
GameField_draw:
    push ebp
    push esi
    push edi
    mov ebp, esp

    .cur_color          equ -12
    .left_offset        equ -8
    .bottom_offset      equ -4

    .argbase            equ 16
    .self               equ .argbase+0
    .image              equ .argbase+4

    .args_size          equ .image-.argbase+4
    .stack_size         equ -.cur_color

    sub esp, .stack_size

    ; self := esi
    mov esi, dword [ebp+.self]

    ; image := edi
    mov edi, dword [ebp+.image]

    ; left_offset = (image.width - FIELD_WIDTH_PIXELS) / 2
    mov eax, dword [edi+ScreenImage.width]
    sub eax, FIELD_WIDTH_PIXELS
    shr eax, 1
    mov dword [ebp+.left_offset], eax

    ; bottom_offset = (image.height - FIELD_HEIGHT_PIXELS) / 2
    mov eax, dword [edi+ScreenImage.height]
    sub eax, FIELD_HEIGHT_PIXELS
    shr eax, 1
    mov dword [ebp+.bottom_offset], eax

    ; image.fill_rect(left_offset, bottom_offset,
    ;                 FIELD_WIDTH_PIXELS, FIELD_HEIGHT_PIXELS,
    ;                 BACKGROUND_COLOR)
    push BACKGROUND_COLOR
    push FIELD_HEIGHT_PIXELS
    push FIELD_WIDTH_PIXELS
    push dword [ebp+.bottom_offset]
    push dword [ebp+.left_offset]
    push edi
    call ScreenImage_fill_rect

    %assign row 0
    %rep GameField_HEIGHT
        %assign col 0
        %rep GameField_WIDTH

            ; Self::draw_cell(image, row, col, self.cells[row * GameField_WIDTH + col].type)
            push dword [esi+GameField.cells+4*(row*GameField_WIDTH+col)+Cell.type]
            push col
            push row
            push edi
            call GameField_draw_cell

        %assign col col+1
        %endrep
    %assign row row+1
    %endrep

    add esp, .stack_size

    pop edi
    pop esi
    pop ebp
    ret .args_size


; #[stdcall]
; fn GameField::draw_cell(image: &mut ScreenImage, row: u32, col: u32, type: CellType)
GameField_draw_cell:
    push ebp
    push edi
    mov ebp, esp

    .cur_color          equ -12
    .left               equ -8
    .bottom             equ -4

    .argbase            equ 12
    .image              equ .argbase+0
    .row                equ .argbase+4
    .col                equ .argbase+8
    .type               equ .argbase+12

    .args_size          equ .type-.argbase+4
    .stack_size         equ -.cur_color

    sub esp, .stack_size

    ; image := edi
    mov edi, dword [ebp+.image]

    ; if row >= GameField_HEIGHT { return }
    cmp dword [ebp+.row], GameField_HEIGHT
    jnb .exit

    ; if col >= GameField_WIDTH { return }
    cmp dword [ebp+.col], GameField_WIDTH
    jnb .exit

    ; cur_color = cell_colors[type]
    mov eax, dword [ebp+.type]
    mov eax, dword [cell_colors+4*eax]
    mov dword [ebp+.cur_color], eax

    ; left = (image.width - FIELD_WIDTH_PIXELS) / 2 
    ;      + col * CELL_SIZE_PIXELS + CELL_PADDING_PIXELS
    mov eax, dword [edi+ScreenImage.width]
    sub eax, FIELD_WIDTH_PIXELS
    shr eax, 1
    mov dword [ebp+.left], eax
    mov edx, CELL_SIZE_PIXELS
    mov eax, dword [ebp+.col]
    mul edx
    add eax, CELL_PADDING_PIXELS
    add dword [ebp+.left], eax

    ; bottom = (image.height - FIELD_HEIGHT_PIXELS) / 2 
    ;      + row * CELL_SIZE_PIXELS + CELL_PADDING_PIXELS
    mov eax, dword [edi+ScreenImage.height]
    sub eax, FIELD_HEIGHT_PIXELS
    shr eax, 1
    mov dword [ebp+.bottom], eax
    mov edx, CELL_SIZE_PIXELS
    mov eax, dword [ebp+.row]
    mul edx
    add eax, CELL_PADDING_PIXELS
    add dword [ebp+.bottom], eax

    ; image.fill_rect(left, 
    ;                 bottom,
    ;                 CELL_SIZE_PIXELS - 2 * CELL_PADDING_PIXELS,
    ;                 CELL_SIZE_PIXELS - 2 * CELL_PADDING_PIXELS,
    ;                 cur_color)
    push dword [ebp+.cur_color]
    push CELL_SIZE_PIXELS - 2 * CELL_PADDING_PIXELS
    push CELL_SIZE_PIXELS - 2 * CELL_PADDING_PIXELS
    push dword [ebp+.bottom]
    push dword [ebp+.left]
    push edi
    call ScreenImage_fill_rect

.exit:
    add esp, .stack_size

    pop edi
    pop ebp
    ret .args_size



; [stdcall]
; fn Game::new() -> Self
Game_new:
    push ebp
    push edi
    mov ebp, esp

    .argbase            equ 12
    .return             equ .argbase+0

    .args_size          equ .return-.argbase+4

    ; return := edi
    mov edi, dword [ebp+.return]

    DEBUGLN `Game::new()`

    ; return.field = GameField::new()
    lea eax, dword [edi+Game.field]
    push eax
    call GameField_new

    ; return.cur_figure_type = CellType::T
    mov byte [edi+Game.cur_figure_type], CellType_T

    ; return.cur_figure = FIGURES.t
    %assign i 0
    %rep 4
        mov eax, dword [FIGURES.t+i*4]
        mov dword [edi+Game.cur_figure+i*4], eax
    %assign i i+1
    %endrep

    ; return.figure_row = GameField_HEIGHT - 4
    mov dword [edi+Game.figure_row], GameField_HEIGHT - 4

    ; return.figure_col = GameField_WIDTH / 2
    mov dword [edi+Game.figure_col], GameField_WIDTH / 2

    ; return.fall_speed = 1.0
    fld1
    fstp dword [edi+Game.fall_speed]

    ; return.last_fall_time = 0.0
    fldz
    fstp dword [edi+Game.last_fall_time]

    pop edi
    pop ebp
    ret .args_size


; #[stdcall]
; fn Game::draw(&self, image: &mut ScreenImage)
Game_draw:
    push ebp
    push esi
    push edi
    mov ebp, esp

    .argbase            equ 16
    .self               equ .argbase+0
    .image              equ .argbase+4

    .args_size          equ .image-.argbase+4

    ; self := esi
    mov esi, dword [ebp+.self]

    ; image := edi
    mov edi, dword [ebp+.image]

    ; self.field.draw(image)
    push edi
    lea eax, dword [esi+Game.field]
    push eax
    call GameField_draw

    %assign relative_row 0
    %rep 4
        %assign relative_col 0
        %rep 4
        %push

            ; if self.cur_figure[relative_row * 4 + relative_col] != 0
            cmp byte [esi+Game.cur_figure+relative_row*4+relative_col], 0
            je %$.figure_is_not_empty

                ; GameField::draw_cell(image,
                ;                 self.figure_row + relative_row,
                ;                 self.figure_col + relative_col,
                ;                 self.cur_figure_type as u32)
                mov al, byte [esi+Game.cur_figure_type]
                movzx eax, al
                push eax
                mov eax, dword [esi+Game.figure_col]
                add eax, relative_col
                push eax
                mov eax, dword [esi+Game.figure_row]
                add eax, relative_row
                push eax
                push edi
                call GameField_draw_cell
            ; }
            %$.figure_is_not_empty:

        %pop
        %assign relative_col relative_col+1
        %endrep
    %assign relative_row relative_row+1
    %endrep

    pop edi
    pop esi
    pop ebp
    ret .args_size


; #[stdcall]
; fn Game::update(&mut self, time_delta: f32)
Game_update:
    push ebp
    push esi
    mov ebp, esp

    .offset             equ -4

    .argbase            equ 12
    .self               equ .argbase+0
    .time_delta         equ .argbase+4

    .args_size          equ .time_delta-.argbase+4
    .stack_size         equ -.offset

    sub esp, .stack_size

    ; self := esi
    mov esi, dword [ebp+.self]

    ; self.last_fall_time += time_delta
    fld dword [esi+Game.last_fall_time]
    fadd dword [ebp+.time_delta]
    fstp dword [esi+Game.last_fall_time]

    ; offset = self.last_fall_time * self.fall_speed
    fld dword [esi+Game.last_fall_time]
    fmul dword [esi+Game.fall_speed]
    fistp dword [ebp+.offset]

    ; self.figure_row = GameField_HEIGHT - 4 - offset
    mov eax, GameField_HEIGHT - 4
    sub eax, dword [ebp+.offset]
    mov dword [esi+Game.figure_row], eax

    add esp, .stack_size

    pop esi
    pop ebp
    ret .args_size