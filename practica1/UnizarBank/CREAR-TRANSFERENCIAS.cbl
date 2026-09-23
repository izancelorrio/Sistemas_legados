        IDENTIFICATION DIVISION.
        PROGRAM-ID. CREAR-TRANSFERENCIAS.

        ENVIRONMENT DIVISION.
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
            02 TRF-NUM               PIC 9(16).
            02 TRF-CTA-ORIGEN        PIC 9(16).
            02 TRF-CTA-DESTINO       PIC 9(16).
            02 TRF-NOM-DESTINO       PIC X(35).
            02 TRF-IMPORTE-ENT       PIC 9(7).
            02 TRF-IMPORTE-DEC       PIC 9(2).
            02 TRF-TIPO              PIC X(1).
            02 TRF-FEC-PUNTUAL.
                05 TRF-ANO           PIC 9(4).
                05 TRF-MES           PIC 9(2).
                05 TRF-DIA           PIC 9(2).
            02 TRF-DIA-MES           PIC 9(2).
            02 TRF-ESTADO            PIC X(1).
            02 TRF-FEC-ALTA.
                05 TRF-ALTA-ANO      PIC 9(4).
                05 TRF-ALTA-MES      PIC 9(2).
                05 TRF-ALTA-DIA      PIC 9(2).

        WORKING-STORAGE SECTION.
        77 FSTF                      PIC X(2).

        PROCEDURE DIVISION.
        INICIO.
            OPEN OUTPUT F-TRANSFERENCIAS.

            DISPLAY "FILE STATUS: " FSTF.

            CLOSE F-TRANSFERENCIAS.

            DISPLAY "Fichero transferencias.ubd creado.".

            STOP RUN.
