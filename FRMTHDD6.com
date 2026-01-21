;(перед компилированием преобразовать в KOI-8R)
	.ORG    00100h
;
L_0100:	CALL    L_0A08	; вывод строки и отбивки дефисами
	.db 01Bh, 05Bh, "$"	;Ch, 01Bh, 05Eh, "$"
	CALL    L_0A08	; вывод строки и отбивки дефисами
	.db "ОЧИСТКА (ФОРМАТИРОВАНИЕ) "
	.db "НАКОПИТЕЛЯ НА "
	.db "ЖЕСТКОМ МАГНИТНОМ ДИСКЕ.$"
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Improver 2026$"
	LXI  SP,08000h
L_045F: CALL    L_0A08	; вывод строки и отбивки дефисами
	.db "Определение параметров НЖМД$"
;
L_047G:	CALL	L_D8DC	; сброс и проверка готовности НЖМД
L_PDT4:	LXI  D, 00000h
	MOV  C, D	; (C)(DE) (24 бита) -- номер сектора, 000000
	MOV  B, D	; чтение == 0
	LXI  H, BufHDD0	; буфер
	CALL    L_RWHD	; чтение LBA в буфер по адресу в HL
	JNC	L_BTS0	; >>> всё ок
	CALL    L_0B6N	; вывод A в шестнадцатиричном формате с новой строки
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db ": чтение сектора НЖМД$"
	JZ      L_PDT4
L_BTS0:	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Текущая конфигурация на НЖМД: $"
	CALL    L_0A56	; вывод строки далее до "$"
	.db "секторов : $"
	LHLD	BufHDD0+80h	; число секторов из HDD
	MVI  H, 0
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A56	; вывод строки далее до "$"
	.db "головок  : $"
	LHLD	BufHDD0+81h	; число головок из HDD
	MVI  H, 0
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A56	; вывод строки далее до "$"
	.db "цилиндров: $"
	LHLD    BufHDD0+82h	; число цилиндров из HDD
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "дискет   : $"
	LHLD    BufHDD0+84h	; число дискет из HDD
	SHLD	D_FND
	CALL    L_0B3F	; вывод числа из HL
	LXI  H, 00001h
	SHLD	D_STD
	CALL    L_0A08	; вывод строки и отбивки дефисами
	.db "Форматирование НЖМД.", 00Dh, 00Ah
	.db "Определите область очистки, "
	.db "с какой и по какую дискету "
	.db "форматировать:$"
 	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "- номер первой дискеты, 01..$"
	LHLD    D_FND	; всего дискет
	MOV  A, H
	ORA  A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_110F	; ввод шестнадцатиричного числа
	JZ      $-3
	SHLD	D_STD	; первая дискета
	PUSH H
 	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "- номер последней дискеты, $"
	POP  H
	MOV  A, H
	ORA  A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "..$"	
	LHLD    D_FND	; всего дискет
	MOV  A, H
	ORA  A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_110F	; ввод шестнадцатиричного числа
	JZ      $-3
	SHLD    D_FND	; последняя дискета
L_FRE: 	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Выполнить форматирование "
	.db "дискет с $"
	LHLD    D_STD	; первая дискета
	MOV  A, H
	ORA  A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "(H) по $"	
	LHLD    D_FND	; последняя дискета
	MOV  A, H
	ORA  A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_0B1X	;L_0B17	; вывод сообщения с "да/нет?"
	.db "(H) $"
	JNZ	L_WRS1	; отмена
	LHLD    D_STD	; первая дискета
L_FD0:	LXI  D, 0FA30h	; 52h-622h
	MVI  A, 0FFh
	LXI  B, 0622h	; Дискета * 0622h + 52h -> CDE
	XCHG
	INR  D		; +1
L_CLBA:	DAD  B
	ACI	0
	DCR  E
	JNZ	L_CLBA
	DCR  D
	JNZ	L_CLBA
	XCHG
	MOV  C, A	; CDE -- номер сектора LBA
	CALL	L_FRM8	; форматирование заголовка дискеты
	JZ	L_FD1	; нет ошибок
 	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Форматирование дискеты $"
	LHLD    D_STD	; первая дискета
	MOV  A, H
	ORA  A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "(H)$"	
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db " $"
	JZ      L_FRE
L_FD1:	LHLD    D_FND	; последняя дискета
	XCHG
	LHLD    D_STD	; первая дискета
	MOV  A, D
	CMP  H
	JNZ	L_FD3	; D_STD <> D_FND
	MOV  A, E
	CMP  L
	JNZ	L_FD3	; D_STD <> D_FND
L_FD4: 	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Форматирование дискет "
	.db "завершено.$"
L_FD5:	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Очистить системную "
	.db "область диска$"
	JNZ	L_FD7
	MVI  C, 000h	; очистка системной области
	LXI  D, 00002h
L_FD6:	PUSH B
	PUSH D
	CALL	L_FRM8	; по 8 секторов
	POP  D
	POP  B
	MOV  A, E
	ADI  008h
	MOV  E, A
	CPI  052h
	JC	L_FD6	; до первой дискеты
