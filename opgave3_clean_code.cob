       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Allocate space for variables in memory.
           01 WS-KUNDE-ID PIC X(10) VALUE SPACES.
           01 WS-FORNAVN PIC X(20) VALUE SPACES.
           01 WS-FULDE-NAVN PIC X(40) VALUE SPACES.
           01 WS-EFTERNAVN PIC X(20) VALUE SPACES.
           01 WS-KONTONUMMER PIC X(20) VALUE SPACES.
           01 WS-BALANCE PIC 9(7)V99 VALUE ZEROS.
           01 WS-VALUTAKODE PIC X(3) VALUE SPACES.

       PROCEDURE DIVISION.
      * Overwrite variables
           MOVE "1234567890" TO WS-KUNDE-ID.
           MOVE "Lars" TO WS-FORNAVN.
           MOVE "Hansen" TO WS-EFTERNAVN.
           MOVE "DK12345678912345" TO WS-KONTONUMMER.
           MOVE 2500.75 TO WS-BALANCE.
           MOVE "DKK" TO WS-VALUTAKODE.
      
      * USING "DELIMITED BY SPACE" strips out ALL the white SPACE
      * in the variable.
           STRING WS-FORNAVN DELIMITED BY SPACE
               " " DELIMITED BY SIZE
               WS-EFTERNAVN DELIMITED BY SPACE
               INTO WS-FULDE-NAVN.

      * Prints variables
           DISPLAY "----------------------------------------"
           DISPLAY "Kunde ID: " WS-KUNDE-ID.
           DISPLAY "Navn (renset): " WS-FULDE-NAVN.
           DISPLAY "Kontonummer: " WS-KONTONUMMER.
           DISPLAY "Balance: " WS-BALANCE.
           DISPLAY "Valutakode: " WS-VALUTAKODE.
           DISPLAY "----------------------------------------"

           STOP RUN.
