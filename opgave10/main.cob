       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAIN.
      *> For both the bank file and the transaction file:
      *> read the file into a table, remove duplicate lines with
      *> REMOVE-DUPLICATES and get the result as JSON from the
      *> matching handler.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *> The file name is taken from WS-INPUT-FILE-NAME when the file
      *> is opened, so the same file definition reads both files.
           SELECT INPUT-FILE ASSIGN TO WS-INPUT-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD INPUT-FILE.
       01 INPUT-LINE               PIC X(250).

       WORKING-STORAGE SECTION.
       01 WS-BANK-FILE-NAME        PIC X(256) VALUE "Banker.txt".
       01 WS-TRANSACTION-FILE-NAME PIC X(256)
                                   VALUE "Trans_sml_samp.txt".
       01 WS-INPUT-FILE-NAME       PIC X(256).
       01 WS-FILE-STATUS           PIC XX.
       01 WS-EOF-FLAG              PIC X.

      *> One table, reused for each file in turn.
       01 LINE-COUNT               PIC 9(8) VALUE 0.
       01 LINE-TABLE.
           COPY "linje-tabel.cpy".

      *> Must have the same sizes as the LINKAGE SECTION
      *> in BankHandler.cob and TransactionHandler.cob.
       01 WS-BANK-JSON             PIC X(100000).
       01 WS-BANK-JSON-LEN         PIC 9(8).
       01 WS-TRANSACTION-JSON      PIC X(25000000).
       01 WS-TRANSACTION-JSON-LEN  PIC 9(8).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
      *> Banks
           MOVE WS-BANK-FILE-NAME TO WS-INPUT-FILE-NAME
           PERFORM READ-INPUT-FILE

           CALL "REMOVE-DUPLICATES"
               USING LINE-COUNT LINE-TABLE
           END-CALL

           CALL "BANK-HANDLER"
               USING LINE-COUNT LINE-TABLE
                     WS-BANK-JSON WS-BANK-JSON-LEN
           END-CALL

           IF WS-BANK-JSON-LEN > 0
               DISPLAY WS-BANK-JSON(1:WS-BANK-JSON-LEN)
           ELSE
               DISPLAY "No bank JSON was returned"
           END-IF

      *> Transactions
           MOVE WS-TRANSACTION-FILE-NAME TO WS-INPUT-FILE-NAME
           PERFORM READ-INPUT-FILE

           CALL "REMOVE-DUPLICATES"
               USING LINE-COUNT LINE-TABLE
           END-CALL

           CALL "TRANSACTION-HANDLER"
               USING LINE-COUNT LINE-TABLE
                     WS-TRANSACTION-JSON WS-TRANSACTION-JSON-LEN
           END-CALL

           IF WS-TRANSACTION-JSON-LEN > 0
               DISPLAY WS-TRANSACTION-JSON(1:WS-TRANSACTION-JSON-LEN)
           ELSE
               DISPLAY "No transaction JSON was returned"
           END-IF

           STOP RUN.

      *> Read every non-blank line of WS-INPUT-FILE-NAME into
      *> LINE-TABLE, replacing what was there before.
       READ-INPUT-FILE.
           MOVE 0 TO LINE-COUNT
           MOVE "N" TO WS-EOF-FLAG

           OPEN INPUT INPUT-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "MAIN: cannot open "
                   FUNCTION TRIM(WS-INPUT-FILE-NAME)
                   ", status " WS-FILE-STATUS
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF-FLAG = "Y"
               READ INPUT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       IF INPUT-LINE NOT = SPACES
                           IF LINE-COUNT = 60000
                               DISPLAY "MAIN: more than 60000 lines in "
                                   FUNCTION TRIM(WS-INPUT-FILE-NAME)
                               CLOSE INPUT-FILE
                               STOP RUN
                           END-IF
                           ADD 1 TO LINE-COUNT
                           MOVE INPUT-LINE TO LINE-TEXT(LINE-COUNT)
                       END-IF
               END-READ
           END-PERFORM

           CLOSE INPUT-FILE.
