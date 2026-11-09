       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT8.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "KontoOpl.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUTPUT-FILE ASSIGN TO "KUNDEKONTO.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD INPUT-FILE.
       01 INPUT-RECORD.
           COPY "KONTOOPL.cpy".
       FD OUTPUT-FILE.
       01 OUTPUT-RECORD.
           COPY "KONTOOPL.cpy".

       WORKING-STORAGE SECTION.
       01 END-OF-FILE PIC X VALUE "N".
       

       PROCEDURE DIVISION.
           OPEN INPUT INPUT-FILE.
           OPEN OUTPUT OUTPUT-FILE.
           
           PERFORM UNTIL END-OF-FILE = "Y"
               READ INPUT-FILE INTO INPUT-RECORD
               AT END 
                   MOVE "Y" TO END-OF-FILE
               NOT AT END
                   MOVE SPACES TO OUTPUT-RECORD
                   MOVE KUNDE-ID OF INPUT-RECORD
                       TO KUNDE-ID OF OUTPUT-RECORD
                   MOVE KONTO-ID OF INPUT-RECORD
                       TO KONTO-ID OF OUTPUT-RECORD
                   MOVE KONTO-TYPE OF INPUT-RECORD
                       TO KONTO-TYPE OF OUTPUT-RECORD
                   MOVE BALANCE OF INPUT-RECORD
                       TO BALANCE OF OUTPUT-RECORD
                   MOVE VALUTA-KD OF INPUT-RECORD
                       TO VALUTA-KD OF OUTPUT-RECORD
                   WRITE OUTPUT-RECORD
                       
               END-READ
               
           END-PERFORM.

           CLOSE INPUT-FILE.
           CLOSE OUTPUT-FILE.
           
           STOP RUN.
