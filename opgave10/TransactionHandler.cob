       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRANSACTION-HANDLER.
      *> Turns a table of transaction lines into JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *> The line currently being turned into JSON.
       01 TRANSACTION-LINE     PIC X(250).
       01 WS-LINE-IDX          PIC 9(8).
       01 WS-OVERFLOW-FLAG     PIC X.
       01 WS-OBJECT-COUNT      PIC 9(8).
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
       01 LINE-COUNT           PIC 9(8).
       01 LINE-TABLE.
           COPY "linje-tabel.cpy".
      *> The full Transaktioner.txt gives about 19 MB of JSON.
      *> The caller must declare the same size.
       01 LK-JSON-OUT          PIC X(25000000).
       01 LK-JSON-LEN          PIC 9(8).

       PROCEDURE DIVISION USING LINE-COUNT LINE-TABLE
                                LK-JSON-OUT LK-JSON-LEN.
       MAIN-LOGIC.
      *> Reset everything, so the program also works when it is
      *> called more than once.
           MOVE 0 TO WS-OBJECT-COUNT
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

           PERFORM VARYING WS-LINE-IDX FROM 1 BY 1
                   UNTIL WS-LINE-IDX > LINE-COUNT
               MOVE LINE-TEXT(WS-LINE-IDX) TO TRANSACTION-LINE
               ADD 1 TO WS-OBJECT-COUNT
               PERFORM SPLIT-LINE
               PERFORM ADD-JSON-OBJECT
           END-PERFORM

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

      *> Find where each character starts. A byte from X"80" to X"BF"
      *> continues the character before it instead of starting one.
       SPLIT-LINE.
           MOVE 0 TO WS-CHAR-COUNT
           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1
                   UNTIL WS-BYTE-IDX > 250
               IF TRANSACTION-LINE(WS-BYTE-IDX:1) < X"80"
                  OR TRANSACTION-LINE(WS-BYTE-IDX:1) > X"BF"
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
           MOVE TRANSACTION-LINE(WS-FROM-BYTE:WS-BYTE-LEN) TO WS-FIELD.

      *> Add one transaction. Every object after the first is
      *> preceded by a comma, so the last one never gets a comma.
       ADD-JSON-OBJECT.
           IF WS-OBJECT-COUNT > 1
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
