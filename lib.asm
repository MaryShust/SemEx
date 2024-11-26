section .text

global exit
global string_length
global print_string
global print_error
global print_char
global print_newline
global print_uint
global print_int
global string_equals
global read_char
global read_line
global read_word
global parse_uint
global parse_int
global string_copy

; Принимает код возврата и завершает текущий процесс

exit:
    mov rax, 60             ; код sys_exit
    syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину

string_length:
    xor rax, rax
  .counter:
    cmp  byte [rdi+rax], 0  ; Проверка, достигнут ли нуль-терминатор.
    je   string_length.end  ; Если да, то выход из функции.
    inc  rax                ; Если нет, то инкрементируем счетчик символов и проходим цикл заново.
    jmp  string_length.counter
  .end:
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout

print_string:
    push rdi                ; Сохраняем caller-saved регистр с нужными данными
    call string_length      ; Подсчитываем длину строки с помощью функции выше.
    pop rdi
    mov  rdx, rax           ; Длина строки.
    mov  rsi, rdi           ; Указатель на начало строки.
    mov  rax, 1             ; Код sys_write.
    mov  rdi, 1             ; Код потока stdout.
    syscall
    ret

; Принимает указатель на нуль-терминированную строку, выводит ее в stderr

print_error:
    push rdi                ; Сохраняем caller-saved регистр с нужными данными
    call string_length      ; Подсчитываем длину строки с помощью функции выше.
    pop rdi
    mov  rdx, rax           ; Длина строки.
    mov  rsi, rdi           ; Указатель на начало строки.
    mov  rax, 1             ; Код sys_write.
    mov  rdi, 2             ; Код потока stderr.
    syscall
    ret

; Принимает код символа и выводит его в stdout

print_char:
    push rdi                ; Кладем код символа на стек.
    mov rsi, rsp            ; Указатель на только что положенный символ.
    mov rdx, 1              ; Длина - 1 символ.
    mov rax, 1              ; Код sys_write.
    mov rdi, 1              ; Код потока stdout.
    syscall
    pop rdi                 ; Возвращаем указатель стека на место.
    ret

; Переводит строку (выводит символ с кодом 0xA)

print_newline:
    mov rdi, 10             ; Код символа 0xA = 10.
    jmp print_char          ; Переходим к функции печати одного символа

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.

print_uint:
    enter 32, 0             ; Выделяем место в стеке под нужное количество символов.
    mov byte[rbp-1], 0      ; Кладем нуль-терминатор в самую верхнюю выделенную ячейку.
    mov r9, 10              ; Делитель - 10.
    mov rax, rdi            ; Переносим делимое из аргумента rdi в аккумулятор rax.
    mov rdi, rbp            ; Переносим rbp в rdi - это будет декрементируемый указатель
    dec rdi                 ; для сохранения каждой последующей цифры. Декрементируем.
  .reading_chars:
    xor rdx, rdx            ; Чистим rdx для корректной работы инструкции div (для сохранения остатка от деления).
    div r9                  ; Делим rax на r9 (на число 10).
    dec rdi                 ; Декрементируем указатель для записи полученной цифры.
    add dl, 48              ; К полученной в rdx цифре числа прибавляем 48 = 0x30, чтобы получить ее ASCII-код.
    mov byte[rdi], dl       ; Сохраняем цифру.
    cmp rax, 0              ; Проверим, не стало ли еще число нулем после скольки-то операций деления.
    je print_uint.success   ; Если да, то переходим к выводу числа.
    jmp print_uint.reading_chars        ; После чего снова переходим к метке reading_chars.
  .success:
    call print_string       ; Если число не ноль, то после перевода в десятичную СС выводим само число.
  .end:
    leave                   ; Освобождаем место в стеке.
    ret

; Выводит знаковое 8-байтовое число в десятичном формате 

