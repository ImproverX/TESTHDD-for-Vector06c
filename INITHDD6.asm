;(перед компилированием преобразовать в KOI-8R)
	.ORG    00100h
;
#DEFINE BufHDD1 BufHDD0+512+16	; второй буфер
;
L_0100:	CALL    L_0A08	; вывод строки и отбивки дефисами
	.db 01Bh, 05Bh, "$"	;Ch, 01Bh, 05Eh, "$"
	CALL    L_0A08	; вывод строки и отбивки дефисами
	.db "ИНИЦИАЛИЗАЦИЯ НАКОПИТЕЛЯ НА "
	.db "ЖЕСТКОМ МАГНИТНОМ ДИСКЕ.$"
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "В.ФРОЛОВ 1995 / Improver 2026$"
	LXI  SP,08000h
	
L_045F: CALL    L_0A08	; вывод строки и отбивки дефисами
	.db "Определение параметров НЖМД$"
;
L_047G:	CALL	L_D8DC	; сброс и проверка готовности НЖМД
	MVI  A, 0E0h	; 1110 0000
	OUT     056h	; режим, выбор устройства 0
	MVI  A, 0ECh	; ECH = идентификация устройства (получение данных о конфигурации)
	OUT     057h	; регистр команды
	CALL	L_D9D9	; проверка готовности НЖМД
	ANI     008h	; 0000 1000 :	запрос данных. Буфер ждет данных (занято)
	JNZ     L_047X
	CALL	L_D9F9	; получение кода ошибки 2
	CALL    L_0B6N	; вывод A в шестнадцатиричном формате с новой строки
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db ": не готов НЖМД$"
;	JZ      L_047G
	JMP     L_047G
;
L_047X:	MVI  D, 000h	; D=0
	LXI  H,	BufHDD0	; буфер
	CALL	L_D8C1	; чтение данных
	JNC	L_04N0	; всё ок
	CALL    L_0B6N	; вывод A в шестнадцатиричном формате с новой строки
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db ": не читаются параметры НЖМД$"
	JZ	L_047G	; повторить
	JMP	L_04E2	; продолжить
;
L_04ER:	CALL    L_0A56	; вывод строки далее до "$"
	.db "Cекторов$"
	LHLD	BufHDD0+12	; число секторов из ID
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ", головок$"
	LHLD	BufHDD0+6	; число головок из ID
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ", цилиндров$"
	LHLD    BufHDD0+2	; число цилиндров из ID
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A7B	; вывод ошибки (?)
	.db "получены неправильные "
	.db "параметры НЖМД", 00Dh, 00Ah
	.db "$"
	JZ	L_047G
L_04E2:	CALL    L_0A56	; вывод строки далее до "$"
	.db "Подбор значений$"
L_047C:	MVI  A, 010h	; 1xH = сброс на цилиндр 0 (x = step rate)
	OUT     057h	; Запись:	регистр команды
	MVI  B, 001h
L_047E: CALL    L_0AF5	; "Прервать?"
	JZ      L_04CA
	CALL	L_D8DC	; сброс и проверка готовности НЖМД
	JC	L_047Y	; >> ошибка
	MOV  A, B
	OUT     053h	; ++ Номер логического сектора для чтения/записи
	XRA  A
	OUT     054h	; Цилиндр, младшие биты
	OUT     055h	; Цилиндр, старшие биты
	MVI  A, 0A0h	; 1010 0000	
	OUT     056h	; Биты определяют устройство и головку для операции чтения/записи, режим CHS
	CALL    L_VRF	; верификация сектора
	JNZ     L_04CA	; >> ошибка
	INR  B
	JNZ     L_047E	; цикл по секторам
L_047Y:	CALL    L_0A7B	; вывод ошибки (?)
	.db "вычисление числа секторов "
	.db "на дорожке$"
	JZ      L_047C
L_04CA:	MOV  L, B
	MVI  H, 000h
	DCX  H
	SHLD    BufHDD0+12	; число секторов
	CALL    L_DOT	; вывод точки
L_04FD:	MVI  A, 010h	; 1xH = сброс на цилиндр 0 (x = step rate)
	OUT     057h	; Запись:	регистр команды
	MVI  B, 0A0h	; 1010 0000	
L_04FF: CALL    L_0AF5	; "Прервать?"
	JZ      L_0523
	CALL	L_D8DC	; сброс и проверка готовности НЖМД
	JC	L_04FY	; >> ошибка
	OUT     053h	; Номер логического сектора для чтения/записи
	XRA  A
	OUT     054h	; Цилиндр, младшие биты
	OUT     055h	; Цилиндр, старшие биты
	MOV  A, B
	OUT     056h	; ++ Биты определяют устройство и головку для операции чтения/записи, режим CHS
	CALL    L_VRF	; верификация сектора
	JNZ     L_0523	; >>
	INR  B
	MOV  A, B
	CPI     0B1h
	JC	L_04FF	; цикл по головкам
