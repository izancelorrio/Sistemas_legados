       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK8.

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

           SELECT INTENTOS ASSIGN TO DISK
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS INUM
           FILE STATUS IS FSI.

       DATA DIVISION.
       FILE SECTION.

       FD TARJETAS
           LABEL RECORD STANDARD
           VALUE OF FILE-ID IS "tarjetas.ubd".
       01 TARJETAREG.
           02 TNUM-E               PIC 9(16).
           02 TPIN-E               PIC 9(4).

       FD INTENTOS
           LABEL RECORD STANDARD
           VALUE OF FILE-ID IS "intentos.ubd".
       01 INTENTOSREG.
           02 INUM                 PIC 9(16).
           02 IINTENTOS            PIC 9(1).

       WORKING-STORAGE SECTION.
       77 FST                      PIC X(2).
       77 FSI                      PIC X(2).

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
           88 ESC-PRESSED          VALUE 2005.

       77 PIN-ACTUAL               PIC 9(4).
       77 PIN-NUEVO                PIC 9(4).
       77 PIN-REPETIDO             PIC 9(4).
       77 PRESSED-KEY              PIC X(1).

       LINKAGE SECTION.
       77 TNUM                     PIC 9(16).

       SCREEN SECTION.

       01 BLANK-SCREEN.
           05 FILLER LINE 1 BLANK SCREEN
               BACKGROUND-COLOR BLACK.

       01 CAMBIO-PIN.
           05 PIN-ACTUAL-ACCEPT
               BLANK ZERO SECURE
               LINE 8 COL 49
               PIC 9(4) USING PIN-ACTUAL.
           05 PIN-NUEVO-ACCEPT
               BLANK ZERO SECURE
               LINE 9 COL 49
               PIC 9(4) USING PIN-NUEVO.
           05 PIN-REPETIDO-ACCEPT
               BLANK ZERO SECURE
               LINE 10 COL 49
               PIC 9(4) USING PIN-REPETIDO.

       PROCEDURE DIVISION USING TNUM.

       IMPRIMIR-CABECERA.
           SET ENVIRONMENT 'COB_SCREEN_EXCEPTIONS' TO 'Y'.
           SET ENVIRONMENT 'COB_SCREEN_ESC' TO 'Y'.

           DISPLAY BLANK-SCREEN.

           DISPLAY (2, 26) "Cajero Automatico UnizarBank"
               WITH FOREGROUND-COLOR IS CYAN.

           MOVE FUNCTION CURRENT-DATE TO CAMPOS-FECHA.

           DISPLAY (4, 32) DIA.
           DISPLAY (4, 34) "-".
           DISPLAY (4, 35) MES.
           DISPLAY (4, 37) "-".
           DISPLAY (4, 38) ANO.
           DISPLAY (4, 44) HORAS.
           DISPLAY (4, 46) ":".
           DISPLAY (4, 47) MINUTOS.

       INICIO.
           MOVE TNUM TO TNUM-E.
           MOVE TNUM TO INUM.

           OPEN I-O TARJETAS.
           IF FST NOT = 00
               GO TO PSYS-ERR
           END-IF.

           READ TARJETAS
               INVALID KEY GO TO PSYS-ERR
           END-READ.

           OPEN I-O INTENTOS.
           IF FSI NOT = 00
               GO TO PSYS-ERR
           END-IF.

           READ INTENTOS
               INVALID KEY GO TO PSYS-ERR
           END-READ.

           IF IINTENTOS = 0
               GO TO TARJETA-BLOQUEADA
           END-IF.

       PEDIR-CLAVES.
           PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.

           INITIALIZE PIN-ACTUAL.
           INITIALIZE PIN-NUEVO.
           INITIALIZE PIN-REPETIDO.

           DISPLAY (6, 14) "Cambio de clave personal".

           DISPLAY (8, 14) "Introduzca clave actual:".
           DISPLAY (9, 14) "Introduzca nueva clave:".
           DISPLAY (10, 14) "Repita la nueva clave:".

           DISPLAY (24, 2) "Enter - Confirmar".
           DISPLAY (24, 66) "ESC - Cancelar".

           ACCEPT CAMBIO-PIN ON EXCEPTION
               IF ESC-PRESSED
                   CLOSE TARJETAS
                   CLOSE INTENTOS
                   EXIT PROGRAM
               ELSE
                   GO TO PEDIR-CLAVES
               END-IF
           END-ACCEPT.

           IF PIN-ACTUAL NOT = TPIN-E
               GO TO PIN-INCORRECTO
           END-IF.

           IF PIN-NUEVO NOT = PIN-REPETIDO
               GO TO PIN-NO-COINCIDE
           END-IF.

           GO TO CAMBIAR-PIN.

       CAMBIAR-PIN.
           MOVE PIN-NUEVO TO TPIN-E.

           REWRITE TARJETAREG
               INVALID KEY GO TO PSYS-ERR
           END-REWRITE.

           MOVE 3 TO IINTENTOS.

           REWRITE INTENTOSREG
               INVALID KEY GO TO PSYS-ERR
           END-REWRITE.

           CLOSE TARJETAS.
           CLOSE INTENTOS.

           PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.

           DISPLAY (8, 14) "Cambio de clave personal".

           DISPLAY (11, 14)
               "La clave se ha cambiado correctamente".

           DISPLAY (24, 33) "Enter-Aceptar".

           GO TO EXIT-ENTER.

       PIN-NO-COINCIDE.
           PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.

           DISPLAY (8, 14) "Cambio de clave personal".

           DISPLAY (11, 20)
               "Las nuevas claves no coinciden"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (24, 2) "Enter - Reintentar".
           DISPLAY (24, 65) "ESC - Cancelar".

       PIN-NO-COINCIDE-ENTER.
           ACCEPT PRESSED-KEY AT 2480 ON EXCEPTION
               IF ESC-PRESSED
                   CLOSE TARJETAS
                   CLOSE INTENTOS
                   EXIT PROGRAM
               END-IF
           END-ACCEPT.

           IF ENTER-PRESSED
               GO TO PEDIR-CLAVES
           ELSE
               GO TO PIN-NO-COINCIDE-ENTER
           END-IF.

       PIN-INCORRECTO.
           SUBTRACT 1 FROM IINTENTOS.

           REWRITE INTENTOSREG
               INVALID KEY GO TO PSYS-ERR
           END-REWRITE.

           IF IINTENTOS = 0
               GO TO TARJETA-BLOQUEADA
           END-IF.

           PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.

           DISPLAY (8, 14) "Cambio de clave personal".

           DISPLAY (11, 25) "La clave actual es incorrecta"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (13, 27) "Intentos restantes:"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (13, 47) IINTENTOS
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (24, 2) "Enter - Reintentar".
           DISPLAY (24, 65) "ESC - Cancelar".

       PIN-INCORRECTO-ENTER.
           ACCEPT PRESSED-KEY AT 2480 ON EXCEPTION
               IF ESC-PRESSED
                   CLOSE TARJETAS
                   CLOSE INTENTOS
                   EXIT PROGRAM
               END-IF
           END-ACCEPT.

           IF ENTER-PRESSED
               GO TO PEDIR-CLAVES
           ELSE
               GO TO PIN-INCORRECTO-ENTER
           END-IF.

       TARJETA-BLOQUEADA.
           CLOSE TARJETAS.
           CLOSE INTENTOS.

           PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.

           DISPLAY (8, 14) "Cambio de clave personal".

           DISPLAY (11, 20)
               "Se ha sobrepasado el numero de intentos"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (13, 18)
               "Por su seguridad se ha bloqueado la tarjeta"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (14, 30) "Acuda a una sucursal"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (24, 33) "Enter - Aceptar".

           GO TO EXIT-ENTER.

       PSYS-ERR.
           CLOSE TARJETAS.
           CLOSE INTENTOS.

           PERFORM IMPRIMIR-CABECERA THRU IMPRIMIR-CABECERA.

           DISPLAY (9, 25) "Ha ocurrido un error interno"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (11, 32) "Vuelva mas tarde"
               WITH FOREGROUND-COLOR IS WHITE
                    BACKGROUND-COLOR IS RED.

           DISPLAY (24, 33) "Enter - Aceptar".

       EXIT-ENTER.
           ACCEPT PRESSED-KEY AT 2480
           IF ENTER-PRESSED
               EXIT PROGRAM
           ELSE
               GO TO EXIT-ENTER
           END-IF.
           