       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-HANDLER.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BANK-FILE ASSIGN TO "Banker.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD BANK-FILE.
       01 BANK-RECORD.
           COPY "banker-strukt.cpy".

       WORKING-STORAGE SECTION.
       01 EOF-FLAG             PIC X VALUE "N".
       01 NUMBER-OF-LINES      PIC 9(3) VALUE 0.
       01 TABLE-INDEX          PIC 9(3) VALUE 0.
       01 UNIQUE-COUNT         PIC 9(3) VALUE 0.
       01 PREV-REG-NR          PIC 9(4) VALUE 9999.

      *> JSON LENGTH & POINTER
       01 JSON-BUFFER          PIC X(32000) VALUE SPACES.
       01 PTR                  PIC 9(5) VALUE 1.
       01 JSON-LEN             PIC 9(5) VALUE 0.

      *> Working fields for trimming
       01 WS-NAVN              PIC X(30).
       01 WS-ADRESSE           PIC X(50).
       01 WS-TLF               PIC X(15).
       01 WS-EMAIL             PIC X(33).

      *> In-memory table matching copybook layout exactly
       01 BANK-TABLE.
           05 BANK-ENTRY OCCURS 1 TO 999 TIMES
               DEPENDING ON NUMBER-OF-LINES
               ASCENDING KEY IS TB-REG-NR.
               10 TB-REG-NR     PIC 9(4).
               10 TB-BANKNAVN   PIC X(30).
               10 TB-BANKADRESSE PIC X(50).
               10 TB-TELEFON    PIC X(15).
               10 TB-EMAIL      PIC X(33).

       01 UNIQUE-TABLE.
           05 UNIQUE-ENTRY OCCURS 1 TO 999 TIMES
               DEPENDING ON UNIQUE-COUNT.
               10 UNQ-REG-NR     PIC 9(4).
               10 UNQ-BANKNAVN   PIC X(30).
               10 UNQ-BANKADRESSE PIC X(50).
               10 UNQ-TELEFON    PIC X(15).
               10 UNQ-EMAIL      PIC X(33).

       LINKAGE SECTION.
       01 LK-JSON-OUT          PIC X(17979).
       01 LK-JSON-LEN          PIC 9(5).

       PROCEDURE DIVISION USING LK-JSON-OUT LK-JSON-LEN.
       MAIN-LOGIC.
      *> Count lines to size the table
           OPEN INPUT BANK-FILE.
           PERFORM UNTIL EOF-FLAG = "Y"
               READ BANK-FILE
               AT END 
                   MOVE "Y" TO EOF-FLAG
               NOT AT END
                   IF BANK-RECORD NOT = SPACES
                       ADD 1 TO NUMBER-OF-LINES
                   END-IF
               END-READ
           END-PERFORM.
           CLOSE BANK-FILE.
           
      *> Load records directly into the table variable
           OPEN INPUT BANK-FILE.
           MOVE "N" TO EOF-FLAG
           MOVE 0 TO TABLE-INDEX

           PERFORM UNTIL EOF-FLAG = "Y"
               READ BANK-FILE INTO BANK-RECORD
                   AT END 
                       MOVE "Y" TO EOF-FLAG
                   NOT AT END
                       IF BANK-RECORD NOT = SPACES
                              ADD 1 TO TABLE-INDEX
                           MOVE BANK-RECORD TO 
                               BANK-ENTRY(TABLE-INDEX)
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE BANK-FILE.

           SORT BANK-ENTRY ON ASCENDING KEY TB-REG-NR.

      *> Remove potential duplicates
           MOVE 0 TO UNIQUE-COUNT
           PERFORM VARYING TABLE-INDEX FROM 1 BY 1 
                   UNTIL TABLE-INDEX > NUMBER-OF-LINES
               IF TB-REG-NR(TABLE-INDEX) NOT = PREV-REG-NR
                   ADD 1 TO UNIQUE-COUNT
                   MOVE TB-REG-NR(TABLE-INDEX) 
                       TO UNQ-REG-NR(UNIQUE-COUNT)
                   MOVE FUNCTION TRIM(TB-BANKNAVN(TABLE-INDEX)) 
                       TO UNQ-BANKNAVN(UNIQUE-COUNT)
                   MOVE FUNCTION TRIM(TB-BANKADRESSE(TABLE-INDEX)) 
                       TO UNQ-BANKADRESSE(UNIQUE-COUNT)
                   MOVE FUNCTION TRIM(TB-TELEFON(TABLE-INDEX)) 
                       TO UNQ-TELEFON(UNIQUE-COUNT)
                   MOVE FUNCTION TRIM(TB-EMAIL(TABLE-INDEX)) 
                       TO UNQ-EMAIL(UNIQUE-COUNT)
                   MOVE TB-REG-NR(TABLE-INDEX) 
                       TO PREV-REG-NR
               END-IF
           END-PERFORM.

      *> Build JSON using PTR pointer tracking
           MOVE 1 TO PTR

           STRING 
               '{' X'0A'
               '  "banker": {' X'0A'
               DELIMITED BY SIZE
               INTO JSON-BUFFER
               POINTER PTR
           END-STRING

           PERFORM VARYING TABLE-INDEX FROM 1 BY 1 
                   UNTIL TABLE-INDEX > UNIQUE-COUNT
               
               MOVE UNQ-BANKNAVN(TABLE-INDEX)    TO WS-NAVN
               MOVE UNQ-BANKADRESSE(TABLE-INDEX) TO WS-ADRESSE
               MOVE UNQ-TELEFON(TABLE-INDEX)     TO WS-TLF
               MOVE UNQ-EMAIL(TABLE-INDEX)       TO WS-EMAIL
      *> Makes sure a comma is not added after the last hash map
               IF TABLE-INDEX < UNIQUE-COUNT
                   STRING 
                       '    "' UNQ-REG-NR(TABLE-INDEX) '": {' X'0A'
                       '      "banknavn": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-NAVN) 
                       '",' X'0A'
                       '      "adresse": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-ADRESSE) 
                       '",' X'0A'
                       '      "telefon": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-TLF) 
                       '",' X'0A'
                       '      "email": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-EMAIL) 
                       '"' X'0A'
                       '    },' X'0A'
                       DELIMITED BY SIZE
                       INTO JSON-BUFFER
                       POINTER PTR
                   END-STRING
               ELSE
                   STRING 
                       '    "' UNQ-REG-NR(TABLE-INDEX) '": {' X'0A'
                       '      "banknavn": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-NAVN) 
                       '",' X'0A'
                       '      "adresse": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-ADRESSE) 
                       '",' X'0A'
                       '      "telefon": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-TLF) 
                       '",' X'0A'
                       '      "email": "' 
                       DELIMITED BY SIZE
                       FUNCTION TRIM(WS-EMAIL) 
                       '"' X'0A'
                       '    }' X'0A'
                       DELIMITED BY SIZE
                       INTO JSON-BUFFER
                       POINTER PTR
                   END-STRING
               END-IF

           END-PERFORM

           STRING 
               '  }' X'0A'
               '}' X'0A'
               DELIMITED BY SIZE
               INTO JSON-BUFFER
               POINTER PTR
           END-STRING

      *> Adapt the lenght OF the json STRING
           COMPUTE JSON-LEN = PTR - 2
           MOVE JSON-BUFFER(1:JSON-LEN) TO LK-JSON-OUT
           MOVE JSON-LEN TO LK-JSON-LEN

           GOBACK.
      