print_int:
    cmp rdi, 0              ; Проверим: может быть, входное число неотрицательное?
    jge print_uint          ; Если да, то работаем с ним с помощью функции для беззнаковых чисел.
    push rdi                ; Иначе число отрицательное. Тогда сохраняем его в стеке.
    mov rdi, '-'            ; Кладем в rdi ASCII-код символа "минус".
    call print_char         ; Выводим его отдельно.
    pop rdi                 ; Восстаналиваем число-аргумент из стека.
    neg rdi                 ; Накладываем арифметическое отрицание
    jmp print_uint          ; и работаем с ним с помощью функции для беззнаковых чисел.

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе

string_equals:
    xor rax, rax
    xor rdx, rdx
  .loop:
    mov al, byte[rdi]          ; Считываем в rax и rdx пару символов, которые должны быть равны.
    mov dl, byte[rsi]
    cmp rax, rdx            ; Сравним их коды: если они не равны, то строки точно не будут равны.
    jne string_equals.failure
    cmp al, 0              ; Иначе символы равны. Значит, если хотя бы один из них - это нуль терминатор, то и второй тоже,
    je string_equals.success ; а значит мы дошли до конца обеих строк и все символы до этого были равны. Следовательно, строки равны.
    inc rdi                 ; Если мы еще не дошли до конца строк, и все символы до этого момента были равны,
    inc rsi                 ; то инкрементируем указатели на символы строк и переходим к следующей паре символов.
    jmp string_equals.loop
  .success:
    mov rax, 1              ; При успехе возвращаем 1.
    ret
  .failure:
    mov rax, 0              ; При неудаче возвращаем 0.
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока

read_char:
    mov rax, 0              ; Код sys_read.
    mov rdi, 0              ; Код потока stdin.
    mov rdx, 1              ; Размер буфера - 1.
    enter 16, 0		    ; Выделяем место в стеке под считываемый символ.
    mov rsi, rbp            ; Переносим указатель на начало буфера (1 байт в стеке) в rsi.
    dec rsi
    syscall                 ; Читаем символ из stdin в выделенную ячейку памяти в стеке.
    cmp al, 0               ; При чтении символа окончания ввода, ввод заканчивается, а в rax записывается 0.
    je read_char.end        ; В таком случае у нас в rax будет лежать нужное значение - 0, значит возвращаем его.
    mov al, [rsi]           ; Иначе переносим считанный символ в rax.
  .end:
    leave     	            ; Освобождаем место в стеке.
    ret

; Принимает: адрес начала буфера, размер буфера.
; Читает в буфер строку из stdin.
; Останавливается и возвращает 0, если строка слишком большая для буфера.
; При успехе возвращает адрес буфера в rax, длину строки в rdx.
; При неудаче возвращает 0 в rax.
; Эта функция дописывает к строке нуль-терминатор

read_line:
	
    enter 48, 0 	     ; Принцип работы почти такой же, как у read_word.
    mov rcx, rsi 	     ; Данная функция останавливается только на символе переноса строки '\n' или при окончании ввода.
    dec rcx		     ; Соответственно, у нее отсутствуют некоторые проверки, которые есть у read_word.
    mov rsi, rdi
    mov [rbp-24], rsi
    mov qword[rbp-32], 0
  .main_loop:
    mov [rbp-8], rcx
    mov [rbp-16], rsi
    call read_char
    mov rsi, [rbp-16]
    mov rcx, [rbp-8]
    test al, al 
    jz read_line.success
    cmp al, 10
    je read_line.success
    test rcx, rcx
    jz read_line.failure
    inc qword[rbp-32]
    mov byte[rsi], al
    inc rsi
    dec rcx
    jmp read_line.main_loop
  .success:
    mov byte[rsi], 0
    mov rax, [rbp-24]
    mov rdx, [rbp-32]
    jmp read_line.finally
  .failure:
    xor rax, rax
    xor rdx, rdx
  .finally:
    leave
    ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале.
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция дописывает к слову нуль-терминатор

