       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT9.

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
       01 END-OF-FILE       PIC X VALUE "N".
       01 WS-IX             PIC 9(2) VALUE 1.

       01 KONTO-ARRAY OCCURS 5 TIMES.
           COPY "KONTOOPL.cpy".

       PROCEDURE DIVISION.
           OPEN INPUT INPUT-FILE
           OPEN OUTPUT OUTPUT-FILE
           
           PERFORM UNTIL END-OF-FILE = "Y"
               READ INPUT-FILE INTO INPUT-RECORD
               AT END 
                   MOVE "Y" TO END-OF-FILE
               NOT AT END
                   MOVE INPUT-RECORD TO KONTO-ARRAY(WS-IX)
                   MOVE INPUT-RECORD TO OUTPUT-RECORD
                   WRITE OUTPUT-RECORD
                   ADD 1 TO WS-IX
               END-READ
           END-PERFORM

           CLOSE INPUT-FILE
           CLOSE OUTPUT-FILE
           
           STOP RUN.
