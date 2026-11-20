       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILES-TO-JSON.
      *> Turns every file listed in JSON-SPEC into one JSON object:
      *>   {
      *>     "<json name of file 1>": ...,
      *>     "<json name of file 2>": ...
      *>   }
      *> Each file is handled by TEXT-FILE-TO-JSON.
      *> JSON-LEN is 0 if anything went wrong.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FILE-IDX          PIC 9(2).
       01 WS-PTR               PIC 9(8).
       01 WS-RESULT            PIC 9.

       LINKAGE SECTION.
       01 JSON-SPEC.
           COPY "json-spec.cpy".
       COPY "json-buffer.cpy".
       01 JSON-LEN             PIC 9(8).

       PROCEDURE DIVISION USING JSON-SPEC JSON-BUFFER JSON-LEN.
       MAIN-LOGIC.
           MOVE 1 TO WS-PTR
           MOVE 0 TO WS-RESULT
           MOVE 0 TO JSON-LEN

           STRING '{' X'0A'
               DELIMITED BY SIZE INTO JSON-BUFFER POINTER WS-PTR
           END-STRING

           PERFORM VARYING WS-FILE-IDX FROM 1 BY 1
                   UNTIL WS-FILE-IDX > SPEC-FILE-COUNT
                      OR WS-RESULT NOT = 0
               IF WS-FILE-IDX > 1
                   STRING ',' X'0A'
                       DELIMITED BY SIZE INTO JSON-BUFFER POINTER WS-PTR
                       ON OVERFLOW MOVE 3 TO WS-RESULT
                   END-STRING
               END-IF
               IF WS-RESULT = 0
                   CALL "TEXT-FILE-TO-JSON"
                       USING FILE-SPEC(WS-FILE-IDX)
                             JSON-BUFFER WS-PTR WS-RESULT
                   END-CALL
               END-IF
           END-PERFORM

           IF WS-RESULT = 0
               STRING X'0A' '}'
                   DELIMITED BY SIZE INTO JSON-BUFFER POINTER WS-PTR
                   ON OVERFLOW MOVE 3 TO WS-RESULT
               END-STRING
           END-IF

           IF WS-RESULT = 0
               COMPUTE JSON-LEN = WS-PTR - 1
           ELSE
               IF WS-RESULT = 3
                   DISPLAY "FILES-TO-JSON: the JSON is larger than "
                       "JSON-BUFFER"
               END-IF
               DISPLAY "FILES-TO-JSON: no JSON returned"
           END-IF

           GOBACK.