L_FD7:	MVI  C, 00Dh	; сброс дисковой системы
	CALL	00005h
	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Форматирование НЖМД завершено. "
	.db "Повторить$"
	JZ      L_045F
	JMP	00000h	; >>>>> Выход в ОС
;
L_FD3:	JC	L_FD4	; ну а вдруг...
	INX  H
	SHLD    D_STD
	JMP	L_FD0	; к следующей дискете
;
L_WRS1:	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Форматирование дискет "
	.db "отменено.$"
	JMP	L_FD5	;
;
;----------------------------------------------------------------------------------------
; ПП вывода строки и отбивки дефисами
L_0A08: CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "----------------------------"
	.db "----------------------------"
	.db "------------------$"
;
; ПП вывода cтроки до "$" с добавлением перевода строки в начале
L_0A56: CALL    L_0A5C	; вывод строки далее до "$"
	.db 00Dh, 00Ah, "$"
;
; ПП вывода строки от адреса в стеке до "$" с возвратом на адрес после строки
L_0A5C: XTHL		; HL <-> стек (адрес возврата)
	CALL    L_0A62
	XTHL
	RET
;
L_0A62: PUSH PSW
	PUSH D
	PUSH B
L_0A65: MOV  A, M
	INX  H
	CPI     024h
	JZ      L_0A77
	MOV  E, A
	PUSH H
	MVI  C, 002h
	CALL	00005h
	POP  H
	JMP     L_0A65
;
L_0A77: POP  B
	POP  D
	POP  PSW
	RET
;
; ПП вывода строки с ошибкой
L_0A7B: CALL    L_0B39	; перевод строки и пробел
L_0A7C:	XTHL		; без перевода строки
	CALL    L_0A62
	XTHL
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db 01Bh, 062h
	.db "       ОШИБКА        "
	.db 01Bh, 061h, "$"
;	JMP     L_0AAB
;
L_0AAB: PUSH H		; ПП вывода сообщения о продолжении
	PUSH D
	PUSH B
L_0AAE: CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db " -Продолжить/Повторить/Прервать"
	.db " ? (C/R/A)$"
	MVI  C, 001h
	CALL	00005h
	CPI     041h
	JZ      00000h
	CPI     052h
	JZ      L_0AF1
	CPI     043h
	JZ      L_0AF0
	JMP     L_0AAE
;
L_0AF0: INR  A
L_0AF1: POP  B
	POP  D
	POP  H
	RET
;
; ПП вывода сообщения с "да/нет?"
L_0B17: CALL    L_0B39	; перевод строки и пробел
L_0B1X:	XTHL
	CALL    L_0A62
	XTHL
	CALL    L_0A5C	; вывод строки далее до "$"
	.db " ? (Y/N)$"
	PUSH H
	PUSH D
	PUSH B
	MVI  C, 001h
	CALL	00005h
	CPI     059h
	POP  B
	POP  D
	POP  H
	RET
;
L_0B39: CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db " $"
	RET
;
; вывод значения из HL в HEX и DEC
L_0B3F: CALL    L_0A5C	; вывод строки далее до "$"
	.db " $"
	SHLD    Lx0B5X+1
	MOV  A, H
	ORA  A
	CNZ    L_0B6F	; вывод A в шестнадцатиричном формате
	MOV  A, L
	CALL    L_0B6F	; вывод A в шестнадцатиричном формате
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "(H) = $"
Lx0B5X:	LXI  D, 00000h
	CALL    L_CB86	; вывод DE в десятичном формате
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "(D) $"
	RET
;
;
L_0B6N:	CALL	L_0B39	; перевод строки и пробел
; вывод A в шестнадцатиричном формате
L_0B6F: PUSH H
	PUSH D
	PUSH B
	PUSH PSW
	RRC
	RRC
	RRC
	RRC
	CALL    L_0B82	; вывод полубайта в шестнадцатиричном формате
	POP  PSW
	CALL    L_0B82	; --
	POP  B
	POP  D
	POP  H
	RET
;
L_0B82:	ORI	0F0h	; вывод полубайта в шестнадцатиричном формате
	DAA
	CPI	060h
	SBI	01Fh
	MOV  E, A
	MVI  C, 002h
	JMP 	00005h
;
; вывод DE в десятичном формате
L_CB86: PUSH D
	MVI  B, 085h
	LXI  H, L_CBD1
L_CB8C: MOV  E, M
	INX  H
	MOV  D, M
	INX  H
	XTHL
	MVI  C, 030h
L_CB93: MOV  A, L
	SUB  E
	MOV  L, A
	MOV  A, H
	SBB  D
	MOV  H, A
	JC      L_CBA0
	INR  C
	JMP     L_CB93
;
L_CBA0: DAD  D
	MOV  A, B
	ORA  A
	JP      L_CBB7
	PUSH PSW
	MOV  A, C
	CPI     030h
	JZ      L_CBBE
	CALL    L_CBF6	; печать символа из А
	POP  PSW
	ANI     07Fh
	MOV  B, A
	JMP     L_CBCA
