      *> This copybook allows main.cob to describe an input file.
      *> main.cob can describe the name of the input file and where
      *> each field begins and ends.
      *> From main.cob it also gets the (SPEC-JSON-NAME, SF-NAME) and
      *> the types (SF-TYPE).

      *> It is also used inside json-spec.cpy, and TextFileToJson.cob.

           10 SPEC-FILE-NAME       PIC X(256).
      *> The key this file's data gets in the JSON, e.g. "banker".
           10 SPEC-JSON-NAME       PIC X(50).
      
      *> If set to 1, it the unique parts of the text file (such
      *> as the reg number), will be used as a key in the JSON.
      *> If set to 0, the JSON will be structured differently.
           10 SPEC-KEY-FIELD       PIC 9(2).

           10 SPEC-FIELD-COUNT     PIC 9(2).

        *> One entry per field in a line of the file.
           10 SPEC-FIELD OCCURS 20 TIMES.
        *> The name the field gets in the JSON, e.g. "banknavn".
                 15 SF-NAME          PIC X(50).
        *> Position of the field's first character in the line,
        *> e.g. 5 for banknavn, because reg_nr fills 1 to 4.
                 15 SF-START         PIC 9(3).
        *> Number of characters in the field, e.g. 30 for banknavn.
                 15 SF-WIDTH         PIC 9(3).
        *> S if the value is text, N if it is a number, e.g. S for
        *> banknavn and N for beløb in the transactions.
                 15 SF-TYPE          PIC X.
