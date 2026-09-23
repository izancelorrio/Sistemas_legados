       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACTUALIZAR-ESPECTACULO.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-ESPECTACULOS ASSIGN TO DISK
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS ESP-NUM
           FILE STATUS IS FSE.

       DATA DIVISION.
       FILE SECTION.

       FD F-ESPECTACULOS
           LABEL RECORD STANDARD
           VALUE OF FILE-ID IS "espectaculos.ubd".

       01 ESPECTACULO-REG.
           02 ESP-NUM               PIC 9(4).
           02 ESP-ANO               PIC 9(4).
           02 ESP-MES               PIC 9(2).
           02 ESP-DIA               PIC 9(2).
           02 ESP-HOR               PIC 9(2).
           02 ESP-MIN               PIC 9(2).
           02 ESP-DESCR             PIC X(40).
           02 ESP-DISP              PIC 9(7).
           02 ESP-PRECIO-ENT        PIC 9(4).
           02 ESP-PRECIO-DEC        PIC 9(2).

       WORKING-STORAGE SECTION.
       77 FSE                       PIC X(2).

       PROCEDURE DIVISION.

       INICIO.
           OPEN I-O F-ESPECTACULOS.

           IF FSE NOT = "00"
               DISPLAY "Error abriendo espectaculos.ubd. STATUS: " FSE
               STOP RUN
           END-IF.

           MOVE 0 TO ESP-NUM.

           START F-ESPECTACULOS
               KEY IS GREATER THAN ESP-NUM
               INVALID KEY
                   DISPLAY "No hay espectaculos en el fichero."
                   CLOSE F-ESPECTACULOS
                   STOP RUN
           END-START.

           READ F-ESPECTACULOS NEXT RECORD
               AT END
                   DISPLAY "No hay espectaculos en el fichero."
                   CLOSE F-ESPECTACULOS
                   STOP RUN
           END-READ.

           DISPLAY "Espectaculo encontrado:"
           DISPLAY "Numero:      " ESP-NUM
           DISPLAY "Descripcion: " ESP-DESCR
           DISPLAY "Fecha vieja: " ESP-DIA "/" ESP-MES "/" ESP-ANO.

           MOVE 2027 TO ESP-ANO.
           MOVE 12   TO ESP-MES.
           MOVE 31   TO ESP-DIA.

           REWRITE ESPECTACULO-REG
               INVALID KEY
                   DISPLAY "Error actualizando el espectaculo."
                   CLOSE F-ESPECTACULOS
                   STOP RUN
           END-REWRITE.

           DISPLAY "Nueva fecha: " ESP-DIA "/" ESP-MES "/" ESP-ANO.
           DISPLAY "Espectaculo actualizado correctamente.".

           CLOSE F-ESPECTACULOS.

           STOP RUN.
           