       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           01  VAR-TEXT PIC X(30) VALUE "HELLO med Variabel".
       PROCEDURE DIVISION.
      * Displays the VALUE OF VAR-TEXT. This comment serves
      * as an example of where to place comments in COBOL code.
           DISPLAY VAR-TEXT
           STOP RUN.