read_word:
    enter 48, 0             ; Выделим место в стеке.
    mov rcx, rsi            ; Перенесем размер буфера в rcx.
    dec rcx                 ; Сразу декрементируем, т.к. один байт уйдет под нуль-терминатор.
    mov rsi, rdi            ; Переносим адрес начала буфера в rsi.
    mov [rbp-24], rsi       ; Сохраняем адрес начала буфера в стеке - он понадобится при возврате значений из функции.
    mov qword[rbp-32], 0    ; Чистим ячейку памяти в стеке - она будет нужна для подсчета кол-ва символов.
  .blank_space_skip_loop:
    mov [rbp-8], rcx        ; Сохраняем rcx и rsi перед вызовом функции как caller-saved регистры,
    mov [rbp-16], rsi       ; которые используются в функции в дальнейшем.
    call read_char          ; Читаем один символ.
    mov rsi, [rbp-16]       ; Восстанавливаем значения rcx и rsi.
    mov rcx, [rbp-8]
    test al, al             ; Если считано 0 байт, значит мы достигли конца потока, причем никаких символов еще не было считано. 
    jz read_word.failure    ; В этом случае переходим к неудачному результату работы функции.
    cmp al, 9               ; Далее - три проверки на ведущие пробельные символы.
    je read_word.blank_space_skip_loop
    cmp al, 10              ; Они нам не нужны, поэтому проходим этот цикл до тех пор, пока не будет введен какой-либо другой символ или поток не закончится.
    je read_word.blank_space_skip_loop
    cmp al, 32
    je read_word.blank_space_skip_loop
    jmp read_word.char_read
  .main_loop:               ; Если был считан первый непробельный символ, то переходим к основному циклу считывания строки.
    mov [rbp-8], rcx        ; Та же схема со считыванием одного символа, что и в цикле read_word.blank_space_skip_loop.
    mov [rbp-16], rsi
    call read_char
    mov rsi, [rbp-16]
    mov rcx, [rbp-8]
    test al, al             ; Только в этом случае конец потока или любой пробельный символ будет означать конец слова.
    jz read_word.success    ; Уже был считан хотя бы один непробельный символ, а значит это уже можно считать словом.
    cmp al, 9               ; В таком случае переходим к успешному результату работы функции.
    je read_word.success
    cmp al, 10
    je read_word.success
    cmp al, 32
    je read_word.success
    test rcx, rcx           ; Проверяем, не закончился ли буфер. Если закончился, то переходим к неудачному результату работы функции,
    jz read_word.failure    ; т.к. до этого символ прошел проверку и не является пробельным, т.е. нам нужно больше места, чем в буфере.
  .char_read:               ; Эта метка нужна только для перехода из цикла read_word.blank_space_skip_loop, т.к. там мы уже считали символ и остается только его обработать.
    inc qword[rbp-32]       ; Инкрементируем кол-во символов в слове.
    mov byte[rsi], al       ; Сохраняем считанный символ в текущую ячейку буфера.
    inc rsi                 ; Инкрементируем указатель, переходя тем самым к следующей ячейке буфера.
    dec rcx                 ; Уменьшаем кол-во символов, которые еще можно считать (сколько еще осталось места в буфере).
    jmp read_word.main_loop ; Считываем следующий символ.
  .success:
    mov byte[rsi], 0        ; При успехе дописываем нуль-терминатор к слову.
    mov rax, [rbp-24]       ; Возвращаем адрес начала буфера в rax.
    mov rdx, [rbp-32]       ; Возвращаем кол-во символов в слове в rdx.
    jmp read_word.finally   ; Переходим к общим действиям для успешного и неудачного результатов.
  .failure:
    xor rax, rax            ; При неудаче возвращаем 0 в rax и rdx.
    xor rdx, rdx
  .finally:
    leave                   ; Освобождаем место в буфере.
    ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось

