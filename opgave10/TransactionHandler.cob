       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRANSACTION-HANDLER.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE ASSIGN TO "Trans_sml_samp.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
       01 TRANSACTION-RECORD.
           COPY "transaktioner-strukt.cpy".

       WORKING-STORAGE SECTION.
       
       01 WS-EOF-FLAG PIC X VALUE "N".
       01 WS-NUMBER-OF-LINES PIC 9(3) VALUE 0.
       01 WS-TABLE-INDEX PIC 9(3) VALUE 0.
       01 WS-UNIQUE-COUNT PIC 9(3) VALUE 0.
       01 WS-PREV-CPR PIC X(11) VALUE SPACES.

      *> JSON LENGTH & POINTER
       01 WS-JSON-BUFFER PIC X(100000) VALUE SPACES.
       01 WS-PTR PIC 9(5) VALUE 1.
       01 WS-JSON-LEN PIC 9(5) VALUE 0.

      *> Working fields for trimming
       01 WS-CPR PIC X(15).
       01 WS-NAVN PIC X(30).
       01 WS-ADRESSE PIC X(50).
       01 WS-FØDSELSDATO PIC X(10).
       01 WS-KONTO-ID PIC X(15).
       01 WS-REG-NR PIC 9(4).
       01 WS-BELØB PIC 9(11)V99.
       01 WS-VALUTA PIC 9(3).
       01 WS-TRANSAKTIONSTYPE PIC X(15).
       01 WS-BUTIK PIC X(20).
       01 WS-TIDSPUNKT PIC X(26).
 
      *> In-memory TABLE matching copybook layout exactly
       01 WS-TRANSACTION-TABLE.
           05 WS-TRANSACTION-ENTRY OCCURS 1 TO 999 TIMES
           DEPENDING ON WS-NUMBER-OF-LINES
           ASCENDING key IS WS-TB-CPR.
           10 WS-TB-CPR PIC X(15).
           10 WS-TB-NAVN PIC X(30).
           10 WS-TB-ADRESSE PIC X(50).
           10 WS-TB-FØDSELSDATO PIC X(10).
           10 WS-TB-KONTO-ID PIC X(15).
           10 WS-TB-REG-NR PIC 9(4).
           10 WS-TB-BELØB PIC 9(11)V99.
           10 WS-TB-VALUTA PIC 9(3).
           10 WS-TB-TRANSAKTIONSTYPE PIC X(15).
           10 WS-TB-BUTIK PIC X(20).
           10 WS-TB-TIDSPUNKT PIC X(26).

       01 UNIQUE-TABLE.
           05 UNIQUE-ENTRY OCCURS 1 TO 999 TIMES
           DEPENDING ON WS-UNIQUE-COUNT
           ASCENDING key IS WS-UNQ-CPR.
           10 WS-UNQ-CPR PIC X(15).
           10 WS-UNQ-NAVN PIC X(30).
           10 WS-UNQ-ADRESSE PIC X(50).
           10 WS-UNQ-FØDSELSDATO PIC X(10).
           10 WS-UNQ-KONTO-ID PIC X(15).
           10 WS-UNQ-REG-NR PIC 9(4).
           10 WS-UNQ-BELØB PIC 9(11)V99.
           10 WS-UNQ-VALUTA PIC 9(3).
           10 WS-UNQ-TRANSAKTIONSTYPE PIC X(15).
           10 WS-UNQ-BUTIK PIC X(20).
           10 WS-UNQ-TIDSPUNKT PIC X(26).

      *> LINKAGE SECTION.
      *>01 LK-JSON-OUT          PIC X(17979).
      *>01 LK-JSON-LEN          PIC 9(5).

      *>PROCEDURE DIVISION USING LK-JSON-OUT LK-JSON-LEN.
       PROCEDURE DIVISION.
       MAIN-LOGIC.
      *> COUNT LINES TO SIZE the TABLE
           OPEN INPUT TRANSACTION-FILE.
           PERFORM UNTIL WS-EOF-FLAG = "Y"
               READ TRANSACTION-FILE
               AT END 
                   MOVE "Y" TO WS-EOF-FLAG
               NOT AT END 
                   IF TRANSACTION-RECORD NOT = SPACES
                       ADD 1 TO WS-NUMBER-OF-LINES
                   END-IF 
               END-READ
           END-PERFORM.
           CLOSE TRANSACTION-FILE.

           PERFORM UNTIL WS-EOF-FLAG = "Y"
               READ TRANSACTION-FILE INTO TRANSACTION-RECORD
               AT END 
                   MOVE "Y" TO WS-EOF-FLAG
               NOT AT END 
                   IF TRANSACTION-RECORD NOT = SPACES
                       ADD 1 TO WS-TABLE-INDEX
                   MOVE TRANSACTION-RECORD TO
                       WS-TRANSACTION-ENTRY(WS-TABLE-INDEX)
                   END-IF
               END-READ
           END-PERFORM.
           CLOSE TRANSACTION-FILE.

           SORT WS-TRANSACTION-ENTRY ON ASCENDING KEY WS-TB-CPR.

      *> Remove potential DUPLICATES
           MOVE 0 TO WS-UNIQUE-COUNT
           PERFORM VARYING WS-TABLE-INDEX FROM 1 BY 1
                   UNTIL WS-TABLE-INDEX > WS-NUMBER-OF-LINES
               IF WS-TB-CPR(WS-TABLE-INDEX) NOT = WS-PREV-CPR
                   ADD 1 TO WS-UNIQUE-COUNT
                   
                   MOVE WS-TB-CPR(WS-TABLE-INDEX)
                       TO WS-UNQ-CPR(WS-UNIQUE-COUNT)
                   
                   MOVE FUNCTION TRIM(WS-TB-NAVN(WS-TABLE-INDEX))
                       TO WS-UNQ-NAVN(WS-UNIQUE-COUNT)
                   
                   MOVE FUNCTION TRIM(WS-TB-ADRESSE(WS-TABLE-INDEX))
                       TO WS-UNQ-ADRESSE(WS-UNIQUE-COUNT)

                   MOVE FUNCTION
                       TRIM(WS-TB-FØDSELSDATO(WS-TABLE-INDEX))
                       TO WS-UNQ-FØDSELSDATO(WS-UNIQUE-COUNT)

                   MOVE FUNCTION TRIM(WS-TB-KONTO-ID(WS-TABLE-INDEX))
                       TO WS-UNQ-KONTO-ID(WS-UNIQUE-COUNT)

                   MOVE FUNCTION TRIM(WS-TB-REG-NR(WS-TABLE-INDEX))
                       TO WS-UNQ-REG-NR(WS-UNIQUE-COUNT)

                   MOVE FUNCTION TRIM(WS-TB-BELØB(WS-TABLE-INDEX))
                       TO WS-UNQ-BELØB(WS-UNIQUE-COUNT)

                   MOVE FUNCTION TRIM(WS-TB-VALUTA(WS-TABLE-INDEX))
                       TO WS-UNQ-VALUTA(WS-UNIQUE-COUNT)

                   MOVE FUNCTION
                       TRIM(WS-TB-TRANSAKTIONSTYPE(WS-TABLE-INDEX))
                       TO WS-UNQ-TRANSAKTIONSTYPE(WS-UNIQUE-COUNT)

                   MOVE FUNCTION TRIM(WS-TB-BUTIK(WS-TABLE-INDEX))
                       TO WS-UNQ-BUTIK(WS-UNIQUE-COUNT)

                   MOVE FUNCTION TRIM(WS-TB-TIDSPUNKT(WS-TABLE-INDEX))
                       TO WS-UNQ-TIDSPUNKT(WS-UNIQUE-COUNT)

                   MOVE WS-TB-CPR(WS-TABLE-INDEX)
                       TO WS-PREV-CPR

               END-IF 
           END-PERFORM.
