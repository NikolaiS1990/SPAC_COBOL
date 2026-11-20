       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEXT-FILE-TO-JSON.
      *> Reads one fixed-width text file, removes duplicate lines with
      *> REMOVE-DUPLICATES and appends the lines as JSON to JSON-BUFFER,
      *> starting at JSON-PTR. Depending on SPEC-KEY-FIELD:
      *>   0: "<json name>": [ { ... }, { ... } ]
      *>   n: "<json name>": { "<field n>": { ... }, ... }
      *> The fields of each line are described in FILE-SPEC.
      *>
      *> The file is UTF-8, where letters like ø take 2 bytes, so the
      *> field columns count characters, not bytes.
      *>
      *> LK-RESULT after the call:
      *>   0 = OK
      *>   1 = the file could not be opened
      *>   2 = the file has more lines than LINE-TABLE can hold
      *>   3 = JSON-BUFFER is full

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO WS-INPUT-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD INPUT-FILE.
       01 INPUT-LINE           PIC X(250).

       WORKING-STORAGE SECTION.
       01 WS-INPUT-FILE-NAME   PIC X(256).
       01 WS-FILE-STATUS       PIC XX.
       01 WS-EOF-FLAG          PIC X.

       01 LINE-COUNT           PIC 9(8).
       01 LINE-TABLE.
           COPY "linje-tabel.cpy".

       01 WS-LINE-IDX          PIC 9(8).
       01 WS-FIELD-IDX         PIC 9(2).
       01 WS-FIRST-FIELD       PIC X.
      *> One byte longer than a line, so position 251 always exists
      *> and is a space.
       01 WS-CURRENT-LINE      PIC X(251).

      *> WS-CHAR-START(n) is the byte where character n starts.
       01 WS-BYTE-IDX          PIC 9(3).
       01 WS-CHAR-COUNT        PIC 9(3).
       01 WS-CHAR-START-TABLE.
           05 WS-CHAR-START    PIC 9(3) OCCURS 251 TIMES.

      *> Used by GET-VALUE. WS-TO-CHAR and WS-TO-BYTE point just
      *> after the field.
       01 WS-FROM-CHAR         PIC 9(4).
       01 WS-TO-CHAR           PIC 9(4).
       01 WS-FROM-BYTE         PIC 9(3).
       01 WS-TO-BYTE           PIC 9(3).
       01 WS-BYTE              PIC X.

      *> The current field's value, trimmed and escaped for JSON.
       01 WS-VALUE             PIC X(501).
       01 WS-VALUE-LEN         PIC 9(3).

      *> Used by CHECK-NUMBER.
       01 WS-IS-NUMBER         PIC X.
       01 WS-POS               PIC 9(3).
       01 WS-DIGITS-FROM       PIC 9(3).

       LINKAGE SECTION.
       01 FILE-SPEC.
           COPY "fil-spec.cpy".
       COPY "json-buffer.cpy".
       01 JSON-PTR             PIC 9(8).
       01 LK-RESULT            PIC 9.

       PROCEDURE DIVISION USING FILE-SPEC JSON-BUFFER
           JSON-PTR LK-RESULT.
       MAIN-LOGIC.
           MOVE 0 TO LK-RESULT
           PERFORM READ-INPUT-FILE
           IF LK-RESULT NOT = 0
               GOBACK
           END-IF

           CALL "REMOVE-DUPLICATES" USING LINE-COUNT LINE-TABLE
           END-CALL

           STRING '  "' FUNCTION TRIM(SPEC-JSON-NAME) '": '
               DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
               ON OVERFLOW MOVE 3 TO LK-RESULT
           END-STRING
           IF SPEC-KEY-FIELD = 0
               STRING '[' X'0A'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           ELSE
               STRING '{' X'0A'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           END-IF

           PERFORM VARYING WS-LINE-IDX FROM 1 BY 1
                   UNTIL WS-LINE-IDX > LINE-COUNT
                      OR LK-RESULT NOT = 0
               PERFORM ADD-LINE
           END-PERFORM

           IF SPEC-KEY-FIELD = 0
               STRING X'0A' '  ]'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           ELSE
               STRING X'0A' '  }'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           END-IF

           GOBACK.

      *> Read every non-blank line of the file into LINE-TABLE.
       READ-INPUT-FILE.
           MOVE SPEC-FILE-NAME TO WS-INPUT-FILE-NAME
           MOVE 0 TO LINE-COUNT
           MOVE "N" TO WS-EOF-FLAG

           OPEN INPUT INPUT-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "TEXT-FILE-TO-JSON: cannot open "
                   FUNCTION TRIM(WS-INPUT-FILE-NAME)
                   ", status " WS-FILE-STATUS
               MOVE 1 TO LK-RESULT
               EXIT PARAGRAPH
           END-IF

           PERFORM UNTIL WS-EOF-FLAG = "Y"
               READ INPUT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       IF INPUT-LINE NOT = SPACES
                           IF LINE-COUNT = 60000
                               DISPLAY "TEXT-FILE-TO-JSON: more than "
                                   "60000 lines in "
                                   FUNCTION TRIM(WS-INPUT-FILE-NAME)
                               MOVE 2 TO LK-RESULT
                               MOVE "Y" TO WS-EOF-FLAG
                           ELSE
                               ADD 1 TO LINE-COUNT
                               MOVE INPUT-LINE TO LINE-TEXT(LINE-COUNT)
                           END-IF
                       END-IF
               END-READ
           END-PERFORM

           CLOSE INPUT-FILE.

      *> Add the line WS-LINE-IDX as one JSON object. Every object
      *> after the first is preceded by a comma.
       ADD-LINE.
           MOVE LINE-TEXT(WS-LINE-IDX) TO WS-CURRENT-LINE
           PERFORM FIND-CHAR-STARTS

           IF WS-LINE-IDX > 1
               STRING ',' X'0A'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           END-IF

           IF SPEC-KEY-FIELD = 0
               STRING '    {' X'0A'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           ELSE
               MOVE SPEC-KEY-FIELD TO WS-FIELD-IDX
               PERFORM GET-VALUE
               STRING '    '
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
               PERFORM WRITE-QUOTED-VALUE
               STRING ': {' X'0A'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           END-IF

           MOVE "Y" TO WS-FIRST-FIELD
           PERFORM VARYING WS-FIELD-IDX FROM 1 BY 1
                   UNTIL WS-FIELD-IDX > SPEC-FIELD-COUNT
               IF WS-FIELD-IDX NOT = SPEC-KEY-FIELD
                   PERFORM ADD-FIELD
               END-IF
           END-PERFORM

           STRING X'0A' '    }'
               DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
               ON OVERFLOW MOVE 3 TO LK-RESULT
           END-STRING.

      *> Add field WS-FIELD-IDX as  "key": value
      *> Numbers are written without quotes; an empty number is null,
      *> and a value that is not a valid JSON number is written as
      *> text instead, so the JSON stays valid.
       ADD-FIELD.
           IF WS-FIRST-FIELD = "Y"
               MOVE "N" TO WS-FIRST-FIELD
           ELSE
               STRING ',' X'0A'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           END-IF

           STRING '      "' FUNCTION TRIM(SF-NAME(WS-FIELD-IDX)) '": '
               DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
               ON OVERFLOW MOVE 3 TO LK-RESULT
           END-STRING

           PERFORM GET-VALUE

           IF SF-TYPE(WS-FIELD-IDX) = "N"
               IF WS-VALUE-LEN = 0
                   STRING 'null'
                       DELIMITED BY SIZE INTO JSON-BUFFER
                           POINTER JSON-PTR
                       ON OVERFLOW MOVE 3 TO LK-RESULT
                   END-STRING
               ELSE
                   PERFORM CHECK-NUMBER
                   IF WS-IS-NUMBER = "Y"
                       STRING WS-VALUE(1:WS-VALUE-LEN)
                           DELIMITED BY SIZE
                           INTO JSON-BUFFER POINTER JSON-PTR
                           ON OVERFLOW MOVE 3 TO LK-RESULT
                       END-STRING
                   ELSE
                       PERFORM WRITE-QUOTED-VALUE
                   END-IF
               END-IF
           ELSE
               PERFORM WRITE-QUOTED-VALUE
           END-IF.

      *> Write WS-VALUE as a JSON string: "value"
       WRITE-QUOTED-VALUE.
           STRING '"'
               DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
               ON OVERFLOW MOVE 3 TO LK-RESULT
           END-STRING
           IF WS-VALUE-LEN > 0
               STRING WS-VALUE(1:WS-VALUE-LEN)
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
                   ON OVERFLOW MOVE 3 TO LK-RESULT
               END-STRING
           END-IF
           STRING '"'
               DELIMITED BY SIZE INTO JSON-BUFFER POINTER JSON-PTR
               ON OVERFLOW MOVE 3 TO LK-RESULT
           END-STRING.

      *> Find where each character starts. A byte from X"80" to X"BF"
      *> continues the character before it instead of starting one.
       FIND-CHAR-STARTS.
           MOVE 0 TO WS-CHAR-COUNT
           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1
                   UNTIL WS-BYTE-IDX > 250
               IF WS-CURRENT-LINE(WS-BYTE-IDX:1) < X"80"
                  OR WS-CURRENT-LINE(WS-BYTE-IDX:1) > X"BF"
                   ADD 1 TO WS-CHAR-COUNT
                   MOVE WS-BYTE-IDX TO WS-CHAR-START(WS-CHAR-COUNT)
               END-IF
           END-PERFORM
           MOVE 251 TO WS-CHAR-START(WS-CHAR-COUNT + 1).

      *> Put field WS-FIELD-IDX of the current line into WS-VALUE:
      *> spaces at both ends removed, and " and \ escaped for JSON.
       GET-VALUE.
           MOVE 0 TO WS-VALUE-LEN
           MOVE SF-START(WS-FIELD-IDX) TO WS-FROM-CHAR
           COMPUTE WS-TO-CHAR =
               SF-START(WS-FIELD-IDX) + SF-WIDTH(WS-FIELD-IDX)
           IF WS-FROM-CHAR < 1 OR WS-FROM-CHAR > WS-CHAR-COUNT
               EXIT PARAGRAPH
           END-IF
           IF WS-TO-CHAR > WS-CHAR-COUNT + 1
               COMPUTE WS-TO-CHAR = WS-CHAR-COUNT + 1
           END-IF
           MOVE WS-CHAR-START(WS-FROM-CHAR) TO WS-FROM-BYTE
           MOVE WS-CHAR-START(WS-TO-CHAR)   TO WS-TO-BYTE

           PERFORM UNTIL WS-FROM-BYTE >= WS-TO-BYTE
               IF WS-CURRENT-LINE(WS-FROM-BYTE:1) = SPACE
                   ADD 1 TO WS-FROM-BYTE
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           PERFORM UNTIL WS-TO-BYTE <= WS-FROM-BYTE
               IF WS-CURRENT-LINE(WS-TO-BYTE - 1:1) = SPACE
                   SUBTRACT 1 FROM WS-TO-BYTE
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM

           PERFORM VARYING WS-BYTE-IDX FROM WS-FROM-BYTE BY 1
                   UNTIL WS-BYTE-IDX >= WS-TO-BYTE
               MOVE WS-CURRENT-LINE(WS-BYTE-IDX:1) TO WS-BYTE
      *> Control characters such as tab are not allowed in a JSON
      *> string, so they become spaces.
               IF WS-BYTE < SPACE
                   MOVE SPACE TO WS-BYTE
               END-IF
               IF WS-BYTE = '"' OR WS-BYTE = '\'
                   ADD 1 TO WS-VALUE-LEN
                   MOVE '\' TO WS-VALUE(WS-VALUE-LEN:1)
               END-IF
               ADD 1 TO WS-VALUE-LEN
               MOVE WS-BYTE TO WS-VALUE(WS-VALUE-LEN:1)
           END-PERFORM.

      *> Is WS-VALUE a valid JSON number? Accepted: an optional minus,
      *> digits (no leading zeros) and optionally a point and more
      *> digits, e.g. -92543.98, 0.5, 42
       CHECK-NUMBER.
           MOVE "Y" TO WS-IS-NUMBER
           MOVE 1 TO WS-POS
           IF WS-VALUE(1:1) = "-"
               ADD 1 TO WS-POS
           END-IF

           MOVE WS-POS TO WS-DIGITS-FROM
           PERFORM UNTIL WS-POS > WS-VALUE-LEN
               IF WS-VALUE(WS-POS:1) IS NUMERIC
                   ADD 1 TO WS-POS
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           IF WS-POS = WS-DIGITS-FROM
               MOVE "N" TO WS-IS-NUMBER
           END-IF
           IF WS-POS - WS-DIGITS-FROM > 1
              AND WS-VALUE(WS-DIGITS-FROM:1) = "0"
               MOVE "N" TO WS-IS-NUMBER
           END-IF

           IF WS-POS <= WS-VALUE-LEN AND WS-VALUE(WS-POS:1) = "."
               ADD 1 TO WS-POS
               MOVE WS-POS TO WS-DIGITS-FROM
               PERFORM UNTIL WS-POS > WS-VALUE-LEN
                   IF WS-VALUE(WS-POS:1) IS NUMERIC
                       ADD 1 TO WS-POS
                   ELSE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               IF WS-POS = WS-DIGITS-FROM
                   MOVE "N" TO WS-IS-NUMBER
               END-IF
           END-IF

           IF WS-POS <= WS-VALUE-LEN
               MOVE "N" TO WS-IS-NUMBER
           END-IF.
