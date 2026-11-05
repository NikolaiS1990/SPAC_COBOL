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
              05 FORNAVN       PIC X(12).
              05 EFTERNAVN     PIC X(4).
              05 VEJNAVN       PIC X(12).
              05 HUSNR         PIC X(3).
              05 ETAGE         PIC X(2).
              05 SIDE          PIC X(7).
              05 BYNAVN        PIC X(7).
              05 POSTNR        PIC 9(5).
              05 LANDE-KODE    PIC X(3).
              05 TELEFON       PIC 9(9).
              05 EMAIL         PIC X(23).

       FD OUTPUT-FILE.
       01 KUNDEKONTO.
              02 OUTPUT-TEXT PIC X(200).

       WORKING-STORAGE SECTION.

           01 KONTO-REKORD.
               COPY "KONTOOPL.cpy".
