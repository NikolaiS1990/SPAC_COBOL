"""Generate PDF bank statements from fixed-width text files.

This module reads Danish bank transaction data produced by COBOL programs
(fixed-width text files converted to JSON), groups transactions by customer
(CPR number) and account (konto_id), and generates individual PDF bank
statements using ReportLab.

Workflow
--------
1. Verify required COBOL source and data files exist.
2. Compile the COBOL programs (``main.cob``, ``RemoveDuplicates.cob``,
   ``TextFileToJson.cob``, ``FilesToJson.cob``) into a single executable.
3. Run the executable with ``BANK`` and ``TRANSAKTIONER`` arguments to
   obtain JSON data for banks and transactions.
4. Group transactions by CPR number and konto_id.
5. For every account, generate a PDF statement that includes customer info,
   bank info, a transaction table with DKK conversion, and running totals.

Usage
-----
    >>> from main import BankStatementGenerator
    >>> generator = BankStatementGenerator()
    >>> generator.run()
"""

import subprocess
import json
import sys
from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfbase.pdfmetrics import stringWidth


class BankStatementGenerator:
    """Orchestrate the full bank-statement generation pipeline.

    Reads JSON data produced by COBOL programs, groups transactions by
    customer and account, and generates one PDF bank statement per account.

    Attributes
    ----------
    base_dir : Path
        Root directory containing COBOL sources, data files, and output.
    bank_data : dict | None
        Parsed JSON from ``./main BANK`` — keyed by registration number.
    transaction_data : dict | None
        Parsed JSON from ``./main TRANSAKTIONER`` — contains a list of
        transaction objects.
    grouped_transactions : dict | None
        Transactions grouped as ``{cpr: {konto_id: [transactions]}}``.
    """

    REQUIRED_FILES = [
        "main.cob",
        "RemoveDuplicates.cob",
        "TextFileToJson.cob",
        "FilesToJson.cob",
        "Banker.txt",
        "Transaktioner.txt",
        "json-buffer.cpy",
        "linje-tabel.cpy",
        "fil-spec.cpy",
        "json-spec.cpy",
    ]

    CONVERSION_RATES = {"USD": 6.8, "EUR": 7.5, "DKK": 1}

    def __init__(self, base_dir: str = "."):
        """Initialize the generator.

        Parameters
        ----------
        base_dir : str, optional
            Directory containing source files and where output will be
            written. Defaults to the current directory.
        """
        self.base_dir = Path(base_dir)
        self.bank_data = None
        self.transaction_data = None
        self.grouped_transactions = None

    # ── File & build helpers ──────────────────────────────────────────

    def check_files(self) -> bool:
        """Verify that all required COBOL source and data files exist.

        Returns
        -------
        bool
            ``True`` if every file in :attr:`REQUIRED_FILES` is present,
            ``False`` otherwise (missing files are printed to stdout).
        """
        missing = [
            f for f in self.REQUIRED_FILES if not (self.base_dir / f).is_file()
        ]
        if missing:
            print("Missing files:", missing)
            return False
        print("All files are present.")
        return True

    def compile_cobol(self) -> None:
        """Compile COBOL source files into the ``main`` executable.

        Skips compilation if the ``main`` binary already exists in
        :attr:`base_dir`.

        Raises
        ------
        subprocess.CalledProcessError
            If the ``cobc`` compiler fails.
        """
        main_exe = self.base_dir / "main"
        if main_exe.is_file():
            return
        subprocess.run(
            [
                "cobc",
                "-x",
                "-o",
                str(main_exe),
                "main.cob",
                "RemoveDuplicates.cob",
                "TextFileToJson.cob",
                "FilesToJson.cob",
            ],
            check=True,
        )

    # ── JSON data loading ─────────────────────────────────────────────

    def load_jsons(self) -> None:
        """Run the COBOL binary and parse BANK and TRANSAKTIONER JSON.

        Executes ``./main BANK`` and ``./main TRANSAKTIONER``, then parses
        the stdout into :attr:`bank_data` and :attr:`transaction_data`.

        Raises
        ------
        subprocess.CalledProcessError
            If the COBOL binary exits with a non-zero status.
        json.JSONDecodeError
            If the COBOL output is not valid JSON.
        """
        bank_proc = subprocess.run(
            ["./main", "BANK"], capture_output=True, text=True, check=True
        )
        transaction_proc = subprocess.run(
            ["./main", "TRANSAKTIONER"], capture_output=True, text=True, check=True
        )
        self.bank_data = json.loads(bank_proc.stdout)
        self.transaction_data = json.loads(transaction_proc.stdout)

    # ── Transaction grouping ──────────────────────────────────────────

    @staticmethod
    def group_transactions(transactions: dict) -> dict:
        """Group transactions by CPR number, then by konto_id.

        Parameters
        ----------
        transactions : dict
            The ``transaktioner`` JSON object containing a ``"transaktioner"``
            key with a list of transaction dicts.

        Returns
        -------
        dict
            Nested mapping ``{cpr: {konto_id: [transaction, ...], ...}, ...}``.
        """
        data = transactions["transaktioner"]
        grouped = {}
        for transaction in data:
            cpr = transaction.pop("cpr")
            konto_id = transaction.pop("konto_id")
            if cpr not in grouped:
                grouped[cpr] = {}
            if konto_id not in grouped[cpr]:
                grouped[cpr][konto_id] = []
            grouped[cpr][konto_id].append(transaction)
        return grouped

    # ── PDF generation ────────────────────────────────────────────────

    def generate_statement(
        self,
        cpr: str,
        konto_id: str,
        transactions: list,
        customer_info: dict,
        bank_info: dict,
    ) -> None:
        """Generate a single PDF bank statement for one account.

        Creates a ReportLab document containing customer details, bank
        details, a transaction table with currency conversion to DKK,
        and summary totals.

        Parameters
        ----------
        cpr : str
            Customer's CPR number (also used for the output directory name).
        konto_id : str
            Account number (used for the output file name).
        transactions : list[dict]
            Transaction records for this account.
        customer_info : dict
            Customer data with keys ``navn``, ``adresse``, ``reg_nr``.
        bank_info : dict
            Bank data with keys ``banknavn``, ``adresse``, ``telefon``,
            ``email``.

        Side effects
        ------------
        Creates a PDF file at ``bank_statements/<cpr>/<konto_id>.pdf``.
        """
        cpr_dir = self.base_dir / "bank_statements" / cpr
        cpr_dir.mkdir(parents=True, exist_ok=True)
        pdf_path = cpr_dir / f"{konto_id}.pdf"

        doc = SimpleDocTemplate(
            str(pdf_path),
            pagesize=A4,
            leftMargin=15 * mm,
            rightMargin=15 * mm,
            topMargin=10 * mm,
            bottomMargin=10 * mm,
        )
        styles = getSampleStyleSheet()
        elements = []

        elements.append(Paragraph("Kontoudskrift", styles["Title"]))
        elements.append(Spacer(1, 5 * mm))

        # Customer block (left)
        elements.append(
            Paragraph(
                f"Kunde: {customer_info.get('navn', 'N/A')}", styles["Normal"]
            )
        )
        elements.append(
            Paragraph(
                f"Adresse: {customer_info.get('adresse', 'N/A')}",
                styles["Normal"],
            )
        )
        elements.append(Spacer(1, 10 * mm))

        # Bank block (right side of page)
        bank_lines = [
            f"Registreringsnummer: {customer_info.get('reg_nr', 'N/A')}",
            f"Bank: {bank_info.get('banknavn', 'N/A')}",
            f"Bankadresse: {bank_info.get('adresse', 'N/A')}",
            f"Telefon: {bank_info.get('telefon', 'N/A')}",
            f"E-mail: {bank_info.get('email', 'N/A')}",
        ]

        font = styles["Normal"].fontName
        size = styles["Normal"].fontSize
        block_width = (
            max(stringWidth(line, font, size) for line in bank_lines) + 2
        )

        bank_block = Table(
            [[Paragraph("<br/>".join(bank_lines), styles["Normal"])]],
            colWidths=[block_width],
            hAlign="RIGHT",
        )
        bank_block.setStyle(
            TableStyle(
                [
                    ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 0),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                    ("TOPPADDING", (0, 0), (-1, -1), 0),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
                ]
            )
        )
        elements.append(bank_block)
        elements.append(Spacer(1, 10 * mm))

        bold = ParagraphStyle(
            "Bold", parent=styles["Normal"], fontName="Helvetica-Bold"
        )
        elements.append(
            Paragraph(
                f"Kontoudskrift for kontonr.: {konto_id}", bold
            )
        )
        elements.append(Spacer(1, 5 * mm))

        # Transaction table header
        header_data = [
            [
                "Dato",
                "Tidspunkt",
                "Transaktionstype",
                "Beløb (DKK)",
                "Beløb (valuta)",
                "Valutakode",
                "Butik",
            ]
        ]
        header_table = Table(
            header_data,
            colWidths=[
                25 * mm,
                30 * mm,
                30 * mm,
                25 * mm,
                25 * mm,
                20 * mm,
                30 * mm,
            ],
        )
        header_table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 9),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 8),
                    ("TOPPADDING", (0, 0), (-1, 0), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                    (
                        "ROWBACKGROUNDS",
                        (0, 1),
                        (-1, -1),
                        [colors.white, colors.lightgrey],
                    ),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ]
            )
        )
        elements.append(header_table)

        total_indbetalt = 0
        total_udbetalt = 0

        # Transaction rows
        for transaction in transactions:
            belob = transaction.get("beløb", 0)
            valuta = transaction.get("valuta", "")
            tidspunkt = transaction.get("tidspunkt", "")
            dato = tidspunkt[:10] if tidspunkt else ""
            tid = tidspunkt[11:19] if len(tidspunkt) > 19 else ""

            rate = self.CONVERSION_RATES.get(valuta, 1)
            belob_dkk = belob * rate

            if belob_dkk > 0:
                total_indbetalt += belob_dkk
                belob_str = f"{belob_dkk:,.2f}"
            else:
                total_udbetalt += abs(belob_dkk)
                belob_str = f"-{abs(belob_dkk):,.2f}"

            row = [
                dato,
                tid,
                transaction.get("transaktionstype", ""),
                belob_str,
                f"{abs(belob):,.2f}" if belob != 0 else "",
                valuta,
                transaction.get("butik", ""),
            ]
            row_table = Table(
                [row],
                colWidths=[
                    25 * mm,
                    30 * mm,
                    30 * mm,
                    25 * mm,
                    25 * mm,
                    20 * mm,
                    30 * mm,
                ],
            )
            row_table.setStyle(
                TableStyle(
                    [
                        ("GRID", (0, 0), (-1, 0), 0.5, colors.grey),
                        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                        ("ALIGN", (3, 0), (3, 0), "RIGHT"),
                        ("ALIGN", (4, 0), (4, 0), "RIGHT"),
                    ]
                )
            )
            elements.append(row_table)

        # Totals
        elements.append(Spacer(1, 5 * mm))
        saldo = 50000 + total_indbetalt - total_udbetalt
        elements.append(
            Paragraph(
                f"Totalt indbetalt (DKK): {total_indbetalt:,.2f}",
                styles["Normal"],
            )
        )
        elements.append(
            Paragraph(
                f"Totalt udbetalt (DKK): -{total_udbetalt:,.2f}",
                styles["Normal"],
            )
        )
        elements.append(
            Paragraph(f"Saldo (DKK): {saldo:,.2f}", styles["Normal"])
        )
        elements.append(Spacer(1, 10 * mm))
        elements.append(Paragraph("Med venlig hilsen", styles["Normal"]))
        elements.append(
            Paragraph(
                f"{bank_info.get('banknavn', 'N/A')}", styles["Normal"]
            )
        )

        doc.build(elements)
        print(f"  Generated: {pdf_path}")

    # ── Orchestration ─────────────────────────────────────────────────

    def build_customer_info(self) -> dict:
        """Build a CPR → customer info lookup from grouped transactions.

        Extracts ``navn``, ``adresse``, and ``reg_nr`` from the first
        transaction of each CPR's first account.

        Returns
        -------
        dict
            ``{cpr: {'navn': ..., 'adresse': ..., 'reg_nr': ...}, ...}``
        """
        cpr_customer_info = {}
        for cpr, accounts in self.grouped_transactions.items():
            first_konto = next(iter(accounts.values()), [])
            if first_konto:
                first = first_konto[0]
                cpr_customer_info[cpr] = {
                    "navn": first.get("navn", "N/A"),
                    "adresse": first.get("adresse", "N/A"),
                    "reg_nr": first.get("reg_nr", "N/A"),
                }
        return cpr_customer_info

    def generate_all_statements(self) -> None:
        """Generate PDF statements for every account in the data set.

        Groups transactions, builds the customer info lookup, then iterates
        over every CPR/konto_id combination to produce individual PDFs.

        Side effects
        ------------
        Creates ``bank_statements/<cpr>/<konto_id>.pdf`` for each account.
        """
        self.grouped_transactions = self.group_transactions(
            self.transaction_data
        )
        cpr_customer_info = self.build_customer_info()

        (self.base_dir / "bank_statements").mkdir(exist_ok=True)

        for cpr, accounts in self.grouped_transactions.items():
            print(f"\nProcessing CPR: {cpr}")
            for konto_id, transactions in accounts.items():
                customer_info = cpr_customer_info.get(cpr, {})
                reg_nr = customer_info.get("reg_nr", "")
                bank_info = {}
                if (
                    self.bank_data
                    and "banker" in self.bank_data
                    and reg_nr in self.bank_data["banker"]
                ):
                    bank_info = self.bank_data["banker"][reg_nr]
                self.generate_statement(
                    cpr, konto_id, transactions, customer_info, bank_info
                )

        print("\nAll bank statements generated.")

    # ── Entry point ───────────────────────────────────────────────────

    def run(self) -> None:
        """Execute the full pipeline: check → compile → load → generate.

        1. Verifies all required files.
        2. Compiles COBOL sources (if needed).
        3. Loads bank and transaction JSON data.
        4. Generates PDF statements for every account.
        """
        if not self.check_files():
            sys.exit(1)

        self.compile_cobol()
        self.load_jsons()
        self.generate_all_statements()


