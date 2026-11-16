      *> One text file and the layout of its lines.
      *> Used inside json-spec.cpy, and by TextFileToJson.cob.
           10 SPEC-FILE-NAME       PIC X(256).
      *> The key this file's data gets in the JSON, e.g. "banker".
           10 SPEC-JSON-NAME       PIC X(50).
      *> 0: the lines become a JSON array of objects.
      *> n: the lines become a JSON object keyed by field n
      *>    (field n is then not repeated inside each object).
           10 SPEC-KEY-FIELD       PIC 9(2).
           10 SPEC-FIELD-COUNT     PIC 9(2).
      *> For each field: JSON key, first character column (1 = the
      *> first character of the line), width in characters and
      *> type: S = text, N = number.
           10 SPEC-FIELD OCCURS 20 TIMES.
               15 SF-NAME          PIC X(50).
               15 SF-START         PIC 9(3).
               15 SF-WIDTH         PIC 9(3).
               15 SF-TYPE          PIC X.
