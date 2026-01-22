;(перед компилированием преобразовать в KOI-8R)
	.ORG    00100h
;
START:	LXI  D, ABOUT
	CALL	PRINTD
	CALL	L_D8DC	; сброс и проверка готовности НЖМД
	LXI  D, 00000h
	MOV  C, D	; (C)(DE) (24 бита) -- номер сектора, 000000
	MOV  B, D	; чтение == 0
	LXI  H, BufHDD	; буфер
	CALL    L_RWHD	; чтение LBA в буфер по адресу в HL
	JNC	L_HDOK	; >>> всё ок
L_ERRX:	LXI  D, ERROR
L_DONE:	CALL	PRINTD
	JMP	00000h	; >>>>> Выход в ОС
;
L_HDOK:	LHLD    BufHDD+84h	; число дискет из HDD
;	LXI  H, 00001h
	SHLD	D_DSKT
	LXI  H, 00001h
	SHLD	D_CURD
L_DS00:	LXI  D, 0FA30h	; 52h-622h
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
	CALL	L_RD8S	; чтение заголовка дискеты
	JNZ	L_ERRX	; ошибка чтения
	LXI  H, BufHDD	; буфер
	LXI  B, 00180h	; С - счётчик записей, B - счётчик записей в строке
	PUSH B
	PUSH H
	LXI  D, 00020h	; шаг записей
L_DS04:	MOV  A, M	; быстрая проверка наличия файлов
	ANI  0F0h
	JZ	L_DS05	; записи есть
	DAD  D
	DCR  C
	JNZ	L_DS04	; цикл по записям файлов
	POP  H
	POP  B
	JMP	L_DS06	; записи не найдены, к следующей дискете
;
L_DS05:	LXI  D, DSKT	; "Дискета ..."
	CALL	PRINTD
	LHLD	D_CURD
	MOV  A, H
	CALL	PRHEX	; выводим номер дискеты
	MOV  A, L
	CALL	PRHEX
;; вывод списка файлов
	POP  H		;LXI  H, BufHDD	; буфер
	POP  B		;LXI  B, 00180h	; С - счётчик записей, B - счётчик записей в строке
L_DS01:	MOV  A, M
	ANI  0F0h	;ORA  A
	JNZ	L_DS02	; нет записи -- пропускаем
	MOV  D, H
	MOV  A, L
	ADI  00Ch
	MOV  E, A	; на конец записи
	LDAX D
	ORA  A
	JNZ	L_DS02	; повторная запись -- пропускаем
;; +++ фильтрация по маске
	MOV  A, L
	MOV  E, L	; сохраняем адрес начала записи в (H)(E)
	ADI  009h
	MOV  L, A	; на начало расширения
	MOV  D, M
	MVI  M, '.'
	INR  L
	MOV  A, M
	MOV  M, D
	INR  L
	MOV  D, M
	MOV  M, A
	INR  L
	MOV  A, M
	MOV  M, D
	INR  L
	MVI  M, '$'	; сдвигаем расширение и дополняем "$"
	MOV  L, E
	MOV  D, H	; DE = HL = адрес начала записи
	INR  E		; на начало ИФ
	PUSH D
	DCR  B
	CZ	PRNLF	; новая строка
	POP  D
	CALL	PRINTD	; выводим имя файла
	MVI  C, ' '	; пробел
	CALL	PRINTC
	LXI  D, SEPAR	; разделитель
	MOV  A, M
	ORA  A
	JZ	L_DS03
	MVI  C, 'u'	; юзер
	CALL	PRINTC
	CALL	L_0245	; вывод полубайта в HEX
	LXI  D, SEPAU	; разделитель короткий
L_DS03:	MOV  A, B
	CPI  1
	CNZ	PRINTD
L_DS02:	LXI  D, 00020h	; шаг записей
	DAD  D
	DCR  C
	JNZ	L_DS01	; цикл по записям файлов
L_DS06:	LHLD	D_DSKT	; всего дискет
	XCHG
	LHLD	D_CURD	; текущая дискета
	MOV  A, D
	CMP  H
	JNZ	L_FD1	; D_DSKT <> D_CURD
	MOV  A, E
	CMP  L
	JNZ	L_FD1	; D_DSKT <> D_CURD
L_FD2:	LXI  D, FINAL
	JMP	L_DONE	; на выход
;
L_FD1:	JC	L_FD2	; ну а вдруг...
	INX  H
	SHLD    D_CURD
	JMP	L_DS00	; к следующей дискете
;
;----------------------------------------------------------------------------
;
PRNLF:	MVI  B, 004h	; записей в строке
PRNL:	LXI  D, NEWLINE
PRINTD:	PUSH H
	PUSH B
	MVI  C, 009h	; Вывод последовательности символов из DE (до "$")
	CALL	00005h
	POP  B
	POP  H
	RET
;
PRHEX:	MOV  B, A	; вывод значения A в HEX
	RRC
	RRC
	RRC
	RRC
	CALL    L_0245
	MOV  A, B
L_0245:	ORI	0F0h	; вывод полубайта в шестнадцатиричном формате
	DAA
	CPI	060h
	SBI	01Fh
	MOV  C, A
PRINTC:	PUSH PSW	; вывод на экран
	PUSH B
	PUSH H
	PUSH D
	MOV  E, C
	MVI  C, 002h	; вывод на экран (1 символ)
	CALL    00005h
	POP  D
	POP  H
	POP  B
	POP  PSW
	RET
;
; чтение 8 секторов (оглавление дискеты)
L_RD8S:	MVI  B, 000h	; чтение
	LXI  H, BufHDD	; куда читать
	MVI  A, 008h	; счётчик
L_R800:	PUSH PSW
	PUSH B
	PUSH D
	CALL	L_RWHD	; чтение сектора
	POP  D
	POP  B
	JNZ	L_R802	; ошибка
	INR  E		; следующий сектор
	JNZ	L_R801
	INR  D
	JNZ	L_R801
	INR  C
	JNZ	L_R801
L_R801:	POP  PSW
	DCR  A
	JNZ	L_R800
	RET
;
L_R802:	POP  B		; подчистка стека (PSW)
	RET
;
#include "IDE.inc"
;
ABOUT:	.DB 01Bh, 05Bh," ListHDD для МДОС/РДС "
	.DB "Вектор-06ц, Improver 2026"
	.DB 0Dh, 0Ah
	.db "----------------------"
	.db "--------------------------$"
ERROR:	.DB "Ошибка чтения НЖМД$"
NEWLINE:.DB 0Dh,0Ah,"$"
DSKT:	.DB 0Dh, 0Ah, "-- Дискета $"
SEPAR:	.DB "  "
SEPAU:	.DB " | $"
SPACE:	.DB " $"
FINAL:	.DB 0Dh, 0Ah, "Вывод окончен.$"
;
D_DSKT:	.dw 029BEh	; всего дискет
D_CURD:	.dw 00001h	; текущая дискета
;
	.org (((($ - 1) / 010h) + 1) * 010h)	;Выравнивание на адрес ХХX0h
BufHDD:	; .db 000h  ; тут и далее 528 байт буфер для сохранения сектора диска при тестах
	.END