parse_uint:
    xor rcx, rcx            ; Чистим rcx и rax.
    xor rax, rax
    enter 16, 0             ; Выделим немного места в стеке.
    mov qword[rbp-16], 0    ; Чистим ячейку памяти в стеке - там будет храниться результирующее число.
  .first_char:
    cmp byte[rdi + rcx], '0'      ; Проверим, не является ли первая цифра нулем? Если да, то неважно, что идет за ним,
    je parse_uint.zero      ; потому что запись числа с ведущими нулями, например 0038, некорректна. Поэтому считаем, что в этом случае мы считали из начала строки число 0.
    jb parse_uint.failure   ; Если первая цифра не ноль, то проверим, может быть у нас в принципе нет цифр и строка начинается с каких-то других символов?
    cmp byte[rdi + rcx], '9'      ; Если да, то переходим к неудачному результату работы функции.
    ja parse_uint.failure
    inc rcx                 ; Если же первый символ - это цифра от 1 до 9, то увеличиваем счетчик цифр rcx.
  .number_length_loop:      ; Цикл для подсчета кол-ва цифр в числе.
    cmp byte[rdi + rcx], '0'      ; Проверяем, является ли следующий символ цифрой, как в предыдущем цикле, только теперь уже без дополнительной проверки на 0,
    jb parse_uint.calculation ; т.к. хотя бы одна ненулевая цифра уже считана.
    cmp byte[rdi + rcx], '9'
    ja parse_uint.calculation
    inc rcx                 ; Увеличиваем счетчик цифр rcx.
    jmp parse_uint.number_length_loop
  .calculation:             ; Часть функции для перевода считанного десятичного числа из символьного вида в шестнадцатеричное число.
    mov [rbp-8], rcx        ; Сохраняем кол-во цифр в числе в выделенную ячейку в стеке.
    dec rcx                 ; Сейчас мы будем подсчитывать максимальную степень числа 10 для перевода числа из десятичного в шестнадцатеричное (подробнее на метке parse_uint.power_raise_loop),
    mov rax, 1              ; поэтому уменьшаем rcx (это максимальное значение показателя степени), записываем 1 в rax (это будет результат, т.е. максимальная степень)
    mov rsi, 10             ; и записываем 10 в rsi (это множитель).
  .power_raise_loop:        ; Поскольку число в строке хранится от старших разрядов к младшим, то сначала нам нужно будет значение старшего разряда умножить на нужную степень числа 10 (например, цифру 3 в разряде тысяч - на тысячу),
    dec rcx                 ; а дальше для каждого последующего разряда делить степень 10 в регистре rsi на 10. Т.е. мы раскладываем число по разрядам (например, 138 = 1*100 + 3*10 + 8*1).
    cmp rcx, 0              ; В этом цикле мы находим степень 10 для старшего разряда числа. Поэтому изначально rax = 1 (это 10^0), rcx = rcx-1 (т.к. максимальный показатель степени будет равен кол-ву цифр минус 1).
    jl parse_uint.calculation_preloop
    mul rsi
    jmp parse_uint.power_raise_loop
  .calculation_preloop:
    mov rcx, [rbp-8]        ; Восстанавливаем кол-во цифр в числе из стека.
  .calculation_loop:        ; Цикл для перевода считанного десятичного числа из символьного вида в шестнадцатеричное число.
    mov rsi, rax            ; Переносим ранее посчитанную степень 10 в rsi.
    xor rax, rax            ; Чистим rax от предыдущих вычислений.
    mov al, byte[rdi]       ; Переносим в rax ASCII-код следующей цифры числа.
    sub rax, 48             ; Преобразуем ASCII-код в значение соответствующей цифры.
    mul rsi                 ; Умножаем на нужную степень 10.
    add [rbp-16], rax       ; Увеличиваем число в результирующей ячейке на получившееся значение.
    mov rax, rsi            ; Переносим степень 10, которую мы использовали на этом шаге цикла, в rax.
    mov rsi, 10             ; Далее записываем 10 в rsi и делим rax на rsi, чтобы уменьшить показатель степени на 1.
    div rsi
    inc rdi                 ; Инкрементируем указатель на строку rdi, переходя к следующей цифре.
    dec rcx                 ; Декрементируем счетчик оставшихся цифр.
    cmp rcx, 0              ; Если все цифры обработаны, то переходим к успешному результату.
    jne parse_uint.calculation_loop
    jmp parse_uint.success  ; Когда все цифры обработаны, переходим к успешному результату работы функции.
  .zero:
    xor rax, rax            ; Если число в начале строки равно 0, то возвращаем 0 в rax
    mov rdx, 1              ; и длину числа, равную 1, в rdx.
    jmp parse_uint.finally
  .failure:
    xor rdx, rdx            ; При неудаче возвращаем 0 в rdx.
    jmp parse_uint.finally
  .success:
    mov rax, [rbp-16]       ; При успехе возвращаем посчитанное число в rax
    mov rdx, [rbp-8]        ; и его длину в rdx.
  .finally:
    leave
    ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось

