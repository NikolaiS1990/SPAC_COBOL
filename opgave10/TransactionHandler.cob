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
       01 WS-EOF-FLAG          PIC X.
       01 WS-OVERFLOW-FLAG     PIC X.
      *> LOW-VALUES never equals a real line, so the first line
      *> is never treated as a duplicate.
       01 WS-PREV-LINE         PIC X(250).
       01 WS-UNIQUE-COUNT      PIC 9(7).
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

      *> Fields of one transaction. Wider than the column widths,
      *> because each character can take up to 2 bytes.
       01 WS-CPR               PIC X(30).
       01 WS-NAVN              PIC X(60).
       01 WS-ADRESSE           PIC X(100).
       01 WS-FØDSELSDATO       PIC X(20).
       01 WS-KONTO-ID          PIC X(30).
       01 WS-REG-NR            PIC X(8).
       01 WS-BELØB             PIC X(34).
       01 WS-VALUTA            PIC X(6).
       01 WS-TRANSAKTIONSTYPE  PIC X(42).
       01 WS-BUTIK             PIC X(40).
       01 WS-TIDSPUNKT         PIC X(52).

       LINKAGE SECTION.
      *> The full Transaktioner.txt gives about 19 MB of JSON.
      *> The caller must declare the same size.
       01 LK-JSON-OUT          PIC X(25000000).
       01 LK-JSON-LEN          PIC 9(8).

       PROCEDURE DIVISION USING LK-JSON-OUT LK-JSON-LEN.
       MAIN-LOGIC.
      *> Reset everything, so the program also works when it is
      *> called more than once.
           MOVE LOW-VALUES TO WS-PREV-LINE
           MOVE 0 TO WS-UNIQUE-COUNT
           MOVE "N" TO WS-OVERFLOW-FLAG
           MOVE 1 TO WS-PTR
           MOVE 0 TO LK-JSON-LEN

           STRING
               '{' X'0A'
               '  "transaktioner": [' X'0A'
               DELIMITED BY SIZE
               INTO LK-JSON-OUT
               POINTER WS-PTR
           END-STRING

      *> Sorting on the whole line puts identical lines next to each
      *> other, wherever they were in the file. Then a duplicate is
      *> simply a line that equals the line before it.
           SORT SORT-FILE ON ASCENDING KEY SORT-LINE
               INPUT PROCEDURE IS READ-TRANSACTIONS
               OUTPUT PROCEDURE IS REMOVE-DUPLICATES

           STRING
               X'0A'
               '  ]' X'0A'
               '}'
               DELIMITED BY SIZE
               INTO LK-JSON-OUT
               POINTER WS-PTR
               ON OVERFLOW
                   MOVE "Y" TO WS-OVERFLOW-FLAG
           END-STRING

           IF WS-OVERFLOW-FLAG = "Y"
               DISPLAY "TRANSACTION-HANDLER: JSON is larger than "
                   "LK-JSON-OUT, no JSON returned"
               MOVE 0 TO LK-JSON-LEN
           ELSE
               COMPUTE LK-JSON-LEN = WS-PTR - 1
           END-IF

           GOBACK.

      *> Read every non-blank line and hand it to the sort.
       READ-TRANSACTIONS.
           OPEN INPUT TRANSACTION-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "TRANSACTION-HANDLER: cannot open transaction "
                   "file, status " WS-FILE-STATUS
               EXIT PARAGRAPH
           END-IF

           MOVE "N" TO WS-EOF-FLAG
           PERFORM UNTIL WS-EOF-FLAG = "Y"
               READ TRANSACTION-FILE
                   AT END
                       MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       IF TRANSACTION-LINE NOT = SPACES
                           RELEASE SORT-LINE FROM TRANSACTION-LINE
                       END-IF
               END-READ
           END-PERFORM

           CLOSE TRANSACTION-FILE.

      *> Receive the lines in sorted order, keep only the first copy
      *> of each and add it to the JSON.
       REMOVE-DUPLICATES.
           MOVE "N" TO WS-EOF-FLAG
           PERFORM UNTIL WS-EOF-FLAG = "Y"
               RETURN SORT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       IF SORT-LINE NOT = WS-PREV-LINE
                           ADD 1 TO WS-UNIQUE-COUNT
                           PERFORM SPLIT-LINE
                           PERFORM ADD-JSON-OBJECT
                           MOVE SORT-LINE TO WS-PREV-LINE
                       END-IF
               END-RETURN
           END-PERFORM.

      *> Find where each character starts. A byte from X"80" to X"BF"
      *> continues the character before it instead of starting one.
       SPLIT-LINE.
           MOVE 0 TO WS-CHAR-COUNT
           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1
                   UNTIL WS-BYTE-IDX > 250
               IF SORT-LINE(WS-BYTE-IDX:1) < X"80"
                  OR SORT-LINE(WS-BYTE-IDX:1) > X"BF"
                   ADD 1 TO WS-CHAR-COUNT
                   MOVE WS-BYTE-IDX TO WS-CHAR-START(WS-CHAR-COUNT)
               END-IF
           END-PERFORM
           MOVE 251 TO WS-CHAR-START(WS-CHAR-COUNT + 1)

      *> Character columns, verified on all lines in Transaktioner.txt
           MOVE   1 TO WS-COL  MOVE 15 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-CPR
           MOVE  16 TO WS-COL  MOVE 30 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-NAVN
           MOVE  46 TO WS-COL  MOVE 50 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-ADRESSE
           MOVE  96 TO WS-COL  MOVE 10 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-FØDSELSDATO
           MOVE 106 TO WS-COL  MOVE 15 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-KONTO-ID
           MOVE 121 TO WS-COL  MOVE  4 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-REG-NR
           MOVE 125 TO WS-COL  MOVE 17 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-BELØB
           MOVE 142 TO WS-COL  MOVE  3 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-VALUTA
           MOVE 145 TO WS-COL  MOVE 21 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-TRANSAKTIONSTYPE
           MOVE 166 TO WS-COL  MOVE 20 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-BUTIK
           MOVE 186 TO WS-COL  MOVE 26 TO WS-WIDTH
           PERFORM GET-FIELD   MOVE WS-FIELD TO WS-TIDSPUNKT.

      *> Copy WS-WIDTH characters starting at character WS-COL.
       GET-FIELD.
           MOVE WS-CHAR-START(WS-COL) TO WS-FROM-BYTE
           COMPUTE WS-BYTE-LEN =
               WS-CHAR-START(WS-COL + WS-WIDTH) - WS-FROM-BYTE
           MOVE SPACES TO WS-FIELD
           MOVE SORT-LINE(WS-FROM-BYTE:WS-BYTE-LEN) TO WS-FIELD.

      *> Add one transaction. Every object after the first is
      *> preceded by a comma, so the last one never gets a comma.
       ADD-JSON-OBJECT.
           IF WS-UNIQUE-COUNT > 1
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
               '    {' X'0A'
               '      "cpr": "' FUNCTION TRIM(WS-CPR) '",' X'0A'
               '      "navn": "' FUNCTION TRIM(WS-NAVN) '",' X'0A'
               '      "adresse": "' FUNCTION TRIM(WS-ADRESSE) '",'
               X'0A'
               '      "fødselsdato": "' FUNCTION TRIM(WS-FØDSELSDATO)
               '",' X'0A'
               '      "konto_id": "' FUNCTION TRIM(WS-KONTO-ID) '",'
               X'0A'
               '      "reg_nr": "' FUNCTION TRIM(WS-REG-NR) '",' X'0A'
               '      "beløb": ' FUNCTION TRIM(WS-BELØB) ',' X'0A'
               '      "valuta": "' FUNCTION TRIM(WS-VALUTA) '",' X'0A'
               '      "transaktionstype": "'
               FUNCTION TRIM(WS-TRANSAKTIONSTYPE) '",' X'0A'
               '      "butik": "' FUNCTION TRIM(WS-BUTIK) '",' X'0A'
               '      "tidspunkt": "' FUNCTION TRIM(WS-TIDSPUNKT) '"'
               X'0A'
               '    }'
               DELIMITED BY SIZE
               INTO LK-JSON-OUT
               POINTER WS-PTR
               ON OVERFLOW
                   MOVE "Y" TO WS-OVERFLOW-FLAG
           END-STRING.
