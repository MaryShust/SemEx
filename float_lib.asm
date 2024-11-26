%macro fdup 0
	fld st0
%endmacro

section .data

int_1000: dq 1000.0

section .text

global calculate_linear_function
global calculate_circle_function
global square
global fdiv_1000

; Вычисляет квадрат значения X^2
; Принимает 1 аргумент в fpu-стеке:
; | X |
; -----
; Возвращает X^2 в fpu-стеке

square:

	fdup
	fmul
	ret

; Вычисляет значение линейной зависимости вида Y = kX + b
; Принимает 3 аргумента в fpu-стеке:
; | b |
; | k |
; | X |
; -----
; Возвращает Y = kX + b в fpu-стеке

calculate_linear_function:

	fmul
	fadd
	ret

; Вычисляет значение Y в уравнении окружности X^2 + Y^2 = R^2
; Принимает 2 аргумента в fpu-стеке:
; | X |
; | R |
; -----
; Возвращает Y = sqrt(R^2 - X^2) в fpu-стеке

calculate_circle_function:

	call square
	fstp st2
	call square
	fsub
	fsqrt
	ret

; Вычисляет значение X/1000
; Принимает 1 аргумент в fpu-стеке:
; | X |
; -----
; Возвращает X/1000 в fpu-стеке

fdiv_1000:

	fld qword[int_1000]
	fdiv
	ret