;
L_CBB7: MOV  A, C
	CALL    L_CBF6	; печать символа из А
	JMP     L_CBCA
;
L_CBBE: POP  PSW
	ANI     07Fh
	CPI     001h
	JNZ     L_CBCA
	MOV  B, A
	JMP     L_CBB7
;
L_CBCA: XTHL
	DCR  B
	JNZ     L_CB8C
	POP  D
	RET
;
L_CBF6: PUSH H		; ПП печатает символ из А
	PUSH B
	PUSH D
	MOV  E, A
	MVI  C, 002h
	CALL	00005h
	POP  D
	POP  B
	POP  H
	RET
;
L_CBD1: .dw 02710h	; = 10000
	.dw 003E8h	; = 1000
	.dw 00064h	; = 100
	.dw 0000Ah	; = 10
	.dw 00001h	; = 1
;
; ПП ввода значения в шестнадцатиричном формате
L_110F:	CALL    L_0A5C	; вывод строки далее до "$"
	.db " (H) ?$"
	LXI  H, L_1192
	MVI  B, 007h
L_111F: MVI  M, 000h
	INX  H
	DCR  B
	JNZ     L_111F
	LXI  D, L_1190
	MVI  C, 00Ah
	CALL	00005h
	LXI  D, L_1192
	LXI  H, 00000h
L_1134: LDAX D
	CPI     00Dh	; <ВК>
	JZ      L_116X
	INX  D
	ANA  A
	JZ      L_1160
	SUI     030h
	JC      L_1174	; <<< было 1175!!!
	CPI     00Ah
	JC      L_1150
	ADI     0F9h
	CPI     00Ah
	JC      L_1174
	CPI     010h
	JNC     L_1174
L_1150: DAD  H
	DAD  H
	DAD  H
	DAD  H
	ADD  L
	MOV  L, A
	MOV  A, H
	ACI     000h
	MOV  H, A
	JC      L_1174
	JMP     L_1134
;
L_116X:	XRA  A
	STAX D
L_1160:	XCHG
	LHLD	D_FND	;POP  D
	XCHG
	MOV  A, H
	CMP  D
	JNZ     L_116E	; <>maxH
	MOV  A, L
	CMP  E
	JNZ     L_116E	; <>maxL
	JMP     L_116Y	; ==max
;
L_116E: JNC     L_1175	; >max
	XCHG
	LHLD	D_STD
	XCHG
	MOV  A, H
	CMP  D
	JC	L_1175	; <minH
	MOV  A, L
	CMP  E
	JC	L_1175	; <minL
L_116Y:	XRA  A		; ==min
	INR  A
	RET
;
L_1174: ;POP  H
L_1175: PUSH H
	CALL    L_0A7B	; вывод ошибки (?)
	.db "Не правильный номер$"
	XRA  A
	POP  H
	RET
;
;----------------------------------------------------------------------------------------
; Форматирование 8 секторов подряд
; Вход: (C)(DE) (24 бита) -- номер первого сектора
; Вых.:	A и признак C -- код ошибки
;	
L_FRM8:	MOV  A, C
	OUT     055h	; LBA [23..16]
	MOV  A, E
	OUT     053h	; LBA [7..0]
	MOV  A, D
	OUT     054h	; LBA [15..8]
	MVI  A, 0E0h	; 1110 0000
	OUT     056h	; режим и LBA[27..24]
	MVI  A, 008h	; количество записываемых секторов
	OUT     052h	; Счетчик числа секторов для операции записи
	MVI  A, 030h	; 3xH = сектор записи (x = retry and ECC-read)
	OUT     057h	; Запись:	регистр команды
	CALL    L_D9D9	; проверка готовности НЖМД
	ANI     008h	; 0000 1000 :	запрос данных. Буфер ждет данных (занято)
	JZ      L_D9F9	; получение кода ошибки 2 и RET
	LXI  D, 00008h	; D=0, E=8
	MVI  A, 0E5h	; чем заполнять
L_FR00:	OUT     058h	; Регистр данных. Запись данных из буфера
	OUT     050h	; Регистр данных. Запись данных из буфера
	DCR  D		; счётчик
	JNZ     L_FR00	; цикл по сектору
	DCR  E
	JNZ     L_FR00	; цикл на 8 секторов
	JMP     L_D8DC	; выход из записи
;
#include "IDE.inc"
;
L_1190: .db 005h  ; для ввода значений
	.db 000h  ;
L_1192: .db 000h  ;
	.db 000h  ;
	.db 000h  ;
	.db 000h  ;
	.db 000h  ;
	.db 000h  ;
	.db 000h  ;
;
D_STD:	.dw 00001h	; начальная дискета
D_FND:	.dw 029BEh	; последняя дискета
;
	.org (((($ - 1) / 010h) + 1) * 010h)	;Выравнивание на адрес ХХX0h
BufHDD0:	; .db 000h  ; тут и далее 528 байт буфер для сохранения сектора диска
	.END
