       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAIN.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *> Must have the same sizes as the LINKAGE SECTION
      *> in TransactionHandler.cob.
       01 WS-TRANSACTION-JSON      PIC X(25000000).
       01 WS-TRANSACTION-JSON-LEN  PIC 9(8).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           CALL "TRANSACTION-HANDLER"
               USING WS-TRANSACTION-JSON WS-TRANSACTION-JSON-LEN
           END-CALL

           IF WS-TRANSACTION-JSON-LEN > 0
               DISPLAY WS-TRANSACTION-JSON(1:WS-TRANSACTION-JSON-LEN)
           ELSE
               DISPLAY "No transaction JSON was returned"
           END-IF

           STOP RUN.
