       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "Kundeoplysninger.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUTPUT-FILE ASSIGN TO "outputfile.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD INPUT-FILE.
       01 INPUT-RECORD.
              05 VEJNAVN       PIC X(30).
              05 HUSNR         PIC X(5).
              05 ETAGE         PIC X(5).
              05 SIDE          PIC X(6).
              05 BYNAVN        PIC X(6).
              05 POSTNR        PIC 9(4).
              05 LANDE-KODE    PIC X(5).
              05 TELEFON       PIC X(8).
              05 EMAIL         PIC X(50).

       FD OUTPUT-FILE.
       01 OUTPUT-RECORD.
              05 VEJNAVN       PIC X(30).
              05 HUSNR         PIC X(5).
              05 ETAGE         PIC X(5).
              05 SIDE          PIC X(6).
              05 BYNAVN        PIC X(6).
              05 POSTNR        PIC 9(4).
              05 LANDE-KODE    PIC X(5).
              05 TELEFON       PIC X(8).
              05 EMAIL         PIC X(50).

       WORKING-STORAGE SECTION.
           01 END-OF-FILE PIC X VALUE "N".


       PROCEDURE DIVISION.

       MAIN-PROCEDURE.
           OPEN INPUT INPUT-FILE
           OPEN OUTPUT OUTPUT-FILE

           PERFORM UNTIL END-OF-FILE = "Y"
               READ INPUT-FILE INTO INPUT-RECORD
               AT END 
                   MOVE "Y" TO END-OF-FILE
               NOT AT END 
                   MOVE INPUT-RECORD TO OUTPUT-RECORD
                   WRITE OUTPUT-RECORD
                   DISPLAY OUTPUT-RECORD
               END-READ 
           END-PERFORM

           CLOSE INPUT-FILE
           CLOSE OUTPUT-FILE

           STOP RUN.