L_04FY:	CALL    L_0A7B	; вывод ошибки (?)
	.db "вычисление числа головок$"
	JZ      L_04FD
L_0523:	MVI  A, 01Fh
	ANA  B
	MOV  L, A
	MVI  H, 000h
	SHLD    BufHDD0+6	; число головок
	CALL    L_DOT	; вывод точки
L_0550:	MVI  A, 010h	; 1xH = сброс на цилиндр 0 (x = step rate)
	OUT     057h	; Запись:	регистр команды
	LXI  H, 00000h
L_0553: CALL    L_0AF5	; "Прервать?"
	JZ      L_059C
	CALL	L_D8DC	; сброс и проверка готовности НЖМД
	JC	L_055Y	; >> ошибка
	OUT     053h	; Номер логического сектора для чтения/записи
	MOV  A, L
	OUT     054h	; ++ Цилиндр, младшие биты
	MOV  A, H
	OUT     055h	; ++ Цилиндр, старшие биты
	MVI  A, 0A0h	; 1010 0000	
	OUT     056h	; Биты определяют устройство и головку для операции чтения/записи, режим CHS
	CALL    L_VRF	; верификация сектора
	JNZ     L_059C
	INR  L
	JNZ     L_0553	; цикл по цилиндрам (L)
	PUSH H
	CALL    L_DOT	; вывод точки
	POP  H
	INR  H	
	MOV  A, H
	CPI     020h	; максимум 2000h
	JNZ     L_0553	; цикл по цилиндрам (H)
L_055Y:	CALL    L_0A7B	; вывод ошибки (?)
	.db "вычисление числа цилиндров$"
	JZ      L_0550
L_059C:	SHLD    BufHDD0+2	; число цилиндров
	XRA  A
	STA	BufHDD0+1	; признак расчётов
	MVI  A, 010h	; 1xH = сброс на цилиндр 0 (x = step rate)
	OUT     057h	; Запись:	регистр команды
L_04N0: LHLD	BufHDD0+6	; число головок
	XRA  A
	CMP  H
	JNZ	L_04ER	; > 255
	ORA  L
	JZ	L_04ER	; = 0
	CPI	011h
	JNC	L_04ER	; >= 17
	SHLD	D_MGOL
	LHLD	BufHDD0+12	; число секторов
	XRA  A
	CMP  H
	JNZ	L_04ER	; > 255
	ORA  L
	JZ	L_04ER	; = 0
	SHLD	D_MSEC
	LHLD	BufHDD0+2	; число цилиндров
	MOV  A, H
	ORA  L	
	JZ	L_04ER	; = 0
	SHLD	D_MCIL
; подтверждение значений
	CALL    L_0A56	; вывод строки далее до "$"
	.db "секторов : $"
	LHLD	D_MSEC
	CALL    L_0B3F	; вывод числа из HL
L_04EA: LXI  H, 00100h
	CALL    L_110F	; ввод шестнадцатиричного числа
	JZ      L_04EA
	LDA     L_1192
	ANA  A
	JZ      L_04FS
	CALL	L_1176	; проверка на HL=0
	JZ      L_04EA
	SHLD    D_MSEC	; всего секторов
L_04FS:	CALL    L_0A56	; вывод строки далее до "$"
	.db "головок  : $"
	LHLD	D_MGOL
	CALL    L_0B3F	; вывод числа из HL
L_053D: LXI  H, 00011h
	CALL    L_110F	; ввод шестнадцатиричного числа
	JZ      L_053D
	LDA     L_1192
	ANA  A
	JZ      L_055S
	CALL	L_1176	; проверка на HL=0
	JZ      L_053D
	SHLD    D_MGOL	; всего головок
L_055S:	CALL    L_0A56	; вывод строки далее до "$"
	.db "цилиндров: $"
	LHLD    D_MCIL	; всего цилиндров
	CALL    L_0B3F	; вывод числа из HL
L_05B3: LXI  H, 0FFFFh
	CALL    L_110F	; ввод шестнадцатиричного числа
	JZ      L_05B3
	LDA     L_1192
	ANA  A
	JZ      L_05C6
	CALL	L_1176	; проверка на HL=0
	JZ      L_05B3
	SHLD    D_MCIL	; всего цилиндров
