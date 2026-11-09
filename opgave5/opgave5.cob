       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT5.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

           01 KUNDEOPL-1.
               COPY "KUNDEOPL.cpy".

           01 KUNDEOPL-2.
               COPY "KUNDEOPL.cpy".

       PROCEDURE DIVISION.

      * MOVE "Joachimsvej" TO VEJNAVN OF ADDRESSE of KUNDEOPL.
      * is not needed because each variable name is unique.
           MOVE "Joachimsvej" TO VEJNAVN OF KUNDEOPL-1.
           MOVE "3A" TO HUSNR OF KUNDEOPL-1.
           MOVE "2" TO ETAGE OF KUNDEOPL-1.
           MOVE "højre" TO SIDE OF KUNDEOPL-1.
           MOVE "Andeby" TO BYNAVN OF KUNDEOPL-1.
           MOVE "1234" TO POSTNR OF KUNDEOPL-1.
           MOVE "45" TO LANDE-KODE OF KUNDEOPL-1.
           MOVE "74652849" TO TELEFON OF KUNDEOPL-1.
           MOVE "andersand@andemail.dk" TO EMAIL OF KUNDEOPL-1.

      * MOVE "Joachimsvej" TO VEJNAVN OF ADDRESSE of KUNDEOPL.
      * is not needed because each variable name is unique.
           MOVE "Joachimsvej" TO VEJNAVN OF KUNDEOPL-2.
           MOVE "3A" TO HUSNR OF KUNDEOPL-2.
           MOVE "2" TO ETAGE OF KUNDEOPL-2.
           MOVE "højre" TO SIDE OF KUNDEOPL-2.
           MOVE "Andeby" TO BYNAVN OF KUNDEOPL-2.
           MOVE "1234" TO POSTNR OF KUNDEOPL-2.
           MOVE "45" TO LANDE-KODE OF KUNDEOPL-2.
           MOVE "74652849" TO TELEFON OF KUNDEOPL-2.
           MOVE "andersignesand@andemail.dk" TO EMAIL OF KUNDEOPL-2.
           
      * Prints variables
           DISPLAY "----------------------------------------"
           DISPLAY "Kunde 1."
           DISPLAY "----------------------------------------"
           DISPLAY "Vejnavn: " VEJNAVN OF KUNDEOPL-1.
           DISPLAY "Husnummer: " HUSNR OF KUNDEOPL-1.
           DISPLAY "Etage: " ETAGE OF KUNDEOPL-1.
           DISPLAY "Side: " SIDE OF KUNDEOPL-1.
           DISPLAY "Bynavn: " BYNAVN OF KUNDEOPL-1.
           DISPLAY "Post nr.: " POSTNR OF KUNDEOPL-1.
           DISPLAY "Landekode: " LANDE-KODE OF KUNDEOPL-1.
           DISPLAY "Telefonnummer: " TELEFON OF KUNDEOPL-1.
           DISPLAY "Email: " EMAIL OF KUNDEOPL-1.
           DISPLAY "----------------------------------------"

           DISPLAY SPACE
           DISPLAY SPACE

           DISPLAY "----------------------------------------"
           DISPLAY "Kunde 2."
      * Prints variables
           DISPLAY "----------------------------------------"
           DISPLAY "Vejnavn: " VEJNAVN OF KUNDEOPL-2.
           DISPLAY "Husnummer: " HUSNR OF KUNDEOPL-2.
           DISPLAY "Etage: " ETAGE OF KUNDEOPL-2.
           DISPLAY "Side: " SIDE OF KUNDEOPL-2.
           DISPLAY "Bynavn: " BYNAVN OF KUNDEOPL-2.
           DISPLAY "Post nr.: " POSTNR OF KUNDEOPL-2.
           DISPLAY "Landekode: " LANDE-KODE OF KUNDEOPL-2.
           DISPLAY "Telefonnummer: " TELEFON OF KUNDEOPL-2.
           DISPLAY "Email: " EMAIL OF KUNDEOPL-2.
           DISPLAY "----------------------------------------"

           STOP RUN.
