      *> A table of whole text lines, shared by main.cob,
      *> RemoveDuplicates.cob and TransactionHandler.cob.
      *> Each program must define LINE-COUNT PIC 9(8) itself.
      *> 60000 lines is enough for Transaktioner.txt (54752 lines).
      *> 250 is wider than its longest line (216 bytes).
           05 LINE-ENTRY OCCURS 1 TO 60000 TIMES
               DEPENDING ON LINE-COUNT.
               10 LINE-TEXT    PIC X(250).
