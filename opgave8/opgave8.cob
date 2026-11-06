       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.

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
                   DISPLAY " "
               END-READ
               
           END-PERFORM.

           DISPLAY INPUT-RECORD.
           
           CLOSE INPUT-FILE.
           CLOSE OUTPUT-FILE.
           
           STOP RUN.
