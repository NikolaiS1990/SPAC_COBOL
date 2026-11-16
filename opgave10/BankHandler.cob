       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-HANDLER.
      *> Turns a table of bank lines into JSON, keyed by reg.nr.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *> The line currently being turned into JSON.
       01 BANK-LINE            PIC X(250).
       01 WS-LINE-IDX          PIC 9(8).
       01 WS-OVERFLOW-FLAG     PIC X.
       01 WS-PTR               PIC 9(8).

      *> The file is UTF-8: letters like ø take 2 bytes, so the
      *> columns are fixed in characters, not in bytes.
      *> WS-CHAR-START(n) is the byte where character n starts.
       01 WS-BYTE-IDX          PIC 9(3).
       01 WS-CHAR-COUNT        PIC 9(3).
       01 WS-CHAR-START-TABLE.
           05 WS-CHAR-START    PIC 9(3) OCCURS 251 TIMES.

      *> Input/output for GET-FIELD: character column and width.
       01 WS-COL               PIC 9(3).
       01 WS-WIDTH             PIC 9(3).
       01 WS-FROM-BYTE         PIC 9(3).
       01 WS-BYTE-LEN          PIC 9(3).
       01 WS-FIELD             PIC X(100).

      *> Fields of one bank. Wider than the column widths,
      *> because each character can take up to 2 bytes.
       01 WS-REG-NR            PIC X(8).
       01 WS-BANKNAVN          PIC X(60).
       01 WS-BANKADRESSE       PIC X(100).
       01 WS-TELEFON           PIC X(30).
       01 WS-EMAIL             PIC X(66).

       LINKAGE SECTION.
       01 LINE-COUNT           PIC 9(8).
       01 LINE-TABLE.
           COPY "linje-tabel.cpy".
      *> Banker.txt (100 banks) gives about 18 KB of JSON.
      *> The caller must declare the same size.
       01 LK-JSON-OUT          PIC X(100000).
       01 LK-JSON-LEN          PIC 9(8).

       PROCEDURE DIVISION USING LINE-COUNT LINE-TABLE
                                LK-JSON-OUT LK-JSON-LEN.
       MAIN-LOGIC.
      *> Reset everything, so the program also works when it is
      *> called more than once.
           MOVE "N" TO WS-OVERFLOW-FLAG
           MOVE 1 TO WS-PTR
           MOVE 0 TO LK-JSON-LEN

           STRING
               '{' X'0A'
               '  "banker": {' X'0A'
               DELIMITED BY SIZE
               INTO LK-JSON-OUT
               POINTER WS-PTR
           END-STRING

           PERFORM VARYING WS-LINE-IDX FROM 1 BY 1
                   UNTIL WS-LINE-IDX > LINE-COUNT
               MOVE LINE-TEXT(WS-LINE-IDX) TO BANK-LINE
               PERFORM SPLIT-LINE
               PERFORM ADD-JSON-OBJECT
           END-PERFORM

           STRING
               X'0A'
               '  }' X'0A'
               '}'
               DELIMITED BY SIZE
               INTO LK-JSON-OUT
               POINTER WS-PTR
               ON OVERFLOW
                   MOVE "Y" TO WS-OVERFLOW-FLAG
           END-STRING

           IF WS-OVERFLOW-FLAG = "Y"
               DISPLAY "BANK-HANDLER: JSON is larger than "
                   "LK-JSON-OUT, no JSON returned"
               MOVE 0 TO LK-JSON-LEN
           ELSE
               COMPUTE LK-JSON-LEN = WS-PTR - 1
           END-IF

           GOBACK.

      *> Find where each character starts. A byte from X"80" to X"BF"
      *> continues the character before it instead of starting one.
       SPLIT-LINE.
           MOVE 0 TO WS-CHAR-COUNT
           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1
                   UNTIL WS-BYTE-IDX > 250
               IF BANK-LINE(WS-BYTE-IDX:1) < X"80"
                  OR BANK-LINE(WS-BYTE-IDX:1) > X"BF"
                   ADD 1 TO WS-CHAR-COUNT
                   MOVE WS-BYTE-IDX TO WS-CHAR-START(WS-CHAR-COUNT)
               END-IF
           END-PERFORM
           MOVE 251 TO WS-CHAR-START(WS-CHAR-COUNT + 1)

      *> Character columns, verified on all lines in Banker.txt
           MOVE   1 TO WS-COL  MOVE  4 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-REG-NR
           MOVE   5 TO WS-COL  MOVE 30 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-BANKNAVN
           MOVE  35 TO WS-COL  MOVE 50 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-BANKADRESSE
           MOVE  85 TO WS-COL  MOVE 15 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-TELEFON
           MOVE 100 TO WS-COL  MOVE 33 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-EMAIL.

      *> Copy WS-WIDTH characters starting at character WS-COL.
       GET-FIELD.
           MOVE WS-CHAR-START(WS-COL) TO WS-FROM-BYTE
           COMPUTE WS-BYTE-LEN =
               WS-CHAR-START(WS-COL + WS-WIDTH) - WS-FROM-BYTE
           MOVE SPACES TO WS-FIELD
           MOVE BANK-LINE(WS-FROM-BYTE:WS-BYTE-LEN) TO WS-FIELD.

      *> Add one bank. Every bank after the first is preceded by a
      *> comma, so the last one never gets a comma.
       ADD-JSON-OBJECT.
           IF WS-LINE-IDX > 1
               STRING
                   ',' X'0A'
                   DELIMITED BY SIZE
                   INTO LK-JSON-OUT
                   POINTER WS-PTR
                   ON OVERFLOW
                       MOVE "Y" TO WS-OVERFLOW-FLAG
               END-STRING
           END-IF

           STRING
               '    "' FUNCTION TRIM(WS-REG-NR) '": {' X'0A'
               '      "banknavn": "' FUNCTION TRIM(WS-BANKNAVN) '",'
               X'0A'
               '      "adresse": "' FUNCTION TRIM(WS-BANKADRESSE) '",'
               X'0A'
               '      "telefon": "' FUNCTION TRIM(WS-TELEFON) '",'
               X'0A'
               '      "email": "' FUNCTION TRIM(WS-EMAIL) '"' X'0A'
               '    }'
               DELIMITED BY SIZE
               INTO LK-JSON-OUT
               POINTER WS-PTR
               ON OVERFLOW
                   MOVE "Y" TO WS-OVERFLOW-FLAG
           END-STRING.
