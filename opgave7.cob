       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "Kundeoplysninger.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUTPUT-FILE ASSIGN TO "KundeoplysningerOut.txt"
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
       01 KUNDE-ADR.
              02 NAVN-ADR  PIC X(200).

       WORKING-STORAGE SECTION.
           01 END-OF-FILE PIC X VALUE "N".


       PROCEDURE DIVISION.
           OPEN INPUT INPUT-FILE
           OPEN OUTPUT OUTPUT-FILE


           PERFORM UNTIL END-OF-FILE = "Y"
              READ INPUT-FILE INTO INPUT-RECORD
               AT END 
                   MOVE "Y" TO END-OF-FILE
              NOT AT END
                   PERFORM FORMAT-NAVN
                   PERFORM FORMAT-ADR
                   PERFORM POSTNR-BY
                   PERFORM KONTAKT-INFO
                   MOVE SPACES TO KUNDE-ADR
                   WRITE KUNDE-ADR
               END-READ
           END-PERFORM.

           CLOSE INPUT-FILE.
           CLOSE OUTPUT-FILE.

           STOP RUN.


           FORMAT-NAVN.
               MOVE SPACES TO NAVN-ADR.
               STRING
                   FORNAVN DELIMITED BY SPACE 
                   " " DELIMITED BY SIZE 
                   EFTERNAVN DELIMITED BY SPACE
                   INTO NAVN-ADR OF KUNDE-ADR
               END-STRING.
               WRITE KUNDE-ADR.
           EXIT.

           FORMAT-ADR.
               MOVE SPACES TO NAVN-ADR.
               STRING
                   VEJNAVN DELIMITED BY SPACE 
                   " " DELIMITED BY SIZE
                   HUSNR DELIMITED BY SPACE
                   " " DELIMITED BY SIZE
                   ETAGE DELIMITED BY SPACE
                   " " DELIMITED BY SIZE
                   SIDE DELIMITED BY SPACE
                   INTO NAVN-ADR OF KUNDE-ADR
               END-STRING.
               WRITE KUNDE-ADR.
           EXIT.

           POSTNR-BY.
               MOVE SPACES TO NAVN-ADR.
               STRING
                   BYNAVN DELIMITED BY SPACE
                   " " DELIMITED BY SIZE
                   POSTNR DELIMITED BY SPACE 
                   INTO NAVN-ADR OF KUNDE-ADR
               END-STRING.
               WRITE KUNDE-ADR.
           EXIT.

           KONTAKT-INFO.
               MOVE SPACES TO NAVN-ADR.
               STRING
                   EMAIL DELIMITED BY SPACE
                   INTO NAVN-ADR OF KUNDE-ADR
               END-STRING.
               WRITE KUNDE-ADR.

               MOVE SPACES TO NAVN-ADR.
               STRING
                   TELEFON DELIMITED BY SPACE
                   INTO NAVN-ADR OF KUNDE-ADR
               END-STRING.
               WRITE KUNDE-ADR.
           EXIT.