L_05C6:	LXI  D, 00000h
	LDA     D_MSEC	; всего секторов
	LHLD    D_MCIL	; всего цилиндров
	CALL    L_0ED2
	LDA     D_MGOL	; всего головок
	CALL    L_0ED2
	MVI  A, 020h
	CALL    L_0ED2
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "секторов (LBA): $"
	LXI  H, L_0F0B
	CALL	L_QHEX	; вывод 4 байт в шестнадцатиричном формате (L_0F0C,L_0F0B,L_0F0A,L_0F09)
	LDA	BufHDD0+1
	ORA  A
	JZ	L_05CZ	; пропускаем, если была ошибка определения параметров
	CALL    L_0A5C	; вывод строки далее до "$"
	.db 00Dh,00Ah,"секторов (LBA) из ID диска: $"
	LXI  H, BufHDD0+122
	CALL	L_QHEX	; вывод 4 байт в шестнадцатиричном формате (BufHDD2+123,+122,+121,+120)
L_05CZ:	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Доступная память НЖМД "
	.db "составляет$"
	LDA	L_0F0B+1
	ORA  A
	JNZ	L_05CX	; объём > FFFFh
	LHLD    L_0F0F	;
	MVI  A, 01Fh
	CMP  H
	JNC	L_05CY	; объём <= 1Fxx
L_05CX:	LXI  H, 01FFFh	; =8191 мегабайт -- максимальный объём для Вектора
L_05CY:	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "мегабайт$"
	LXI  H, 00000h
	SHLD    D_DSKT	; число дискет = 0
	LHLD    L_0F0B
	XCHG
	LHLD    L_0F09	; DEHL -- всего секторов LBA
	MOV  A, D
	ORA  A
	JNZ	L_MDT	; > 00FF-FFFFh
	LXI  B, 0FFAEh	; -52h секторов на загрузочную область
L_CDT:	DAD  B
	MOV  A, E
	ACI     0FFh
	MOV  E, A
	JNC	L_PDT	; >>>
	PUSH H
	LHLD    D_DSKT	; число дискет
	INX  H		; +1
	SHLD    D_DSKT
	POP  H
	LXI  B, 0F9DEh	; -622h секторов в одной дискете
	JMP     L_CDT
;
L_MDT:	LXI  H, 029BFh
	SHLD    D_DSKT	; максимально возможное число дискет +1
;
L_PDT:	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "НЖМД может быть разбит на $"
	LHLD    D_DSKT
	SHLD	L_PDT2+1
	DCX  H
	SHLD    D_DSKT
;	CALL    L_0B3F	; вывод числа из HL
	XCHG
	CALL    L_CB86	; вывод числа из DE в десятичном виде
	CALL    L_0A5C	; вывод строки далее до "$"
	.db "(D) полных дискет$"
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "дискет   : $"
	LHLD    D_DSKT	; число дискет
	CALL    L_0B3F	; вывод числа из HL
L_PDT2: LXI  H, 0FFFFh
	CALL    L_110F	; ввод шестнадцатиричного числа
	JZ      L_PDT2
	LDA     L_1192
	ANA  A
	JZ      L_PDT3
	CALL	L_1176	; проверка на HL=0
	JZ      L_PDT2
	SHLD    D_DSKT	; всего дискет
L_PDT3:	CALL	L_0A08	; вывод строки и отбивки дефисами
	.db "Запись параметров на НЖМД$"
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
	XRA  A
	STA	D_RERR
	CALL    L_0A56	; вывод строки далее до "$"
	.db "секторов$"
	LHLD	BufHDD0+80h	; число секторов из HDD
	XRA  A
	STA	D_RERR	; обнуляем признак изменения конфигурации
	MOV  H, A
	LDA	D_MSEC
	SUB  L
	JZ	$+6
	STA	D_RERR	; изменения есть -- заносим "неноль"
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ", головок$"
	LHLD	BufHDD0+81h	; число головок из HDD
	MVI  H, 0
	LDA	D_MGOL
	SUB  L
	JZ	$+6
	STA	D_RERR	; изменения есть -- заносим "неноль"
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ", цилиндров$"
	LHLD	D_MCIL
	XCHG
	LHLD    BufHDD0+82h	; число цилиндров из HDD
	MOV  A, H
	SUB  D
	JZ	$+6
	STA	D_RERR	; изменения есть -- заносим "неноль"
	MOV  A, L
	SUB  E
	JZ	$+6
	STA	D_RERR	; изменения есть -- заносим "неноль"
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ",$"
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "дискет$"
	LHLD    BufHDD0+84h	; число дискет из HDD
	CALL    L_0B3F	; вывод числа из HL
	LDA	D_RERR
	ORA  A
	JZ	L_NOCH	; изменений нет -- выход
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "Новая конфигурация: $"
	XRA  A
	STA	D_RERR
	CALL    L_0A56	; вывод строки далее до "$"
	.db "секторов$"
	LHLD	D_MSEC
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ", головок$"
	LHLD	D_MGOL
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ", цилиндров$"
	LHLD	D_MCIL
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db ",$"
	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "дискет$"
	LHLD    D_DSKT
	CALL    L_0B3F	; вывод числа из HL
	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Выполнить запись$"
	JNZ	L_NOCH	; изменений нет -- выход
