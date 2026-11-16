      *> Which text files FILES-TO-JSON should turn into JSON, and the
      *> layout of each. Filled in by main.cob.
           05 SPEC-FILE-COUNT      PIC 9(2).
           05 FILE-SPEC OCCURS 10 TIMES.
               COPY "fil-spec.cpy".
