        IDENTIFICATION DIVISION.
        PROGRAM-ID. BANK6 IS INITIAL PROGRAM.

        ENVIRONMENT DIVISION.
        CONFIGURATION SECTION.
        SPECIAL-NAMES.
            CRT STATUS IS KEYBOARD-STATUS.

        INPUT-OUTPUT SECTION.
        FILE-CONTROL.
            SELECT TARJETAS ASSIGN TO DISK
            ORGANIZATION IS INDEXED
            ACCESS MODE IS DYNAMIC
            RECORD KEY IS TNUM-E
            FILE STATUS IS FST.

            SELECT F-MOVIMIENTOS ASSIGN TO DISK
            ORGANIZATION IS INDEXED
            ACCESS MODE IS DYNAMIC
            RECORD KEY IS MOV-NUM
            FILE STATUS IS FSM.

            SELECT F-TRANSFERENCIAS ASSIGN TO DISK
            ORGANIZATION IS INDEXED
            ACCESS MODE IS DYNAMIC
            RECORD KEY IS TRF-NUM
            FILE STATUS IS FSTF.

        DATA DIVISION.
        FILE SECTION.
        FD TARJETAS
            LABEL RECORD STANDARD
            VALUE OF FILE-ID IS "tarjetas.ubd".
        01 TAJETAREG.
            02 TNUM-E               PIC 9(16).
            02 TPIN-E               PIC 9(4).

        FD F-MOVIMIENTOS
            LABEL RECORD STANDARD
            VALUE OF FILE-ID IS "movimientos.ubd".
        01 MOVIMIENTO-REG.
            02 MOV-NUM              PIC 9(35).
            02 MOV-TARJETA          PIC 9(16).
            02 MOV-ANO              PIC 9(4).
            02 MOV-MES              PIC 9(2).
            02 MOV-DIA              PIC 9(2).
            02 MOV-HOR              PIC 9(2).
            02 MOV-MIN              PIC 9(2).
            02 MOV-SEG              PIC 9(2).
            02 MOV-IMPORTE-ENT      PIC S9(7).
            02 MOV-IMPORTE-DEC      PIC 9(2).
            02 MOV-CONCEPTO         PIC X(35).
            02 MOV-SALDOPOS-ENT     PIC S9(9).
            02 MOV-SALDOPOS-DEC     PIC 9(2).

        FD F-TRANSFERENCIAS
            LABEL RECORD STANDARD
            VALUE OF FILE-ID IS "transferencias.ubd".
        01 TRANSFERENCIA-REG.
            02 TRF-NUM              PIC 9(16).
            02 TRF-CTA-ORIGEN       PIC 9(16).
            02 TRF-CTA-DESTINO      PIC 9(16).
            02 TRF-NOM-DESTINO      PIC X(35).
            02 TRF-IMPORTE-ENT      PIC 9(7).
            02 TRF-IMPORTE-DEC      PIC 9(2).
            02 TRF-TIPO             PIC X(1).
            02 TRF-FEC-PUNTUAL.
                05 TRF-ANO          PIC 9(4).
                05 TRF-MES          PIC 9(2).
                05 TRF-DIA          PIC 9(2).
            02 TRF-DIA-MES          PIC 9(2).
            02 TRF-ESTADO           PIC X(1).
            02 TRF-FEC-ALTA.
                05 TRF-ALTA-ANO     PIC 9(4).
                05 TRF-ALTA-MES     PIC 9(2).
                05 TRF-ALTA-DIA     PIC 9(2).

        WORKING-STORAGE SECTION.
        77 FST                      PIC X(2) VALUE "00".
        77 FSM                      PIC X(2) VALUE "00".
        77 FSTF                     PIC X(2) VALUE "00".

        78 BLACK                    VALUE 0.
        78 BLUE                     VALUE 1.
        78 GREEN                    VALUE 2.
        78 CYAN                     VALUE 3.
        78 RED                      VALUE 4.
        78 MAGENTA                  VALUE 5.
        78 YELLOW                   VALUE 6.
        78 WHITE                    VALUE 7.

        01 CAMPOS-FECHA.
            05 FECHA.
                10 ANO              PIC 9(4).
                10 MES              PIC 9(2).
                10 DIA              PIC 9(2).
            05 HORA.
                10 HORAS            PIC 9(2).
                10 MINUTOS          PIC 9(2).
                10 SEGUNDOS         PIC 9(2).
                10 MILISEGUNDOS     PIC 9(2).
            05 DIF-GMT              PIC S9(4).

        01 KEYBOARD-STATUS          PIC 9(4).
            88 ENTER-PRESSED        VALUE 0.
            88 PGUP-PRESSED         VALUE 2001.
            88 PGDN-PRESSED         VALUE 2002.
            88 UP-ARROW-PRESSED     VALUE 2003.
            88 DOWN-ARROW-PRESSED   VALUE 2004.
            88 ESC-PRESSED          VALUE 2005.

        77 PRESSED-KEY              PIC X(1).

        77 LAST-MOV-NUM             PIC 9(35).
        77 LAST-USER-ORD-MOV-NUM    PIC 9(35).
        77 LAST-USER-DST-MOV-NUM    PIC 9(35).
        77 LAST-TRF-NUM             PIC 9(16).

        77 SALDO-ORD-ENT            PIC S9(9) VALUE 0.
        77 SALDO-ORD-DEC            PIC 9(2) VALUE 0.

        77 EURENT-USUARIO           PIC 9(7).
        77 EURDEC-USUARIO           PIC 9(2).
        77 CUENTA-DESTINO           PIC 9(16).
        77 NOMBRE-DESTINO           PIC X(25).

        77 CENT-SALDO-ORD-USER      PIC S9(9).
        77 CENT-SALDO-DST-USER      PIC S9(9).
        77 CENT-IMPOR-USER          PIC S9(9).

        77 MSJ-ORD                  PIC X(35) VALUE "Transferimos".
        77 MSJ-DST                  PIC X(35) VALUE "Nos transfieren".

        77 TIPO-TRF-OPT             PIC 9(1) VALUE 1.
        77 TRF-DIA-USR              PIC 9(2).
        77 TRF-MES-USR              PIC 9(2).
        77 TRF-ANO-USR              PIC 9(4).
        77 TRF-DIAMES-USR           PIC 9(2).

        77 FECHA-HOY-NUM            PIC 9(8).
        77 FECHA-TRF-NUM            PIC 9(8).

        77 ES-HOY                   PIC 9(1) VALUE 0.

        LINKAGE SECTION.
        77 TNUM                     PIC 9(16).

        SCREEN SECTION.
        01 BLANK-SCREEN.
            05 FILLER LINE 1 BLANK SCREEN BACKGROUND-COLOR BLACK.

        01 FORM-TRANSFERENCIA.
            05 FILLER BLANK WHEN ZERO AUTO UNDERLINE
                LINE 11 COL 44 PIC 9(16) USING CUENTA-DESTINO.
            05 FILLER AUTO UNDERLINE
                LINE 12 COL 44 PIC X(25) USING NOMBRE-DESTINO.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 13 COL 44 PIC 9(7) USING EURENT-USUARIO.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 13 COL 53 PIC 9(2) USING EURDEC-USUARIO.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 15 COL 50 PIC 9(1) USING TIPO-TRF-OPT.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 17 COL 44 PIC 9(2) USING TRF-DIA-USR.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 17 COL 48 PIC 9(2) USING TRF-MES-USR.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 17 COL 52 PIC 9(4) USING TRF-ANO-USR.
            05 FILLER BLANK ZERO UNDERLINE
                LINE 19 COL 47 PIC 9(2) USING TRF-DIAMES-USR.

        01 SALDO-DISPLAY.
            05 FILLER SIGN IS LEADING SEPARATE
                LINE 09 COL 33 PIC -9(7) FROM SALDO-ORD-ENT.
            05 FILLER LINE 09 COL 41 VALUE ",".
            05 FILLER LINE 09 COL 42 PIC 99 FROM SALDO-ORD-DEC.
            05 FILLER LINE 09 COL 45 VALUE "EUR".

        PROCEDURE DIVISION USING TNUM.
        INICIO.
            SET ENVIRONMENT 'COB_SCREEN_EXCEPTIONS' TO 'Y'.

            MOVE FUNCTION CURRENT-DATE TO CAMPOS-FECHA.

            INITIALIZE CUENTA-DESTINO.
            INITIALIZE NOMBRE-DESTINO.
            INITIALIZE EURENT-USUARIO.
            INITIALIZE EURDEC-USUARIO.
            INITIALIZE LAST-MOV-NUM.
            INITIALIZE LAST-USER-ORD-MOV-NUM.
            INITIALIZE LAST-USER-DST-MOV-NUM.
            INITIALIZE LAST-TRF-NUM.
            INITIALIZE SALDO-ORD-ENT.
            INITIALIZE SALDO-ORD-DEC.
            INITIALIZE CENT-SALDO-ORD-USER.

            MOVE 1 TO TIPO-TRF-OPT.
            MOVE DIA TO TRF-DIA-USR.
            MOVE MES TO TRF-MES-USR.
            MOVE ANO TO TRF-ANO-USR.
            MOVE DIA TO TRF-DIAMES-USR.
            MOVE 0 TO ES-HOY.

        IMPRIMIR-CABECERA.
            DISPLAY BLANK-SCREEN.
            DISPLAY(2, 26) "Cajero Automatico UnizarBank"
                WITH FOREGROUND-COLOR IS CYAN.

            MOVE FUNCTION CURRENT-DATE TO CAMPOS-FECHA.

            DISPLAY(4, 32) DIA.
            DISPLAY(4, 34) "-".
            DISPLAY(4, 35) MES.
            DISPLAY(4, 37) "-".
            DISPLAY(4, 38) ANO.
            DISPLAY(4, 44) HORAS.
            DISPLAY(4, 46) ":".
            DISPLAY(4, 47) MINUTOS.

        OBTENER-SALDO-ORDENANTE.
            OPEN INPUT F-MOVIMIENTOS.
            IF FSM NOT = 00 THEN
                GO TO PSYS-ERR
            END-IF.

        LECTURA-MOVIMIENTOS.
            READ F-MOVIMIENTOS NEXT RECORD
                AT END GO TO SALDO-LEIDO.
            IF MOV-TARJETA = TNUM THEN
                IF LAST-USER-ORD-MOV-NUM <= MOV-NUM THEN
                    MOVE MOV-NUM TO LAST-USER-ORD-MOV-NUM
                    MOVE MOV-SALDOPOS-ENT TO SALDO-ORD-ENT
                    MOVE MOV-SALDOPOS-DEC TO SALDO-ORD-DEC
                END-IF
            END-IF.
            IF LAST-MOV-NUM < MOV-NUM THEN
                MOVE MOV-NUM TO LAST-MOV-NUM
            END-IF.
            GO TO LECTURA-MOVIMIENTOS.

        SALDO-LEIDO.
            CLOSE F-MOVIMIENTOS.

            DISPLAY(7, 30) "Ordenar Transferencia".
            DISPLAY(9, 15) "Saldo Actual:".

            DISPLAY(24, 2) "Enter - Confirmar".
            DISPLAY(24, 66) "ESC - Cancelar".

            IF LAST-USER-ORD-MOV-NUM = 0 THEN
                MOVE 0 TO CENT-SALDO-ORD-USER
                MOVE 0 TO SALDO-ORD-ENT
                MOVE 0 TO SALDO-ORD-DEC
                DISPLAY(9, 33) "0,00 EUR"
            ELSE
                DISPLAY SALDO-DISPLAY
                COMPUTE CENT-SALDO-ORD-USER = (SALDO-ORD-ENT * 100)
                                              + SALDO-ORD-DEC
            END-IF.

        DIBUJAR-FORMULARIO.
            DISPLAY(11, 15) "Cuenta destino:".
            DISPLAY(12, 15) "Titular destino:".
            DISPLAY(13, 15) "Cantidad a transferir:".
            DISPLAY(13, 51) ",".
            DISPLAY(13, 56) "EUR".

            DISPLAY(15, 15) "Tipo (1: Puntual, 2: Periodica):".
            DISPLAY(17, 15) "Fecha puntual (DD-MM-AAAA):".
            DISPLAY(17, 46) "-".
            DISPLAY(17, 50) "-".
            DISPLAY(19, 15) "Dia del mes (si periodica 01-31):".

        ACEPTAR-DATOS.
            ACCEPT FORM-TRANSFERENCIA ON EXCEPTION
                IF ESC-PRESSED THEN
                    EXIT PROGRAM
                ELSE
                    GO TO ACEPTAR-DATOS
                END-IF.

            IF CUENTA-DESTINO = 0 THEN
                DISPLAY(21, 15) "Debe indicar la cuenta destino!               "
                    WITH FOREGROUND-COLOR IS WHITE
                         BACKGROUND-COLOR IS RED
                GO TO ACEPTAR-DATOS
            END-IF.

            IF CUENTA-DESTINO = TNUM THEN
                DISPLAY(21, 15) "La cuenta destino no puede ser la propia!     "
                    WITH FOREGROUND-COLOR IS WHITE
                         BACKGROUND-COLOR IS RED
                GO TO ACEPTAR-DATOS
            END-IF.

            COMPUTE CENT-IMPOR-USER = (EURENT-USUARIO * 100)
                                      + EURDEC-USUARIO.

            IF CENT-IMPOR-USER <= 0 THEN
                DISPLAY(21, 15) "Indique una cantidad mayor que cero!          "
                    WITH FOREGROUND-COLOR IS WHITE
                         BACKGROUND-COLOR IS RED
                GO TO ACEPTAR-DATOS
            END-IF.

            IF TIPO-TRF-OPT NOT = 1 AND TIPO-TRF-OPT NOT = 2 THEN
                DISPLAY(21, 15) "Tipo de transferencia no valido (1 o 2)!      "
                    WITH FOREGROUND-COLOR IS WHITE
                         BACKGROUND-COLOR IS RED
                GO TO ACEPTAR-DATOS
            END-IF.

            IF TIPO-TRF-OPT = 1 THEN
                IF TRF-DIA-USR < 1 OR TRF-DIA-USR > 31 OR
                   TRF-MES-USR < 1 OR TRF-MES-USR > 12 OR
                   TRF-ANO-USR < ANO THEN
                    DISPLAY(21, 15) "Fecha puntual no valida!                      "
                        WITH FOREGROUND-COLOR IS WHITE
                             BACKGROUND-COLOR IS RED
                    GO TO ACEPTAR-DATOS
                END-IF

                COMPUTE FECHA-HOY-NUM = (ANO * 10000)
                                        + (MES * 100)
                                        + DIA
                COMPUTE FECHA-TRF-NUM = (TRF-ANO-USR * 10000)
                                        + (TRF-MES-USR * 100)
                                        + TRF-DIA-USR

                IF FECHA-TRF-NUM < FECHA-HOY-NUM THEN
                    DISPLAY(21, 15) "La fecha no puede ser anterior a hoy!         "
                        WITH FOREGROUND-COLOR IS WHITE
                             BACKGROUND-COLOR IS RED
                    GO TO ACEPTAR-DATOS
                END-IF

                IF FECHA-TRF-NUM = FECHA-HOY-NUM THEN
                    MOVE 1 TO ES-HOY
                    IF CENT-IMPOR-USER > CENT-SALDO-ORD-USER THEN
                        DISPLAY(21, 15) "Saldo insuficiente en cuenta para hoy!        "
                            WITH FOREGROUND-COLOR IS WHITE
                                 BACKGROUND-COLOR IS RED
                        GO TO ACEPTAR-DATOS
                    END-IF
                ELSE
                    MOVE 0 TO ES-HOY
                END-IF
            ELSE
                IF TRF-DIAMES-USR < 1 OR TRF-DIAMES-USR > 31 THEN
                    DISPLAY(21, 15) "Dia del mes invalido (debe ser 01 a 31)!      "
                        WITH FOREGROUND-COLOR IS WHITE
                             BACKGROUND-COLOR IS RED
                    GO TO ACEPTAR-DATOS
                END-IF
                MOVE 0 TO ES-HOY
            END-IF.

            GO TO REALIZAR-TRF-VERIFICACION.

        REALIZAR-TRF-VERIFICACION.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(07, 30) "Ordenar Transferencia".
            DISPLAY(09, 15) "Va a ordenar una transferencia por:".
            DISPLAY(09, 52) EURENT-USUARIO.
            DISPLAY(09, 59) ",".
            DISPLAY(09, 60) EURDEC-USUARIO.
            DISPLAY(09, 63) "EUR".
            DISPLAY(10, 15) "Destino: ".
            DISPLAY(10, 24) CUENTA-DESTINO.
            DISPLAY(11, 15) "Titular: ".
            DISPLAY(11, 24) NOMBRE-DESTINO.

            IF TIPO-TRF-OPT = 1 THEN
                DISPLAY(13, 15) "Modalidad: Puntual"
                DISPLAY(14, 15) "Fecha ejecucion: "
                DISPLAY(14, 32) TRF-DIA-USR
                DISPLAY(14, 34) "-"
                DISPLAY(14, 35) TRF-MES-USR
                DISPLAY(14, 37) "-"
                DISPLAY(14, 38) TRF-ANO-USR
                IF ES-HOY = 1 THEN
                    DISPLAY(16, 15) "Estado: Se ejecutara AHORA (inmediata)"
                ELSE
                    DISPLAY(16, 15) "Estado: Quedara programada (PENDIENTE)"
                END-IF
            ELSE
                DISPLAY(13, 15) "Modalidad: Periodica mensual"
                DISPLAY(14, 15) "Dia de cargo mensual: Los dias "
                DISPLAY(14, 46) TRF-DIAMES-USR
                DISPLAY(14, 49) "de cada mes"
                DISPLAY(16, 15) "Estado: Quedara programada (PERIODICA)"
            END-IF.

            DISPLAY(24, 2) "Enter - Confirmar".
            DISPLAY(24, 66) "ESC - Cancelar".

        ENTER-VERIFICACION.
            ACCEPT PRESSED-KEY LINE 24 COL 80 ON EXCEPTION
            IF ESC-PRESSED THEN
                EXIT PROGRAM
            ELSE
                IF ENTER-PRESSED THEN
                    GO TO VERIFICACION-CTA-CORRECTA
                ELSE
                    GO TO ENTER-VERIFICACION
                END-IF
            END-IF.

        VERIFICACION-CTA-CORRECTA.
            OPEN I-O TARJETAS.
            IF FST NOT = 00 THEN
               GO TO PSYS-ERR
            END-IF.

            MOVE CUENTA-DESTINO TO TNUM-E.
            READ TARJETAS INVALID KEY GO TO USER-BAD.
            CLOSE TARJETAS.

            OPEN I-O F-TRANSFERENCIAS.
            IF FSTF NOT = 00 THEN
                GO TO PSYS-ERR
            END-IF.

            MOVE 0 TO LAST-TRF-NUM.
        LECTURA-ULTIMA-TRF.
            READ F-TRANSFERENCIAS NEXT RECORD
                AT END GO TO ULTIMA-TRF-LEIDA.
            IF TRF-NUM > LAST-TRF-NUM THEN
                MOVE TRF-NUM TO LAST-TRF-NUM
            END-IF.
            GO TO LECTURA-ULTIMA-TRF.

        ULTIMA-TRF-LEIDA.
            ADD 1 TO LAST-TRF-NUM.

            MOVE LAST-TRF-NUM       TO TRF-NUM.
            MOVE TNUM               TO TRF-CTA-ORIGEN.
            MOVE CUENTA-DESTINO     TO TRF-CTA-DESTINO.
            MOVE NOMBRE-DESTINO     TO TRF-NOM-DESTINO.
            MOVE EURENT-USUARIO     TO TRF-IMPORTE-ENT.
            MOVE EURDEC-USUARIO     TO TRF-IMPORTE-DEC.

            MOVE ANO                TO TRF-ALTA-ANO.
            MOVE MES                TO TRF-ALTA-MES.
            MOVE DIA                TO TRF-ALTA-DIA.

            IF TIPO-TRF-OPT = 1 THEN
                MOVE 'P'            TO TRF-TIPO
                MOVE TRF-DIA-USR    TO TRF-DIA
                MOVE TRF-MES-USR    TO TRF-MES
                MOVE TRF-ANO-USR    TO TRF-ANO
                MOVE 0              TO TRF-DIA-MES
                IF ES-HOY = 1 THEN
                    MOVE 'E'        TO TRF-ESTADO
                ELSE
                    MOVE 'P'        TO TRF-ESTADO
                END-IF
            ELSE
                MOVE 'M'            TO TRF-TIPO
                MOVE 0              TO TRF-DIA
                MOVE 0              TO TRF-MES
                MOVE 0              TO TRF-ANO
                MOVE TRF-DIAMES-USR TO TRF-DIA-MES
                MOVE 'P'            TO TRF-ESTADO
            END-IF.

            WRITE TRANSFERENCIA-REG INVALID KEY GO TO PSYS-ERR.
            CLOSE F-TRANSFERENCIAS.

            IF ES-HOY = 1 THEN
                GO TO PROCESAR-MOVIMIENTOS-HOY
            ELSE
                GO TO P-EXITO
            END-IF.

        PROCESAR-MOVIMIENTOS-HOY.
            OPEN I-O F-MOVIMIENTOS.
            IF FSM NOT = 00 THEN
                GO TO PSYS-ERR
            END-IF.

            MOVE 0 TO MOV-NUM.
            MOVE 0 TO LAST-USER-DST-MOV-NUM.
            MOVE 0 TO CENT-SALDO-DST-USER.

        LECTURA-SALDO-DST.
            READ F-MOVIMIENTOS NEXT RECORD
                AT END GO TO GUARDAR-MOV-HOY.
            IF MOV-TARJETA = CUENTA-DESTINO THEN
                IF LAST-USER-DST-MOV-NUM <= MOV-NUM THEN
                    MOVE MOV-NUM TO LAST-USER-DST-MOV-NUM
                    COMPUTE CENT-SALDO-DST-USER =
                        (MOV-SALDOPOS-ENT * 100) + MOV-SALDOPOS-DEC
                END-IF
            END-IF.
            GO TO LECTURA-SALDO-DST.

        GUARDAR-MOV-HOY.
            MOVE FUNCTION CURRENT-DATE TO CAMPOS-FECHA.

            ADD 1 TO LAST-MOV-NUM.
            MOVE LAST-MOV-NUM   TO MOV-NUM.
            MOVE TNUM           TO MOV-TARJETA.
            MOVE ANO            TO MOV-ANO.
            MOVE MES            TO MOV-MES.
            MOVE DIA            TO MOV-DIA.
            MOVE HORAS          TO MOV-HOR.
            MOVE MINUTOS        TO MOV-MIN.
            MOVE SEGUNDOS       TO MOV-SEG.

            MOVE EURENT-USUARIO TO MOV-IMPORTE-ENT.
            MULTIPLY -1 BY MOV-IMPORTE-ENT.
            MOVE EURDEC-USUARIO TO MOV-IMPORTE-DEC.
            MOVE MSJ-ORD        TO MOV-CONCEPTO.

            SUBTRACT CENT-IMPOR-USER FROM CENT-SALDO-ORD-USER.
            COMPUTE MOV-SALDOPOS-ENT = (CENT-SALDO-ORD-USER / 100).
            MOVE FUNCTION MOD(CENT-SALDO-ORD-USER, 100)
                TO MOV-SALDOPOS-DEC.

            WRITE MOVIMIENTO-REG INVALID KEY GO TO PSYS-ERR.

            ADD 1 TO LAST-MOV-NUM.
            MOVE LAST-MOV-NUM   TO MOV-NUM.
            MOVE CUENTA-DESTINO TO MOV-TARJETA.
            MOVE ANO            TO MOV-ANO.
            MOVE MES            TO MOV-MES.
            MOVE DIA            TO MOV-DIA.
            MOVE HORAS          TO MOV-HOR.
            MOVE MINUTOS        TO MOV-MIN.
            MOVE SEGUNDOS       TO MOV-SEG.

            MOVE EURENT-USUARIO TO MOV-IMPORTE-ENT.
            MOVE EURDEC-USUARIO TO MOV-IMPORTE-DEC.
            MOVE MSJ-DST        TO MOV-CONCEPTO.

            ADD CENT-IMPOR-USER TO CENT-SALDO-DST-USER.
            COMPUTE MOV-SALDOPOS-ENT = (CENT-SALDO-DST-USER / 100).
            MOVE FUNCTION MOD(CENT-SALDO-DST-USER, 100)
                TO MOV-SALDOPOS-DEC.

            WRITE MOVIMIENTO-REG INVALID KEY GO TO PSYS-ERR.
            CLOSE F-MOVIMIENTOS.

        P-EXITO.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(07, 30) "Ordenar Transferencia".
            IF ES-HOY = 1 THEN
                DISPLAY(11, 19) "Transferencia ejecutada correctamente!"
            ELSE
                DISPLAY(11, 19) "Transferencia programada correctamente!"
            END-IF.
            DISPLAY(24, 33) "Enter - Aceptar".
            GO TO EXIT-ENTER.

        PSYS-ERR.
            CLOSE TARJETAS.
            CLOSE F-MOVIMIENTOS.
            CLOSE F-TRANSFERENCIAS.

            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(09, 25) "Ha ocurrido un error interno"
                WITH FOREGROUND-COLOR IS WHITE
                     BACKGROUND-COLOR IS RED.
            DISPLAY(11, 32) "Vuelva mas tarde"
                WITH FOREGROUND-COLOR IS WHITE
                     BACKGROUND-COLOR IS RED.
            DISPLAY(24, 33) "Enter - Aceptar".

        EXIT-ENTER.
            ACCEPT PRESSED-KEY LINE 24 COL 80
            IF ENTER-PRESSED
                EXIT PROGRAM
            ELSE
                GO TO EXIT-ENTER.

        USER-BAD.
            CLOSE TARJETAS.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(9, 22) "La cuenta introducida es incorrecta"
                WITH FOREGROUND-COLOR IS WHITE
                     BACKGROUND-COLOR IS RED.
            DISPLAY(24, 33) "Enter - Salir".
            GO TO EXIT-ENTER.