if __name__ == "__main__":
    generator = BankStatementGenerator()
    generator.run()
    """Generates PDF bank statements from COBOL-produced JSON data."""

    REQUIRED_FILES = [
        "main.cob",
        "RemoveDuplicates.cob",
        "TextFileToJson.cob",
        "FilesToJson.cob",
        "Banker.txt",
        "Transaktioner.txt",
        "json-buffer.cpy",
        "linje-tabel.cpy",
        "fil-spec.cpy",
        "json-spec.cpy",
    ]

    CONVERSION_RATES = {"USD": 6.8, "EUR": 7.5, "DKK": 1}

    def __init__(self, base_dir: str = "."):
        self.base_dir = Path(base_dir)
        self.bank_data = None
        self.transaction_data = None
        self.grouped_transactions = None

    # ── File & build helpers ──────────────────────────────────────────

    def check_files(self) -> bool:
        """Check that all required COBOL/data files exist."""
        missing = [f for f in self.REQUIRED_FILES if not (self.base_dir / f).is_file()]
        if missing:
            print("Missing files:", missing)
            return False
        print("All files are present.")
        return True

    def compile_cobol(self) -> None:
        """Compile the COBOL programs into the `main` executable."""
        main_exe = self.base_dir / "main"
        if main_exe.is_file():
            return
        subprocess.run(
            [
                "cobc",
                "-x",
                "-o",
                str(main_exe),
                "main.cob",
                "RemoveDuplicates.cob",
                "TextFileToJson.cob",
                "FilesToJson.cob",
            ],
            check=True,
        )

    # ── JSON data loading ─────────────────────────────────────────────

    def load_jsons(self) -> None:
        """Run the COBOL binary for BANK and TRANSAKTIONER and parse JSON."""
        bank_proc = subprocess.run(
            ["./main", "BANK"], capture_output=True, text=True, check=True
        )
        transaction_proc = subprocess.run(
            ["./main", "TRANSAKTIONER"], capture_output=True, text=True, check=True
        )
        self.bank_data = json.loads(bank_proc.stdout)
        self.transaction_data = json.loads(transaction_proc.stdout)

    # ── Transaction grouping ──────────────────────────────────────────

    @staticmethod
    def group_transactions(transactions: dict) -> dict:
        """Group transactions by CPR number, then by konto_id."""
        data = transactions["transaktioner"]
        grouped = {}
        for transaction in data:
            cpr = transaction.pop("cpr")
            konto_id = transaction.pop("konto_id")
            if cpr not in grouped:
                grouped[cpr] = {}
            if konto_id not in grouped[cpr]:
                grouped[cpr][konto_id] = []
            grouped[cpr][konto_id].append(transaction)
        return grouped

    # ── PDF generation ────────────────────────────────────────────────

    def generate_statement(
        self,
        cpr: str,
        konto_id: str,
        transactions: list,
        customer_info: dict,
        bank_info: dict,
    ) -> None:
        """Generate a single PDF bank statement for one account."""
        cpr_dir = self.base_dir / "bank_statements" / cpr
        cpr_dir.mkdir(parents=True, exist_ok=True)
        pdf_path = cpr_dir / f"{konto_id}.pdf"

        doc = SimpleDocTemplate(
            str(pdf_path),
            pagesize=A4,
            leftMargin=15 * mm,
            rightMargin=15 * mm,
            topMargin=10 * mm,
            bottomMargin=10 * mm,
        )
        styles = getSampleStyleSheet()
        elements = []

        elements.append(Paragraph("Kontoudskrift", styles["Title"]))
        elements.append(Spacer(1, 5 * mm))

        # Customer block (left)
        elements.append(
            Paragraph(
                f"Kunde: {customer_info.get('navn', 'N/A')}", styles["Normal"]
            )
        )
        elements.append(
            Paragraph(
                f"Adresse: {customer_info.get('adresse', 'N/A')}", styles["Normal"]
            )
        )
        elements.append(Spacer(1, 10 * mm))

        # Bank block (right side of page)
        bank_lines = [
            f"Registreringsnummer: {customer_info.get('reg_nr', 'N/A')}",
            f"Bank: {bank_info.get('banknavn', 'N/A')}",
            f"Bankadresse: {bank_info.get('adresse', 'N/A')}",
            f"Telefon: {bank_info.get('telefon', 'N/A')}",
            f"E-mail: {bank_info.get('email', 'N/A')}",
        ]

        font = styles["Normal"].fontName
        size = styles["Normal"].fontSize
        block_width = (
            max(stringWidth(line, font, size) for line in bank_lines) + 2
        )

        bank_block = Table(
            [[Paragraph("<br/>".join(bank_lines), styles["Normal"])]],
            colWidths=[block_width],
            hAlign="RIGHT",
        )
        bank_block.setStyle(
            TableStyle(
                [
                    ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 0),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                    ("TOPPADDING", (0, 0), (-1, -1), 0),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
                ]
            )
        )
        elements.append(bank_block)
        elements.append(Spacer(1, 10 * mm))

        bold = ParagraphStyle(
            "Bold", parent=styles["Normal"], fontName="Helvetica-Bold"
        )
        elements.append(
            Paragraph(
                f"Kontoudskrift for kontonr.: {konto_id}", bold
            )
        )
        elements.append(Spacer(1, 5 * mm))

        # Transaction table header
        header_data = [
            [
                "Dato",
                "Tidspunkt",
                "Transaktionstype",
                "Beløb (DKK)",
                "Beløb (valuta)",
                "Valutakode",
                "Butik",
            ]
        ]
        header_table = Table(
            header_data,
            colWidths=[
                25 * mm,
                30 * mm,
                30 * mm,
                25 * mm,
                25 * mm,
                20 * mm,
                30 * mm,
            ],
        )
        header_table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 9),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 8),
                    ("TOPPADDING", (0, 0), (-1, 0), 8),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                    (
                        "ROWBACKGROUNDS",
                        (0, 1),
                        (-1, -1),
                        [colors.white, colors.lightgrey],
                    ),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ]
            )
        )
        elements.append(header_table)

        total_indbetalt = 0
        total_udbetalt = 0

        # Transaction rows
        for transaction in transactions:
            belob = transaction.get("beløb", 0)
            valuta = transaction.get("valuta", "")
            tidspunkt = transaction.get("tidspunkt", "")
            dato = tidspunkt[:10] if tidspunkt else ""
            tid = tidspunkt[11:19] if len(tidspunkt) > 19 else ""

            rate = self.CONVERSION_RATES.get(valuta, 1)
            belob_dkk = belob * rate

            if belob_dkk > 0:
                total_indbetalt += belob_dkk
                belob_str = f"{belob_dkk:,.2f}"
            else:
                total_udbetalt += abs(belob_dkk)
                belob_str = f"-{abs(belob_dkk):,.2f}"

            row = [
                dato,
                tid,
                transaction.get("transaktionstype", ""),
                belob_str,
                f"{abs(belob):,.2f}" if belob != 0 else "",
                valuta,
                transaction.get("butik", ""),
            ]
            row_table = Table(
                [row],
                colWidths=[
                    25 * mm,
                    30 * mm,
                    30 * mm,
                    25 * mm,
                    25 * mm,
                    20 * mm,
                    30 * mm,
                ],
            )
            row_table.setStyle(
                TableStyle(
                    [
                        ("GRID", (0, 0), (-1, 0), 0.5, colors.grey),
                        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                        ("ALIGN", (3, 0), (3, 0), "RIGHT"),
                        ("ALIGN", (4, 0), (4, 0), "RIGHT"),
                    ]
                )
            )
            elements.append(row_table)

        # Totals
        elements.append(Spacer(1, 5 * mm))
        saldo = 50000 + total_indbetalt - total_udbetalt
        elements.append(
            Paragraph(
                f"Totalt indbetalt (DKK): {total_indbetalt:,.2f}", styles["Normal"]
            )
        )
        elements.append(
            Paragraph(
                f"Totalt udbetalt (DKK): -{total_udbetalt:,.2f}", styles["Normal"]
            )
        )
        elements.append(
            Paragraph(f"Saldo (DKK): {saldo:,.2f}", styles["Normal"])
        )
        elements.append(Spacer(1, 10 * mm))
        elements.append(Paragraph("Med venlig hilsen", styles["Normal"]))
        elements.append(
            Paragraph(f"{bank_info.get('banknavn', 'N/A')}", styles["Normal"])
        )

        doc.build(elements)
        print(f"  Generated: {pdf_path}")

    # ── Orchestration ─────────────────────────────────────────────────

    def build_customer_info(self) -> dict:
        """Build a lookup of CPR → customer info from grouped transactions."""
        cpr_customer_info = {}
        for cpr, accounts in self.grouped_transactions.items():
            first_konto = next(iter(accounts.values()), [])
            if first_konto:
                first = first_konto[0]
                cpr_customer_info[cpr] = {
                    "navn": first.get("navn", "N/A"),
                    "adresse": first.get("adresse", "N/A"),
                    "reg_nr": first.get("reg_nr", "N/A"),
                }
        return cpr_customer_info

    def generate_all_statements(self) -> None:
        """Generate PDF statements for every account."""
        self.grouped_transactions = self.group_transactions(
            self.transaction_data
        )
        cpr_customer_info = self.build_customer_info()

        (self.base_dir / "bank_statements").mkdir(exist_ok=True)

        for cpr, accounts in self.grouped_transactions.items():
            print(f"\nProcessing CPR: {cpr}")
            for konto_id, transactions in accounts.items():
                customer_info = cpr_customer_info.get(cpr, {})
                reg_nr = customer_info.get("reg_nr", "")
                bank_info = {}
                if (
                    self.bank_data
                    and "banker" in self.bank_data
                    and reg_nr in self.bank_data["banker"]
                ):
                    bank_info = self.bank_data["banker"][reg_nr]
                self.generate_statement(
                    cpr, konto_id, transactions, customer_info, bank_info
                )

        print("\nAll bank statements generated.")

    # ── Entry point ───────────────────────────────────────────────────

    def run(self) -> None:
        """Full pipeline: check → compile → load → generate."""
        if not self.check_files():
            sys.exit(1)

        self.compile_cobol()
        self.load_jsons()
        self.generate_all_statements()


if __name__ == "__main__":
    generator = BankStatementGenerator()
    generator.run()
