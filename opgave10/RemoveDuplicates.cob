       IDENTIFICATION DIVISION.
       PROGRAM-ID. REMOVE-DUPLICATES.
      *> Sorts a table of lines and removes duplicates in place.
      *> A line only counts as a duplicate if it matches another line
      *> completely, wherever in the table that other line is.
      *> After the call, LINE-COUNT is the number of distinct lines,
      *> and they are the first LINE-COUNT entries in sorted order.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-READ-IDX          PIC 9(8).
       01 WS-KEPT-COUNT        PIC 9(8).

       LINKAGE SECTION.
       01 LINE-COUNT           PIC 9(8).
       01 LINE-TABLE.
           COPY "linje-tabel.cpy".

       PROCEDURE DIVISION USING LINE-COUNT LINE-TABLE.
       MAIN-LOGIC.
           IF LINE-COUNT < 2
               GOBACK
           END-IF

      *> Sorting on the whole line puts identical lines next to each
      *> other, wherever they were in the table.
           SORT LINE-ENTRY ON ASCENDING KEY LINE-TEXT

      *> Then a duplicate is simply a line that equals the last line
      *> kept. Kept lines are moved up to close the gaps.
           MOVE 1 TO WS-KEPT-COUNT
           PERFORM VARYING WS-READ-IDX FROM 2 BY 1
                   UNTIL WS-READ-IDX > LINE-COUNT
               IF LINE-TEXT(WS-READ-IDX)
                       NOT = LINE-TEXT(WS-KEPT-COUNT)
                   ADD 1 TO WS-KEPT-COUNT
                   MOVE LINE-TEXT(WS-READ-IDX)
                       TO LINE-TEXT(WS-KEPT-COUNT)
               END-IF
           END-PERFORM

           MOVE WS-KEPT-COUNT TO LINE-COUNT
           GOBACK.
