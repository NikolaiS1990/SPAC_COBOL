       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT6.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "Kundeoplysninger.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD INPUT-FILE.
       01 INPUT-RECORD.
              05 NAVN          PIC X(16).
              05 VEJNAVN       PIC X(12).
              05 HUSNR         PIC X(3).
              05 ETAGE         PIC X(2).
              05 SIDE          PIC X(7).
              05 BYNAVN        PIC X(7).
              05 POSTNR        PIC 9(5).
              05 LANDE-KODE    PIC X(3).
              05 TELEFON       PIC X(9).
              05 EMAIL         PIC X(22).

       WORKING-STORAGE SECTION.
           01 END-OF-FILE PIC X VALUE "N".


       PROCEDURE DIVISION.
           OPEN INPUT INPUT-FILE.

           PERFORM UNTIL END-OF-FILE = "Y"
              READ INPUT-FILE INTO INPUT-RECORD
                  AT END MOVE "Y" TO END-OF-FILE
              NOT AT END
                     DISPLAY "----------------------------------------"
                     DISPLAY "Navn: " NAVN OF INPUT-RECORD
                     DISPLAY "Vejnavn: " VEJNAVN OF INPUT-RECORD
                     DISPLAY "Husnummer: " HUSNR OF INPUT-RECORD
                     DISPLAY "Etage: " ETAGE OF INPUT-RECORD
                     DISPLAY "Side: " SIDE OF INPUT-RECORD
                     DISPLAY "Bynavn: " BYNAVN OF INPUT-RECORD
                     DISPLAY "Post nr.: " POSTNR OF INPUT-RECORD
                     DISPLAY "Landekode: " LANDE-KODE OF INPUT-RECORD
                     DISPLAY "Telefonnummer: " TELEFON OF INPUT-RECORD
                     DISPLAY "Email: " EMAIL OF INPUT-RECORD
                     DISPLAY "----------------------------------------"
              END-READ
           END-PERFORM.

           CLOSE INPUT-FILE.

           STOP RUN.
