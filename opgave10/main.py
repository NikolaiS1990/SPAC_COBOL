import subprocess
import json
import sys
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


def get_jsons() -> list:

    bank_proc = subprocess.run(
        ["./main", "BANK"], capture_output=True, text=True, check=True
    )
    transaction_proc = subprocess.run(
        ["./main", "TRANSAKTIONER"], capture_output=True, text=True, check=True
    )

    bank_data = json.loads(bank_proc.stdout)
    transaction_data = json.loads(transaction_proc.stdout)


    list_of_jsons = [bank_data, transaction_data]

    return list_of_jsons

def group_transaction_pr_cpr_number(json: dict) -> dict:

    data = json["transaktioner"]

    grouped_transactions = {}

    for transaction in data:
        cpr = transaction.pop("cpr")
        if cpr not in grouped_transactions:
            grouped_transactions[cpr] = []
        grouped_transactions[cpr].append(transaction)

    return grouped_transactions


def build_bank_statement_text(grouped_transactions: dict, bank_data: dict):

    cpr_account_ids_transactions = {}

    for cpr, transactions in grouped_transactions.items():
        cpr_account_ids_transactions[cpr] = {}
        for transaction in transactions:
            konto_id = transaction.pop("konto_id")
            cpr_account_ids_transactions[cpr][konto_id] = transaction

    print(json.dumps(cpr_account_ids_transactions, indent=2, ensure_ascii=False))








def run_app() -> None:

    if not check_if_cobol_files():
        sys.exit(1)

    compile_cobol_main()

    lists_of_jsons = get_jsons()

    bank_json = lists_of_jsons[0]
    transaction_json = lists_of_jsons[1]
    

    grouped_transactions = group_transaction_pr_cpr_number(transaction_json)

    build_bank_statement_text(grouped_transactions, bank_json)


run_app()