L_WRS:	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "запись...$"
	LXI  H, BufHDD0+80h	; начало параметров
	LDA	D_MSEC	; число секторов -- заносим в буфер
	MOV  M, A
	INX  H
	LDA	D_MGOL	; число головок
	MOV  M, A
	INX  H
	XCHG
	LHLD	D_MCIL	; число цилиндров
	XCHG
	MOV  M, E
	INX  H
	MOV  M, D
	INX  H
	XCHG
	LHLD    D_DSKT	; число дискет
	XCHG
	MOV  M, E
	INX  H
	MOV  M, D
	MVI  B, 0FFh	; запись == FF
	LXI  D, 00000h
	MOV  C, D	; (C)(DE) (24 бита) -- номер сектора, 000000
	LXI  H, BufHDD0	; буфер
	CALL    L_RWHD	; запись LBA из буфера по адресу в HL
	JNC	L_WRS0	; >>> всё ок
	CALL    L_0B6N	; вывод A в шестнадцатиричном формате с новой строки
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db ": запись сектора НЖМД$"
	JZ	L_WRS	; повторить
L_WRS0:	CALL    L_0A56	; вывод cтроки до "$" с добавлением перевода строки в начале
	.db "проверка...$"
	LXI  D, 00000h
	MOV  C, D	; (C)(DE) (24 бита) -- номер сектора, 000000
	MOV  B, D	; чтение == 0
	LXI  H, BufHDD1	; второй буфер
	CALL    L_RWHD	; чтение LBA в буфер по адресу в HL
	JNC	L_WRS1	; >>> всё ок
	CALL    L_0B6N	; вывод A в шестнадцатиричном формате с новой строки
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db ": чтение сектора НЖМД$"
	JZ      L_WRS0
L_WRS1:	CALL    L_0DD4	; сравнение двух областей данных BufHDD0 и BufHDD1
	JNZ	L_WRS2	; >> записалось без ошибок
	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Повторить запись$"
	JNZ	L_NOCH	; изменений нет -- выход
L_WRS2:	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Конфигурация сохранена. "
	.db "Повторить$"
L_DONE:	JZ      L_045F
	JMP	00000h	; >>>>> Выход в ОС
;
L_NOCH:	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Изменений в конфигурации "
	.db "нет, запись не выполнялась. "
	.db "Повторить$"
	JMP	L_DONE
;
;----------------------------------------------------------------------------------------
; ПП сравнения двух областей данных
L_0DD4:	LXI  H, BufHDD0
L_0DD7:	LXI  D, BufHDD1
	LXI  B, 0200h	; сколько сравнивать
L_0DE4: LDAX D
	CMP  M
	JNZ     L_0DF5
	INX  H
	INX  D
	DCX  B
	MOV  A, B
	ORA  C
	JNZ     L_0DE4
	INR  A
	CALL    L_0A5C	; вывод строки далее до "$" без ПС
	.db " ошибок нет$"
	RET
;
L_0DF5:	CALL    L_0A5C	; вывод строки далее до "$"
	.db " несовпадение на байте$"
	MOV  A, C	; инвертируем BC
	CMA
	MOV  C, A
	MOV  A, B
	CMA
	MOV  B, A
	LXI  H, 0202h
	DAD  B		; HL = 0208h - BC
	CALL    L_0B3F	; вывод номера байта, на котором возникла ошибка
	CALL    L_0A7B	; вывод ошибки (?)
	.db " $"
	XRA  A
L_0E05: RET
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
; ПП вывода точки
L_DOT:	MVI  E, '.'
	MVI  C, 002h
	JMP	00005h
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
	CALL    00005h
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
	CALL    00005h
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
L_0AF5: PUSH B		; "Прервать?"
	PUSH H
	PUSH D
	MVI  C, 00Bh
	CALL    00005h
	ANA  A
	JZ      L_0B11
	MVI  C, 006h
	MVI  E, 0FFh
	CALL    00005h
	CALL    L_0B17	; вывод сообщения с "да/нет?"
	.db "Прервать$"
