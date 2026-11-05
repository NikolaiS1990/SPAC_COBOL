       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "Kundeoplysninger.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD INPUT-FILE.
       01 INPUT-RECORD.
              05 VEJNAVN       PIC X(12).
              05 HUSNR         PIC X(3).
              05 ETAGE         PIC X(2).
              05 SIDE          PIC X(7).
              05 BYNAVN        PIC X(7).
              05 POSTNR        PIC 9(5).
              05 LANDE-KODE    PIC X(3).
              05 TELEFON       PIC X(9).
              05 EMAIL         PIC X(21).

       WORKING-STORAGE SECTION.
           01 END-OF-FILE PIC X VALUE "N".


       PROCEDURE DIVISION.
           OPEN INPUT INPUT-FILE
           READ INPUT-FILE INTO INPUT-RECORD

           CLOSE INPUT-FILE

           DISPLAY "----------------------------------------"
           DISPLAY "Vejnavn: " VEJNAVN OF INPUT-RECORD.
           DISPLAY "Husnummer: " HUSNR OF INPUT-RECORD.
           DISPLAY "Etage: " ETAGE OF INPUT-RECORD.
           DISPLAY "Side: " SIDE OF INPUT-RECORD.
           DISPLAY "Bynavn: " BYNAVN OF INPUT-RECORD.
           DISPLAY "Post nr.: " POSTNR OF INPUT-RECORD.
           DISPLAY "Landekode: " LANDE-KODE OF INPUT-RECORD.
           DISPLAY "Telefonnummer: " TELEFON OF INPUT-RECORD.
           DISPLAY "Email: " EMAIL OF INPUT-RECORD.
           DISPLAY "----------------------------------------"

           STOP RUN.
