        IDENTIFICATION DIVISION.
        PROGRAM-ID. BANK9 IS INITIAL PROGRAM.

        ENVIRONMENT DIVISION.
        CONFIGURATION SECTION.
        SPECIAL-NAMES.
            CRT STATUS IS KEYBOARD-STATUS.

        INPUT-OUTPUT SECTION.
        FILE-CONTROL.
            SELECT F-TRANSFERENCIAS ASSIGN TO DISK
            ORGANIZATION IS INDEXED
            ACCESS MODE IS DYNAMIC
            RECORD KEY IS TRF-NUM
            FILE STATUS IS FSTF.

        DATA DIVISION.
        FILE SECTION.
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
        77 FSTF                     PIC X(2).

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

        77 DIA-DESDE                PIC 9(2).
        77 MES-DESDE                PIC 9(2).
        77 ANO-DESDE                PIC 9(4).
        77 DIA-HASTA                PIC 9(2).
        77 MES-HASTA                PIC 9(2).
        77 ANO-HASTA                PIC 9(4).

        77 FECHA-MIN                PIC 9(8).
        77 FECHA-MAX                PIC 9(8).
        77 FECHA-HOY                PIC 9(8).
        77 FECHA-REG                PIC 9(8).

        77 TOTAL-ENCONTRADAS        PIC 9(3) VALUE 0.
        77 INDICE                   PIC 9(3) VALUE 0.
        77 PAGINA-ACTUAL            PIC 9(2) VALUE 1.
        77 TOTAL-PAGINAS            PIC 9(2) VALUE 1.
        77 REG-INICIO-PAG           PIC 9(3) VALUE 1.
        77 REG-FIN-PAG              PIC 9(3) VALUE 1.
        77 I                        PIC 9(3) VALUE 0.
        77 LINEA-PANTALLA           PIC 9(2) VALUE 0.

        77 ES-VALIDA                PIC 9(1) VALUE 0.

        01 TABLA-TRANSFERENCIAS.
            05 T-ITEM OCCURS 60 TIMES.
                10 T-FECHA-TXT      PIC X(10).
                10 T-TIPO-TXT       PIC X(9).
                10 T-DESTINO        PIC 9(16).
                10 T-IMP-ENT        PIC 9(7).
                10 T-IMP-DEC        PIC 9(2).
                10 T-ESTADO-TXT     PIC X(9).

        LINKAGE SECTION.
        77 TNUM                     PIC 9(16).

        SCREEN SECTION.
        01 BLANK-SCREEN.
            05 FILLER LINE 1 BLANK SCREEN BACKGROUND-COLOR BLACK.

        01 FILTRO-FECHAS.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 12 COL 42 PIC 9(2) USING DIA-DESDE.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 12 COL 45 PIC 9(2) USING MES-DESDE.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 12 COL 48 PIC 9(4) USING ANO-DESDE.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 14 COL 42 PIC 9(2) USING DIA-HASTA.
            05 FILLER BLANK ZERO AUTO UNDERLINE
                LINE 14 COL 45 PIC 9(2) USING MES-HASTA.
            05 FILLER BLANK ZERO UNDERLINE
                LINE 14 COL 48 PIC 9(4) USING ANO-HASTA.

        PROCEDURE DIVISION USING TNUM.
        INICIO.
            SET ENVIRONMENT 'COB_SCREEN_EXCEPTIONS' TO 'Y'.
            SET ENVIRONMENT 'COB_SCREEN_ESC'        TO 'Y'.

            MOVE FUNCTION CURRENT-DATE TO CAMPOS-FECHA.
            COMPUTE FECHA-HOY = (ANO * 10000) + (MES * 100) + DIA.

            INITIALIZE DIA-DESDE.
            INITIALIZE MES-DESDE.
            INITIALIZE ANO-DESDE.
            INITIALIZE DIA-HASTA.
            INITIALIZE MES-HASTA.
            INITIALIZE ANO-HASTA.

        IMPRIMIR-CABECERA.
            DISPLAY BLANK-SCREEN.
            DISPLAY(2, 26) "Cajero Automatico UnizarBank"
                WITH FOREGROUND-COLOR IS CYAN.

            DISPLAY(4, 32) DIA.
            DISPLAY(4, 34) "-".
            DISPLAY(4, 35) MES.
            DISPLAY(4, 37) "-".
            DISPLAY(4, 38) ANO.
            DISPLAY(4, 44) HORAS.
            DISPLAY(4, 46) ":".
            DISPLAY(4, 47) MINUTOS.

        PANTALLA-FILTRO.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(8, 28) "Listado de transferencias".
            DISPLAY(10, 20) "Indique el intervalo de fechas a consultar:".

            DISPLAY(12, 20) "Fecha desde (DD-MM-AAAA):    -  -    ".
            DISPLAY(14, 20) "Fecha hasta (DD-MM-AAAA):    -  -    ".

            DISPLAY(16, 20) "(Deje en blanco para consultar todas)".

            DISPLAY(24, 02) "Enter - Buscar".
            DISPLAY(24, 66) "ESC - Cancelar".

            ACCEPT FILTRO-FECHAS ON EXCEPTION
                IF ESC-PRESSED THEN
                    EXIT PROGRAM
                ELSE
                    GO TO PANTALLA-FILTRO
                END-IF.

            IF DIA-DESDE = 0 AND MES-DESDE = 0 AND ANO-DESDE = 0 THEN
                MOVE 00000000 TO FECHA-MIN
            ELSE
                IF DIA-DESDE < 1 OR DIA-DESDE > 31 OR
                   MES-DESDE < 1 OR MES-DESDE > 12 THEN
                    DISPLAY(19, 20) "Fecha inicial no valida!             "
                        WITH FOREGROUND-COLOR IS WHITE
                             BACKGROUND-COLOR IS RED
                    GO TO PANTALLA-FILTRO
                END-IF
                COMPUTE FECHA-MIN = (ANO-DESDE * 10000)
                                    + (MES-DESDE * 100)
                                    + DIA-DESDE
            END-IF.

            IF DIA-HASTA = 0 AND MES-HASTA = 0 AND ANO-HASTA = 0 THEN
                MOVE 99999999 TO FECHA-MAX
            ELSE
                IF DIA-HASTA < 1 OR DIA-HASTA > 31 OR
                   MES-HASTA < 1 OR MES-HASTA > 12 THEN
                    DISPLAY(19, 20) "Fecha final no valida!               "
                        WITH FOREGROUND-COLOR IS WHITE
                             BACKGROUND-COLOR IS RED
                    GO TO PANTALLA-FILTRO
                END-IF
                COMPUTE FECHA-MAX = (ANO-HASTA * 10000)
                                    + (MES-HASTA * 100)
                                    + DIA-HASTA
            END-IF.

            IF FECHA-MIN > FECHA-MAX THEN
                DISPLAY(19, 20) "La fecha desde no puede superar hasta! "
                    WITH FOREGROUND-COLOR IS WHITE
                         BACKGROUND-COLOR IS RED
                GO TO PANTALLA-FILTRO
            END-IF.

        CARGAR-TRANSFERENCIAS.
            OPEN INPUT F-TRANSFERENCIAS.
            IF FSTF NOT = 00 THEN
                GO TO PSYS-ERR
            END-IF.

            INITIALIZE TABLA-TRANSFERENCIAS.
            MOVE 0 TO TOTAL-ENCONTRADAS.

        LEER-BUCLE.
            READ F-TRANSFERENCIAS NEXT RECORD
                AT END GO TO FIN-LECTURA.

            IF TRF-CTA-ORIGEN NOT = TNUM THEN
                GO TO LEER-BUCLE
            END-IF.

            MOVE 0 TO ES-VALIDA.

            IF TRF-TIPO = 'P' THEN
                COMPUTE FECHA-REG = (TRF-ANO * 10000)
                                    + (TRF-MES * 100)
                                    + TRF-DIA
                IF FECHA-REG >= FECHA-MIN AND FECHA-REG <= FECHA-MAX THEN
                    MOVE 1 TO ES-VALIDA
                END-IF
            ELSE
                IF TRF-TIPO = 'M' THEN
                    MOVE 1 TO ES-VALIDA
                END-IF
            END-IF.

            IF ES-VALIDA = 1 THEN
                IF TOTAL-ENCONTRADAS < 60 THEN
                    ADD 1 TO TOTAL-ENCONTRADAS
                    MOVE TOTAL-ENCONTRADAS TO INDICE

                    IF TRF-TIPO = 'P' THEN
                        STRING TRF-DIA DELIMITED BY SIZE
                               "-"     DELIMITED BY SIZE
                               TRF-MES DELIMITED BY SIZE
                               "-"     DELIMITED BY SIZE
                               TRF-ANO DELIMITED BY SIZE
                               INTO T-FECHA-TXT(INDICE)
                        END-STRING
                        MOVE "PUNTUAL  " TO T-TIPO-TXT(INDICE)
                        IF FECHA-REG <= FECHA-HOY THEN
                            MOVE "EJECUTADA" TO T-ESTADO-TXT(INDICE)
                        ELSE
                            MOVE "PENDIENTE" TO T-ESTADO-TXT(INDICE)
                        END-IF
                    ELSE
                        STRING "DIA "       DELIMITED BY SIZE
                               TRF-DIA-MES DELIMITED BY SIZE
                               "     "     DELIMITED BY SIZE
                               INTO T-FECHA-TXT(INDICE)
                        END-STRING
                        MOVE "PERIODICA" TO T-TIPO-TXT(INDICE)
                        IF TRF-DIA-MES <= DIA THEN
                            MOVE "EJECUTADA" TO T-ESTADO-TXT(INDICE)
                        ELSE
                            MOVE "PENDIENTE" TO T-ESTADO-TXT(INDICE)
                        END-IF
                    END-IF

                    MOVE TRF-CTA-DESTINO TO T-DESTINO(INDICE)
                    MOVE TRF-IMPORTE-ENT TO T-IMP-ENT(INDICE)
                    MOVE TRF-IMPORTE-DEC TO T-IMP-DEC(INDICE)
                END-IF
            END-IF.

            GO TO LEER-BUCLE.

        FIN-LECTURA.
            CLOSE F-TRANSFERENCIAS.

            IF TOTAL-ENCONTRADAS = 0 THEN
                GO TO MOSTRAR-VACIO
            END-IF.

            COMPUTE TOTAL-PAGINAS = ((TOTAL-ENCONTRADAS - 1) / 10) + 1.
            MOVE 1 TO PAGINA-ACTUAL.

        MOSTRAR-TABLA.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(6, 26) "LISTADO DE TRANSFERENCIAS"
                WITH FOREGROUND-COLOR IS YELLOW.

            DISPLAY(7, 2)
              "FECHA/DIA   TIPO       CUENTA DESTINO     IMPORTE (EUR)  ESTADO"
                WITH FOREGROUND-COLOR IS CYAN.
            DISPLAY(8, 2)
              "----------  ---------  -----------------  -------------  ---------"
                WITH FOREGROUND-COLOR IS CYAN.

            COMPUTE REG-INICIO-PAG = ((PAGINA-ACTUAL - 1) * 10) + 1.
            COMPUTE REG-FIN-PAG = REG-INICIO-PAG + 9.
            IF REG-FIN-PAG > TOTAL-ENCONTRADAS THEN
                MOVE TOTAL-ENCONTRADAS TO REG-FIN-PAG
            END-IF.

            MOVE 9 TO LINEA-PANTALLA.
            PERFORM VARYING I FROM REG-INICIO-PAG BY 1
                    UNTIL I > REG-FIN-PAG
                DISPLAY(LINEA-PANTALLA, 2) T-FECHA-TXT(I)
                DISPLAY(LINEA-PANTALLA, 14) T-TIPO-TXT(I)
                DISPLAY(LINEA-PANTALLA, 25) T-DESTINO(I)
                DISPLAY(LINEA-PANTALLA, 44) T-IMP-ENT(I)
                DISPLAY(LINEA-PANTALLA, 51) ","
                DISPLAY(LINEA-PANTALLA, 52) T-IMP-DEC(I)
                DISPLAY(LINEA-PANTALLA, 55) "EUR"
                IF T-ESTADO-TXT(I) = "EJECUTADA" THEN
                    DISPLAY(LINEA-PANTALLA, 61) T-ESTADO-TXT(I)
                        WITH FOREGROUND-COLOR IS GREEN
                ELSE
                    DISPLAY(LINEA-PANTALLA, 61) T-ESTADO-TXT(I)
                        WITH FOREGROUND-COLOR IS YELLOW
                END-IF
                ADD 1 TO LINEA-PANTALLA
            END-PERFORM.

            DISPLAY(20, 2) "Pagina "
            DISPLAY(20, 9) PAGINA-ACTUAL
            DISPLAY(20, 11) " de "
            DISPLAY(20, 15) TOTAL-PAGINAS
            DISPLAY(20, 20) "(Total registros: "
            DISPLAY(20, 38) TOTAL-ENCONTRADAS
            DISPLAY(20, 41) ")"

            IF TOTAL-PAGINAS > 1 THEN
                DISPLAY(24, 2) "Enter - Siguiente Pagina"
                DISPLAY(24, 66) "ESC - Salir"
            ELSE
                DISPLAY(24, 2) "Enter - Volver"
                DISPLAY(24, 66) "ESC - Salir"
            END-IF.

        ESPERA-TECLA-TABLA.
            ACCEPT PRESSED-KEY LINE 24 COL 80 ON EXCEPTION
                IF ESC-PRESSED THEN
                    EXIT PROGRAM
                ELSE
                    IF ENTER-PRESSED THEN
                        IF PAGINA-ACTUAL < TOTAL-PAGINAS THEN
                            ADD 1 TO PAGINA-ACTUAL
                            GO TO MOSTRAR-TABLA
                        ELSE
                            EXIT PROGRAM
                        END-IF
                    ELSE
                        GO TO ESPERA-TECLA-TABLA
                    END-IF
                END-IF.

            IF ENTER-PRESSED THEN
                IF PAGINA-ACTUAL < TOTAL-PAGINAS THEN
                    ADD 1 TO PAGINA-ACTUAL
                    GO TO MOSTRAR-TABLA
                ELSE
                    EXIT PROGRAM
                END-IF
            ELSE
                GO TO ESPERA-TECLA-TABLA
            END-IF.

        MOSTRAR-VACIO.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(8, 28) "Listado de transferencias".
            DISPLAY(11, 16) "No existen transferencias en el intervalo indicado."
                WITH FOREGROUND-COLOR IS YELLOW.
            DISPLAY(24, 33) "Enter - Salir".

        ESPERA-VACIO.
            ACCEPT PRESSED-KEY LINE 24 COL 80 ON EXCEPTION
                IF ESC-PRESSED THEN
                    EXIT PROGRAM
                ELSE
                    GO TO ESPERA-VACIO
                END-IF.
            IF ENTER-PRESSED THEN
                EXIT PROGRAM
            ELSE
                GO TO ESPERA-VACIO
            END-IF.

        PSYS-ERR.
            CLOSE F-TRANSFERENCIAS.
            PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.
            DISPLAY(09, 25) "Ha ocurrido un error interno"
                WITH FOREGROUND-COLOR IS WHITE
                     BACKGROUND-COLOR IS RED.
            DISPLAY(11, 32) "Vuelva mas tarde"
                WITH FOREGROUND-COLOR IS WHITE
                     BACKGROUND-COLOR IS RED.
            DISPLAY(24, 33) "Enter - Aceptar".

        ESPERA-ERR.
            ACCEPT PRESSED-KEY LINE 24 COL 80.
            IF ENTER-PRESSED THEN
                EXIT PROGRAM
            ELSE
                GO TO ESPERA-ERR
            END-IF.