L_0B11: CPI     059h
	POP  D
	POP  H
	POP  B
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
	CALL    00005h
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
; вывод 4 байт в HEX с адреса в HL
L_QHEX:	INX  H
	MOV  A, M
	ORA  A
	MOV  B, A
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	DCX  H
	MOV  C, M
	MOV  A, B
	ORA  C
	MOV  B, A
	MOV  A, C
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	DCX  H
	MOV  C, M
	MOV  A, B
	ORA  C
	MOV  A, C
	CNZ	L_0B6F	; вывод A в шестнадцатиричном формате
	DCX  H
	MOV  A, M
	CALL	L_0B6F	; вывод A в шестнадцатиричном формате
	CALL	L_0A5C	; вывод строки далее до "$"
	.db " (H)$"
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
	JMP     00005h
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
L_110F: PUSH H
L_1110:	CALL    L_0A5C	; вывод строки далее до "$"
	.db " (H) ?$"
	LXI  H, L_1192
	MVI  B, 007h
L_111F: MVI  M, 000h
	INX  H
	DCR  B
	JNZ     L_111F
	LXI  D, L_1190
	MVI  C, 00Ah
	CALL    00005h
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
L_1160: POP  D
	MOV  A, H
	CMP  D
	JNZ     L_116E
	MOV  A, L
	CMP  E
	JNZ     L_116E
	JMP     L_1175
;
L_116E: JNC     L_1175
	XRA  A
	INR  A
	RET
;
L_1174: POP  H
L_1175: PUSH H
	CALL    L_0A7B	; вывод ошибки (?)
	.db "Не правильный номер$"
	XRA  A
	POP  H
	RET
;
L_1176:	MOV  A, H	; проверка на ввод нулевого значения
	ORA  L
	JZ      L_1175
	RET
;
L_0ED2: SHLD    L_0F09	; DEHL * A -> L_0F0F / L_0F0D -- вычисление секторов и объёма НЖМД
	XCHG
	SHLD    L_0F0B
	LXI  H, 00000h
	SHLD    L_0F0D
	SHLD    L_0F0F
	MOV  B, A
L_0EE3: LHLD    L_0F0D
	XCHG
	LHLD    L_0F09
	DAD  D
	SHLD    L_0F0D
	LHLD    L_0F0F
	XCHG
	LHLD    L_0F0B
	JNC     L_0EF9
	INX  H
L_0EF9: DAD  D
	SHLD    L_0F0F
	DCR  B
	JNZ     L_0EE3
	LHLD    L_0F0F
	XCHG
	LHLD    L_0F0D
	RET
; 
;----------------------------------------------------------------------------------------
L_VRF:	MVI  A, 001h	; (не быстрая верификация)
	OUT     052h	; Счетчик числа секторов для операции чтения/записи
	MVI  A, 041h	; 4xH = чтение для верификации (x = 1 -- без повторов)
	CALL    L_0E58	; << отправка команды
	ANI     0FDh	; отбрасываем бит 1
	CPI     050h	; "поиск завершен" + "устройство готово к операции"
	RET
;
L_0E58: PUSH PSW	; << отправка команды
L_0E59:	CALL    L_D9D9	; ожидание готовности НЖМД
	JNC     L_0E73
	CALL    L_0B6N	; вывод A в шестнадцатиричном формате с новой строки
	CALL    L_0A7C	; вывод ошибки (?) без перевода строки
	.db ": не готов НЖМД$"
	JZ      L_0E59
L_0E73: POP  PSW
	OUT     057h
L_0E76: CALL    L_D9D9	; ожидание готовности НЖМД
	RNC
	PUSH PSW
	CALL    L_0A7B	; вывод ошибки (?)
	.db "адаптер не может завершить "
	.db "выполнение команды$"
	POP  PSW
	JZ      L_0E76
	RET
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
D_MSEC: .dw 00000h	; всего секторов
D_MGOL: .dw 00000h	; всего головок
D_MCIL: .dw 00000h	; всего цилиндров
D_DSKT: .dw 00000h	; всего дискет
;
L_0F09: .dw 00000h	;
L_0F0B: .dw 00000h	; секторов LBA
L_0F0D: .dw 00000h	;
L_0F0F: .dw 00000h	; мегабайт
;
D_RERR:	.db 000h	; ошибка сравнения параметров
;
	.org (((($ - 1) / 010h) + 1) * 010h)	;Выравнивание на адрес ХХX0h
BufHDD0:	; .db 000h  ; тут и далее 528 байт буфер для сохранения сектора диска при тестах
	.END