parse_int:
    sub rsp, 8              ; Выравниваем стек.
  .first_char:
    cmp byte[rdi], '-'      ; Проверим, вдруг число отрицательное?
    je parse_int.negative   ; Если да, то переходим к обработке отрицательных чисел.
    cmp byte[rdi], '0'      ; Если минуса нет, то либо число положительное, либо в начале строки нет числа.
    jb parse_int.failure    ; Проверим наличие цифры в начале строки.
    cmp byte[rdi], '9'
    ja parse_int.failure    ; Если цифры в начале нет, то переходим к обработке неудачного результата работы функции.
  .positive:
    call parse_uint         ; Если цифра была найдена, то обрабатываем число с помощью функции для беззнаковых чисел.
    jmp parse_int.finally
  .negative:
    inc rdi                 ; Если число отрицательное, то инкрементируем указатель на строку (т.к. минус нам больше обрабатывать не нужно)
    call parse_uint         ; и обрабатываем число как положительное с помощью функции выше.
    cmp rdx, 0              ; Проверим, не было ли каких-то символов после знака -, помимо цифр. Если они были, то функция parse_uint вернет 0 в rdx.
    je parse_int.failure
    inc rdx                 ; Если число было обработано успешно, то увеличиваем кол-во его символов на 1 (за счет минуса)
    neg rax                 ; и накладываем арифметическое отрицание на число.
    jmp parse_int.finally
  .failure:
    xor rdx, rdx            ; При неудаче возвращаем 0 в rdx.
  .finally:
    add rsp, 8              ; Восстанавливаем значение rsp.
    ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0

string_copy:
    xor rcx, rcx            ; Чистим rcx - он нужен для подсчета длины строки.
    xor rax, rax            ; Чистим rax - он является "буфером" между строкой и буфером :).
  .loop:
    cmp rdx, 0              ; Проверяем, не закончилось ли место в буфере.
    je string_copy.failure  ; Делаем это в начале цикла, потому что можно дать длину буфера 0 как входной параметр.
    dec rdx                 ; Декрементируем кол-во оставшихся байтов под символы в буфере.
    mov al, byte[rdi]       ; Копируем следующий символ строки в следующую ячейку буфера.
    mov byte[rsi], al
    cmp al, 0              ; Проверяем, не является ли только что скопированный символ нуль-терминатором.
    je string_copy.success ; Если да, то кол-во символов в строке <= длины буфера, а значит копирование успешно.
    inc rcx                ; Инкрементируем длину строки только после этой проверки, т.к. нуль-терминатор в строку не входит.
    inc rdi                ; Инкрементируем указатели на следующий символ в строке и на следующую позицию в буфере.
    inc rsi
    jmp string_copy.loop
  .failure:
    mov rax, 0              ; При неудаче возвращаем 0 в rax.
    ret
  .success:
    mov rax, rcx            ; При успехе возвращаем длину строки. Она у нас сохранена в rcx - переносим в rax.
    ret
