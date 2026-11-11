       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-HANDLER.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BANK-FILE ASSIGN TO "Banker.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD BANK-FILE.
       01 BANK-RECORD.
           COPY "banker-strukt.cpy".

       WORKING-STORAGE SECTION.
       01 EOF-FLAG             PIC X VALUE "N".
       01 NUMBER-OF-LINES      PIC 9(3) VALUE 0.
       01 TABLE-INDEX          PIC 9(3) VALUE 0.
       01 UNIQUE-COUNT         PIC 9(3) VALUE 0.
       01 PREV-REG-NR          PIC 9(4) VALUE 9999.

       *> In-memory table matching copybook layout exactly
       01 BANK-TABLE.
           05 BANK-ENTRY OCCURS 1 TO 999 TIMES
               DEPENDING ON NUMBER-OF-LINES
               ASCENDING KEY IS TB-REG-NR.
               10 TB-REG-NR     PIC 9(4).
               10 TB-BANKNAVN   PIC X(30).
               10 TB-BANKADRESSE PIC X(50).
               10 TB-TELEFON    PIC X(15).
               10 TB-EMAIL      PIC X(33).

       01 UNIQUE-TABLE.
           05 UNIQUE-ENTRY OCCURS 1 TO 999 TIMES
               DEPENDING ON UNIQUE-COUNT.
               10 UNQ-REG-NR     PIC 9(4).
               10 UNQ-BANKNAVN   PIC X(30).
               10 UNQ-BANKADRESSE PIC X(50).
               10 UNQ-TELEFON    PIC X(15).
               10 UNQ-EMAIL      PIC X(33).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
      *> 1. Count lines to size the table
           OPEN INPUT BANK-FILE.
           PERFORM UNTIL EOF-FLAG = "Y"
               READ BANK-FILE
               AT END 
                   MOVE "Y" TO EOF-FLAG
               NOT AT END
                   IF BANK-RECORD NOT = SPACES
                       ADD 1 TO NUMBER-OF-LINES
               END-READ
           END-PERFORM.
           CLOSE BANK-FILE.
           
      *> 2. Load records directly into the table variable
           OPEN INPUT BANK-FILE.
           MOVE "N" TO EOF-FLAG
           MOVE 0 TO TABLE-INDEX

           PERFORM UNTIL EOF-FLAG = "Y"
               READ BANK-FILE INTO BANK-RECORD
                   AT END 
                       MOVE "Y" TO EOF-FLAG
                   NOT AT END
                       ADD 1 TO TABLE-INDEX
                       MOVE BANK-RECORD TO BANK-ENTRY(TABLE-INDEX)
               END-READ
           END-PERFORM.
           CLOSE BANK-FILE.

           SORT BANK-ENTRY ON ASCENDING KEY TB-REG-NR.

      *> Remove potential duplicates
           MOVE 0 TO UNIQUE-COUNT
           PERFORM VARYING TABLE-INDEX FROM 1 BY 1 
                   UNTIL TABLE-INDEX > NUMBER-OF-LINES
               IF TB-REG-NR(TABLE-INDEX) NOT = PREV-REG-NR
                   ADD 1 TO UNIQUE-COUNT
                   MOVE BANK-ENTRY(TABLE-INDEX) TO
                       UNIQUE-ENTRY(UNIQUE-COUNT)
                   MOVE TB-REG-NR(TABLE-INDEX) TO PREV-REG-NR
               END-IF
           END-PERFORM.

      *> Display clean unique records natively without any pipes
           PERFORM VARYING TABLE-INDEX FROM 1 BY 1 
                   UNTIL TABLE-INDEX > UNIQUE-COUNT
               DISPLAY UNIQUE-ENTRY(TABLE-INDEX)
           END-PERFORM.

           STOP RUN.
