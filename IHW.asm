.data
#заготовки для вывода
msg_input:		.asciz "\n enter the name of input file\n"
msg_output: 		.asciz "\n enter the name of output file\n"
msg_console_output:     .asciz "\n do u want to see the result?\n"

#Выделяем место для переменных
input_file:     .space 4096            # Имя входного файла
output_file:    .space 4096             # Имя выходного файла
buffer:         .space 4096              # Буфер для чтения строки
result:         .space 4096              # Буфер для результатов
user_choice:     .space 2                 #Для выбора Y или нет

#Символы всякие
space: 		.byte ' '		 #Пробел(да ну!?)
newline:        .byte '\n'               # Символ новой строки
capital_A:      .byte 'A'                #точки для определения букв или не букв
capital_Z:      .byte 'Z'                
low_a:		.byte 'a'		
low_z:		.byte 'z'		

.text
.globl main

main:
    #Печатаем сообщение для считывания имени файла
    la a0 msg_input
    li a7, 4
    ecall
    
    # Прочитать имя файла с консоли
    li a0, 0                  # Стандартный ввод 
    la a1, input_file         # Адрес буфера для строки
    li a2, 4096               # Максимальное количество байт для чтения
    li a7, 63                 # ecall для чтения
    ecall
    
    #очистим строку от символа некст строки
    la t0, input_file         # Адрес буфера с именем файла
    call remove_newline       # Функция в конце 
    
    
    #Печатаем сообщение для считывания имени файла на выход
    la a0 msg_output
    li a7, 4
    ecall
    
     # Прочитать имя файла с консоли
    li a0, 0                  
    la a1, output_file                        
    li a7, 63                 
    ecall
    
    #очистим строку от символа некст строки
    la t0, output_file         
    call remove_newline
    
    
    
start:    
    # Открытие входного файла
    la a0, input_file
    li a1, 0                   # Открытие файла в режиме чтения
    li a2, 0
    li a7, 1024                # syscall для открытия файла
    ecall  
    mv s0, a0                  # Сохраняем файловый дескриптор

    # Открытие выходного файла
    la a0, output_file
    li a1, 1                 # Создание файла, режим чтения и записи
    li a7, 1024
    ecall
    mv s1, a0                  # Сохраняем файловый дескриптор

    # Чтение из входного файла
    read_loop:
    mv a0, s0
    la a1, buffer
    li a2, 4096
    li a7, 63                  # ecall для чтения
    ecall
    
    beqz a0, process_done      # Если ничего не прочитано, завершение обработки

    # Обработка строки
    la t0, buffer              # Установить t0 на начало буфера
    la t1, result              # Установить t1 на начало буфера результата
    j parse_buffer             # Перейти к обработке

parse_buffer:
    lbu t3, 0(t0)              # Считать символ
    beqz t3, write_result      # Если конец строки, переход к записи результата

    # Проверка, является ли символ заглавной буквой
    lbu t4, capital_A
    lbu t5, capital_Z
    blt t3, t4, next_char
    bgt t3, t5, next_char

    # Копирование слова
    copy_word:
    	
        lbu t3, 0(t0)          # Считать символ
        
        
        sb t3, 0(t1)           # Записать символ в результирующий буфер
        addi t1, t1, 1         # Увеличить индекс буфера
        addi t0, t0, 1         # Перейти к следующему символу
        
        lbu t3, 0(t0)          # Считать символ
        # Проверка, является ли Некст символ буквой
        lbu t4, low_a
    	lbu t5, low_z
    	blt t3, t4, end_copy_word
   	bgt t3, t5, end_copy_word
        
        j copy_word
    end_copy_word:	
        lbu t3, space
        sb t3, 0(t1)           # Записать символ в результирующий буфер
        addi t1, t1, 1
        
    next_char:
        addi t0, t0, 1         # Перейти к следующему символу
        j parse_buffer

write_result:
    # Добавить символ новой строки
    la t3, newline             # Загрузить адрес символа новой строки
    lbu t4, 0(t3)              # Загрузить значение символа новой строки
    sb t4, 0(t1)               # Записать символ новой строки в буфер
    addi t1, t1, 1             # Увеличить индекс буфера
    

    # Запись результата в выходной файл
    mv a0, s1
    la t2, result              # Загрузить адрес начала буфера результата
    sub a2, t1, t2             # Вычислить длину результирующего буфера
    mv a1, t2                  # Установить адрес буфера для записи
    bge a2, zero, valid_write  # Если длина > 0, записать данные
    j read_loop

valid_write:
    li a7, 64                  # ecall для записи
    ecall
    
    j read_loop

process_done:
	
    # Закрытие файлов
    mv a0, s0
    li a7, 57
    ecall

    mv a0, s1
    li a7, 57
    ecall

    # Завершение программы
    li a0, 0
    li a7, 10
    ecall

    # Удалить символ новой строки, если он есть 
remove_newline:
    lbu t1, 0(t0)              # Считать байт
    beqz t1, start             # Если достигнут конец строки, завершить
    li t2, 10                  # Код символа '\n'
    beq t1, t2, null_terminate # Если найден '\n', заменить на '\0'
    addi t0, t0, 1             # Перейти к следующему байту
    j remove_newline

null_terminate:
    sb zero, 0(t0)            # Установить '\0' в текущую позицию
    ret
 
exit:			      #закругляемся
    li a0, -1
    li a7, 10
    ecall
