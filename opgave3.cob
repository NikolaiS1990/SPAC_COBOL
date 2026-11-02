       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Allocate SPACE FOR variables IN MEMORY.

           01 WS-FULDE-NAVN PIC X(40) VALUE SPACES.
           01 WS-KUNDE-ID PIC X(10) VALUE SPACES.

           01 WS-FORNAVN PIC X(20) VALUE SPACES.

           01 WS-EFTERNAVN PIC X(20) VALUE SPACES.
           01 WS-KONTONUMMER PIC X(20) VALUE SPACES.
           01 WS-BALANCE PIC 9(7)V99 VALUE ZEROS.
           01 WS-VALUTAKODE PIC X(3) VALUE SPACES.

      * Variables for looping.
           01 WS-IX1 PIC 9(5) VALUE ZEROS.
           01 WS-IX2 PIC 9(5) VALUE ZEROS.
           01 WS-NUVÆRRENDE-TEGN PIC X(1) VALUE SPACE.
           01 WS-FØRHENVÆRENDE-TEGN PIC X(1) VALUE SPACE.
           01 WS-RENSET-NAVN PIC X(20) VALUE SPACE.

       PROCEDURE DIVISION.

      * Overwrite variables
           MOVE "1234567890" TO WS-KUNDE-ID.
           MOVE "Lars" TO WS-FORNAVN.
           MOVE "Hansen" TO WS-EFTERNAVN.
           MOVE "DK12345678912345" TO WS-KONTONUMMER.
           MOVE 2500.75 TO WS-BALANCE.
           MOVE "DKK" TO WS-VALUTAKODE.
           MOVE 1 TO WS-IX1.
           MOVE 1 TO WS-IX2.

      * move WS-FORNAVN + space + WS-EFTERNAVN into
      * WS-FULDE-NAVN.
      
           STRING
               WS-FORNAVN DELIMITED BY SIZE
               " " DELIMITED BY SIZE
               WS-EFTERNAVN DELIMITED BY SIZE
               INTO WS-FULDE-NAVN.

           PERFORM VARYING WS-IX1 FROM 1 BY 1 UNTIL WS-IX1 > LENGTH OF
           WS-FULDE-NAVN
                  MOVE WS-FULDE-NAVN(WS-IX1:1) TO WS-NUVÆRRENDE-TEGN
              
                  IF WS-NUVÆRRENDE-TEGN NOT = SPACE OR
                  WS-FØRHENVÆRENDE-TEGN NOT = SPACE
      *               One have TO tell COBOL which INDEX it has to 
      *               overwrite with the relevant characters.
                      MOVE WS-NUVÆRRENDE-TEGN TO
                      WS-RENSET-NAVN(WS-IX2:1)

                      ADD 1 TO WS-IX2
                  END-IF
              
                  MOVE WS-NUVÆRRENDE-TEGN TO WS-FØRHENVÆRENDE-TEGN
              
           END-PERFORM.

      * Prints variables
           DISPLAY "----------------------------------------"
           DISPLAY "Kunde ID: " WS-KUNDE-ID.
           DISPLAY "Navn (renset): " WS-RENSET-NAVN.
           DISPLAY "Kontonummer: " WS-KONTONUMMER.
           DISPLAY "Balance: " WS-BALANCE.
           DISPLAY "Valutakode: " WS-VALUTAKODE.
           DISPLAY "----------------------------------------"

           STOP RUN.
