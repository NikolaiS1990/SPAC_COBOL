       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRANSACTION-HANDLER.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE ASSIGN TO "Trans_sml_samp.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT SORT-FILE ASSIGN TO "sortwork".

       DATA DIVISION.
       FILE SECTION.
      *> Each line is read as one whole field, so duplicates are found
      *> by comparing complete lines. 250 is wider than the longest
      *> line in Transaktioner.txt (216 bytes); shorter lines are
      *> padded with spaces.
       FD TRANSACTION-FILE.
       01 TRANSACTION-LINE     PIC X(250).

       SD SORT-FILE.
       01 SORT-LINE            PIC X(250).

       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS       PIC XX.
       01 WS-EOF-FLAG          PIC X VALUE "N".
      *> LOW-VALUES never equals a real line, so the first line
      *> is never treated as a duplicate.
       01 WS-PREV-LINE         PIC X(250) VALUE LOW-VALUES.
       01 WS-LINES-READ        PIC 9(7) VALUE 0.
       01 WS-UNIQUE-COUNT      PIC 9(7) VALUE 0.
       01 WS-DUPLICATE-COUNT   PIC 9(7) VALUE 0.

      *> Working fields for trimming in the JSON construction
       01 WS-CPR PIC X(16).
       01 WS-NAVN PIC X(31).
       01 WS-ADRESSE PIC X(51).
       01 WS-FØDSELSDATO PIC X(12).
       01 WS-KONTO-ID PIC X(15).
       01 WS-REG-NR PIC 9(13).
       01 WS-BELØB PIC 9(01)V99.
       01 WS-VALUTA PIC 9(3).
       01 WS-TRANSAKTIONSTYPE PIC X(21).
       01 WS-BUTIK PIC X(21).
       01 WS-TIDSPUNKT PIC X(27).

      *> LINKAGE SECTION.
      *>01 LK-JSON-OUT          PIC X(17979).
      *>01 LK-JSON-LEN          PIC 9(5).

      *>PROCEDURE DIVISION USING LK-JSON-OUT LK-JSON-LEN.
       PROCEDURE DIVISION.
       MAIN-LOGIC.
      *> Sorting on the whole line puts identical lines next to each
      *> other, wherever they were in the file. Then a duplicate is
      *> simply a line that equals the line before it.
           SORT SORT-FILE ON ASCENDING KEY SORT-LINE
               INPUT PROCEDURE IS READ-TRANSACTIONS
               OUTPUT PROCEDURE IS REMOVE-DUPLICATES

           DISPLAY SPACES
           DISPLAY "Lines read:         " WS-LINES-READ
           DISPLAY "Unique lines:       " WS-UNIQUE-COUNT
           DISPLAY "Duplicates removed: " WS-DUPLICATE-COUNT

           STOP RUN.

      *> Read every non-blank line and hand it to the sort.
       READ-TRANSACTIONS.
           OPEN INPUT TRANSACTION-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "Cannot open transaction file, status "
                   WS-FILE-STATUS
               STOP RUN
           END-IF

           MOVE "N" TO WS-EOF-FLAG
           PERFORM UNTIL WS-EOF-FLAG = "Y"
               READ TRANSACTION-FILE
                   AT END
                       MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       IF TRANSACTION-LINE NOT = SPACES
                           ADD 1 TO WS-LINES-READ
                           RELEASE SORT-LINE FROM TRANSACTION-LINE
                       END-IF
               END-READ
           END-PERFORM

           CLOSE TRANSACTION-FILE.

      *> Receive the lines in sorted order and keep only the first
      *> copy of each.
       REMOVE-DUPLICATES.
           MOVE "N" TO WS-EOF-FLAG
           PERFORM UNTIL WS-EOF-FLAG = "Y"
               RETURN SORT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       IF SORT-LINE = WS-PREV-LINE
                           ADD 1 TO WS-DUPLICATE-COUNT
                       ELSE
                           ADD 1 TO WS-UNIQUE-COUNT
                           DISPLAY FUNCTION TRIM(SORT-LINE TRAILING)
                           MOVE SORT-LINE TO WS-PREV-LINE
                       END-IF
               END-RETURN
           END-PERFORM.
