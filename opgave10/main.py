import subprocess
import json
from pathlib import Path

"""Kunde: [Kundens navn]
Adresse: [Kundens adresse]
Registreringsnummer: [REG-NR]
Bank: [Bankens navn]
Bankadresse: [Bankens adresse]
Telefon: [Bankens telefon]
E-mail: [Bankens e-mail]
Kontoudskrift for kontonr.: [Kontonummer}
Dato Tidspunkt Transaktionstype Beløb (DKK) Beløb (valuta) Valutakode Butik
[En linje per transaktion]
Totalt indbetalt (DKK): XX,XXX.XX
Totalt udbetalt (DKK): -XX,XXX.XX
Saldo (DKK): XX,XXX.XX [Gå ud fra hver kunde havde kr. 50.000 stående inden
transktionerne]
Med venlig hilse
[Bankens navn]"""



from pathlib import Path

main = Path("main").is_file()


def check_if_cobol_files() -> None:

    files = [
        "main.cob",
        "RemoveDuplicates.cob",
        "TextFileToJson.cob",
        "FilesToJson.cob",
        "Banker.txt",
        "Transaktioner.txt",
        "json-buffer.cpy",
        "linje-tabel.cpy",
        "fil-spec.cpy",
        "json-spec.cpy"
    ]

    missing = [f for f in files if not Path(f).is_file()]

    if missing:
        print("Missing files:", missing)
        return False
    else:
        print("All files are present.")
        return True

def compile_cobol_main() -> None:

    if not main:
        subprocess.run([
            "cobc",
            "-x",
            "-o",
            "main",
            "main.cob",
            "RemoveDuplicates.cob",
            "TextFileToJson.cob",
            "FilesToJson.cob",
        ])

if check_if_cobol_files() == False:
    sys.exit(0)

compile_cobol_main()

bank_proc = subprocess.run(
    ["./main", "BANK"], capture_output=True, text=True, check=True
)
transaction_proc = subprocess.run(
    ["./main", "TRANSAKTIONER"], capture_output=True, text=True, check=True
)

bank_data = json.loads(bank_proc.stdout)
transaction_data = json.loads(transaction_proc.stdout)

print(json.dumps(bank_data, indent=2, ensure_ascii=False))
print(json.dumps(transaction_data, indent=2, ensure_ascii=False))