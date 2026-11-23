import subprocess
import json
import sys
from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from pathlib import Path
from reportlab.pdfbase.pdfmetrics import stringWidth

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
        konto_id = transaction.pop("konto_id")
        if cpr not in grouped_transactions:
            grouped_transactions[cpr] = {}
        if konto_id not in grouped_transactions[cpr]:
            grouped_transactions[cpr][konto_id] = []
        grouped_transactions[cpr][konto_id].append(transaction)

    return grouped_transactions


def generate_pdf(cpr: str, konto_id: str, transactions: list, customer_info: dict, bank_info: dict):
    """Generate a PDF bank statement for one account."""
    cpr_dir = Path("bank_statements") / cpr
    cpr_dir.mkdir(parents=True, exist_ok=True)
    pdf_path = cpr_dir / f"{konto_id}.pdf"

    doc = SimpleDocTemplate(str(pdf_path), pagesize=A4, leftMargin=15*mm, rightMargin=15*mm, topMargin=10*mm, bottomMargin=10*mm)
    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph("Kontoudskrift", styles['Title']))


    elements.append(Spacer(1, 5*mm))

    # Customer block (left)
    elements.append(Paragraph(f"Kunde: {customer_info.get('navn', 'N/A')}", styles['Normal']))
    elements.append(Paragraph(f"Adresse: {customer_info.get('adresse', 'N/A')}", styles['Normal']))
    elements.append(Spacer(1, 10*mm))

    # Bank block (right side of page, text left-aligned inside it)
    bank_lines = [
        f"Registreringsnummer: {customer_info.get('reg_nr', 'N/A')}",
        f"Bank: {bank_info.get('banknavn', 'N/A')}",
        f"Bankadresse: {bank_info.get('adresse', 'N/A')}",
        f"Telefon: {bank_info.get('telefon', 'N/A')}",
        f"E-mail: {bank_info.get('email', 'N/A')}",
    ]

    font = styles['Normal'].fontName
    size = styles['Normal'].fontSize
    block_width = max(stringWidth(line, font, size) for line in bank_lines) + 2

    bank_block = Table(
        [[Paragraph("<br/>".join(bank_lines), styles['Normal'])]],
        colWidths=[block_width],
        hAlign='RIGHT',
    )

    bank_block.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),   # text starts at the same x on every line
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('TOPPADDING', (0, 0), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ]))
    elements.append(bank_block)
    elements.append(Spacer(1, 10*mm))

    bold = ParagraphStyle('Bold', parent=styles['Normal'], fontName='Helvetica-Bold')
    elements.append(Paragraph(f"Kontoudskrift for kontonr.: {konto_id}", bold))
    elements.append(Spacer(1, 5*mm))

    header_data = [["Dato", "Tidspunkt", "Transaktionstype", "Beløb (DKK)", "Beløb (valuta)", "Valutakode", "Butik"]]
    header_table = Table(header_data, colWidths=[25*mm, 30*mm, 30*mm, 25*mm, 25*mm, 20*mm, 30*mm])
    header_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.lightgrey]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    elements.append(header_table)

    total_indbetalt = 0
    total_udbetalt = 0

    # Currency conversion rates
    conversion_rates = {'USD': 6.8, 'EUR': 7.5, 'DKK': 1}

    for transaction in transactions:
        belob = transaction.get('beløb', 0)
        valuta = transaction.get('valuta', '')
        tidspunkt = transaction.get('tidspunkt', '')
        dato = tidspunkt[:10] if tidspunkt else ''
        tid = tidspunkt[11:19] if len(tidspunkt) > 19 else ''

        # Convert to DKK
        rate = conversion_rates.get(valuta, 1)
        belob_dkk = belob * rate

        if belob_dkk > 0:
            total_indbetalt += belob_dkk
            belob_str = f"{belob_dkk:,.2f}"
        else:
            total_udbetalt += abs(belob_dkk)
            belob_str = f"-{abs(belob_dkk):,.2f}"

        row = [dato, tid, transaction.get('transaktionstype', ''), belob_str, f"{abs(belob):,.2f}" if belob != 0 else '', valuta, transaction.get('butik', '')]
        row_table = Table([row], colWidths=[25*mm, 30*mm, 30*mm, 25*mm, 25*mm, 20*mm, 30*mm])
        row_table.setStyle(TableStyle([
            ('GRID', (0, 0), (-1, 0), 0.5, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('ALIGN', (3, 0), (3, 0), 'RIGHT'),
            ('ALIGN', (4, 0), (4, 0), 'RIGHT'),
        ]))
        elements.append(row_table)

    elements.append(Spacer(1, 5*mm))
    saldo = 50000 + total_indbetalt - total_udbetalt
    elements.append(Paragraph(f"Totalt indbetalt (DKK): {total_indbetalt:,.2f}", styles['Normal']))
    elements.append(Paragraph(f"Totalt udbetalt (DKK): -{total_udbetalt:,.2f}", styles['Normal']))
    elements.append(Paragraph(f"Saldo (DKK): {saldo:,.2f}", styles['Normal']))
    elements.append(Spacer(1, 10*mm))
    elements.append(Paragraph("Med venlig hilsen", styles['Normal']))
    elements.append(Paragraph(f"{bank_info.get('banknavn', 'N/A')}", styles['Normal']))

    doc.build(elements)
    print(f"  Generated: {pdf_path}")


def build_bank_statement_text(grouped_transactions: dict, bank_data: dict):

    cpr_customer_info = {}

    for cpr, accounts in grouped_transactions.items():
        first_konto = next(iter(accounts.values()), [])
        if first_konto:
            first = first_konto[0]
            cpr_customer_info[cpr] = {
                'navn': first.get('navn', 'N/A'),
                'adresse': first.get('adresse', 'N/A'),
                'reg_nr': first.get('reg_nr', 'N/A')
            }

    Path("bank_statements").mkdir(exist_ok=True)

    for cpr, accounts in grouped_transactions.items():
        print(f"\nProcessing CPR: {cpr}")
        for konto_id, transactions in accounts.items():
            customer_info = cpr_customer_info.get(cpr, {})
            reg_nr = customer_info.get('reg_nr', '')
            bank_info = {}
            if bank_data and 'banker' in bank_data and reg_nr in bank_data['banker']:
                bank_info = bank_data['banker'][reg_nr]
            generate_pdf(cpr, konto_id, transactions, customer_info, bank_info)

    print("\nAll bank statements generated.")


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
