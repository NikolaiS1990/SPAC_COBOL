       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAIN.
      *> Tells FILES-TO-JSON which text files to turn into JSON and
      *> what the fields of each file are, then prints the JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 JSON-SPEC.
           COPY "json-spec.cpy".
       COPY "json-buffer.cpy".
       01 JSON-LEN                 PIC 9(8).

      *> Input for ADD-FILE.
       01 NEW-FILE-NAME            PIC X(256).
       01 NEW-JSON-NAME            PIC X(50).
       01 NEW-KEY-FIELD            PIC 9(2).

      *> Input for ADD-FIELD: "<json key> <start> <width> <type>",
      *> separated by spaces. Type S = text, N = number.
       01 NEW-FIELD                PIC X(80).
       01 NF-NAME                  PIC X(50).
       01 NF-START                 PIC X(10).
       01 NF-WIDTH                 PIC X(10).
       01 NF-TYPE                  PIC X(10).

       01 WS-F                     PIC 9(2).
       01 WS-N                     PIC 9(2).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           MOVE 0 TO SPEC-FILE-COUNT

      *> Banker.txt: one object per bank, keyed by reg_nr (field 1)
           MOVE "Banker.txt"            TO NEW-FILE-NAME
           MOVE "banker"                TO NEW-JSON-NAME
           MOVE 1                       TO NEW-KEY-FIELD
           PERFORM ADD-FILE
           MOVE "reg_nr             1   4 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "banknavn           5  30 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "adresse           35  50 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "telefon           85  15 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "email            100  33 S" TO NEW-FIELD
           PERFORM ADD-FIELD

      *> Transactions: a list of objects (key field 0)
           MOVE "Trans_sml_samp.txt"    TO NEW-FILE-NAME
           MOVE "transaktioner"         TO NEW-JSON-NAME
           MOVE 0                       TO NEW-KEY-FIELD
           PERFORM ADD-FILE
           MOVE "cpr                1  15 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "navn              16  30 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "adresse           46  50 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "fødselsdato       96  10 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "konto_id         106  15 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "reg_nr           121   4 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "beløb            125  17 N" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "valuta           142   3 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "transaktionstype 145  21 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "butik            166  20 S" TO NEW-FIELD
           PERFORM ADD-FIELD
           MOVE "tidspunkt        186  26 S" TO NEW-FIELD
           PERFORM ADD-FIELD

           CALL "FILES-TO-JSON" USING JSON-SPEC JSON-OUT JSON-LEN
           END-CALL

           IF JSON-LEN > 0
               DISPLAY JSON-OUT(1:JSON-LEN)
           ELSE
               DISPLAY "No JSON was returned"
           END-IF

           STOP RUN.

      *> Add a file to JSON-SPEC. Its fields are added afterwards
      *> with ADD-FIELD.
       ADD-FILE.
           IF SPEC-FILE-COUNT = 10
               DISPLAY "MAIN: more than 10 files in JSON-SPEC"
               STOP RUN
           END-IF
           ADD 1 TO SPEC-FILE-COUNT
           MOVE SPEC-FILE-COUNT TO WS-F
           MOVE NEW-FILE-NAME   TO SPEC-FILE-NAME(WS-F)
           MOVE NEW-JSON-NAME   TO SPEC-JSON-NAME(WS-F)
           MOVE NEW-KEY-FIELD   TO SPEC-KEY-FIELD(WS-F)
           MOVE 0               TO SPEC-FIELD-COUNT(WS-F).

      *> Add a field, described in NEW-FIELD, to the last added file.
       ADD-FIELD.
           IF SPEC-FIELD-COUNT(WS-F) = 20
               DISPLAY "MAIN: more than 20 fields for "
                   FUNCTION TRIM(SPEC-FILE-NAME(WS-F))
               STOP RUN
           END-IF
           ADD 1 TO SPEC-FIELD-COUNT(WS-F)
           MOVE SPEC-FIELD-COUNT(WS-F) TO WS-N

           MOVE SPACES TO NF-NAME NF-START NF-WIDTH NF-TYPE
           UNSTRING NEW-FIELD DELIMITED BY ALL SPACE
               INTO NF-NAME NF-START NF-WIDTH NF-TYPE
           END-UNSTRING

           MOVE NF-NAME                  TO SF-NAME(WS-F WS-N)
           MOVE FUNCTION NUMVAL(NF-START) TO SF-START(WS-F WS-N)
           MOVE FUNCTION NUMVAL(NF-WIDTH) TO SF-WIDTH(WS-F WS-N)
           MOVE NF-TYPE                  TO SF-TYPE(WS-F WS-N).
