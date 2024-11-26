%include "lib.inc"
%include "float_lib.inc"

section .data

welcome_message: db "Введите число:", 10, 0
read_word_error_message: db "Считать число не удалось!", 10, 0
parse_int_error_message: db "Введенное значение не является числом!", 10, 0
range_of_tolerance_error_message: db "Введенное значение не попадает в ОДЗ!", 10, 0
success_message: db "Вычисления прошли успешно. Значение функции в данной точке: Y * 1000 = ", 0

result: dq 0
X: dq 0

int_0: dw 0
int_1: dw 1
int_2: dw 2
int_neg_2: dw -2
int_neg_4: dw -4
int_1000: dw 1000

section .text

global _start

_start:

	mov rdi, welcome_message
	call print_string
	enter 128, 0
	lea rdi, [rbp - 128]
	call read_word
	test rax, rax
	jz .read_word_error
	lea rdi, [rbp - 128]
	call parse_int
	test rax, rax
	jz .parse_int_error
	mov rdi, rax
	mov [X], rax

  .area_check:

	cmp rax, -5000
	jl .range_of_tolerance_error
	cmp rax, -3000
	jl .static_1
	cmp rax, -1000
	jl .circle
	cmp rax, 2000
	jl .static_2
	cmp rax, 5000
	jle .linear
	jmp .range_of_tolerance_error

  .static_1:

	fild word[int_1]
	fild word[int_0]
	fild qword[X]
	call fdiv_1000
	call calculate_linear_function
	jmp .print_result

  .static_2:

	fild word[int_neg_2]
	fild word[int_0]
	fild qword[X]
	call fdiv_1000
	call calculate_linear_function
	jmp .print_result

  .linear:

	fild word[int_neg_4]
	fild word[int_1]
	fild qword[X]
	call fdiv_1000
	call calculate_linear_function
	jmp .print_result

  .circle:

	fild qword[X]
	call fdiv_1000
	fild word[int_1]
	fadd
	fild word[int_2]
	call calculate_circle_function
	fchs

  .print_result:

	fild word[int_1000]
	fmul
	fistp qword[result]
	mov rdi, success_message
	call print_string
	mov rdi, qword[result]
	call print_int
	call print_newline
	jmp .end

  .read_word_error:

	mov rdi, read_word_error_message
	call print_error
	jmp .end

  .parse_int_error:

	mov rdi, parse_int_error_message
	call print_error
	jmp .end

  .range_of_tolerance_error:

	mov rdi, range_of_tolerance_error_message
	call print_error

  .end:

	leave
	call exit
