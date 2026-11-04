       IDENTIFICATION DIVISION.
       PROGRAM-ID. ASSIGNMENT2.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

           01 KUNDEOPL.
               COPY "KUNDEOPL.cpy".

       PROCEDURE DIVISION.

      * MOVE "Joachimsvej" TO VEJNAVN OF ADDRESSE of KUNDEOPL.
      * is not needed because each variable name is unique.
           MOVE "Joachimsvej" TO VEJNAVN.
           MOVE "3A" TO HUSNR.
           MOVE "2" TO ETAGE.
           MOVE "højre" TO SIDE.
           MOVE "Andeby" TO BYNAVN.
           MOVE "1234" TO POSTNR.
           MOVE "45" TO LANDE-KODE.
           MOVE "74652849" TO TELEFON.
           MOVE "andersand@andemail.dk" TO EMAIL.
           
      * Prints variables
           DISPLAY "----------------------------------------"
           DISPLAY "Vejnavn: " VEJNAVN.
           DISPLAY "Husnummer: " HUSNR.
           DISPLAY "Etage: " ETAGE.
           DISPLAY "Side: " SIDE.
           DISPLAY "Bynavn: " BYNAVN.
           DISPLAY "Post nr.: " POSTNR.
           DISPLAY "Landekode: " LANDE-KODE.
           DISPLAY "Telefonnummer: " TELEFON.
           DISPLAY "Email: " EMAIL.
           DISPLAY "----------------------------------------"

           STOP RUN.
