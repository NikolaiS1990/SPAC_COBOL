# 🌟Description

This repo contains assignments from taking the COBOL course at Specialisterne Academy.
It does not contain a project.

# 📂 File structure
```text
.
├── LICENSE
├── opgave10
│   ├── banker-strukt.cpy
│   ├── Banker.txt
│   ├── opgave10.cob
│   └── Transaktioner.txt
├── opgave1.cob
├── opgave2.cob
├── opgave3_clean_code.cob
├── opgave3.cob
├── opgave4.cob
├── opgave5
│   ├── KUNDEOPL.cpy
│   └── opgave5.cob
├── opgave6.cob
├── opgave7
│   ├── KundeoplysningerOut.txt
│   ├── Kundeoplysninger.txt
│   └── opgave7.cob
├── opgave8
│   ├── KONTOOPL.cpy
│   ├── KontoOpl.txt
│   ├── KUNDEKONTO.txt
│   └── opgave8.cob
└── README.md
```

# 🛠️ Installation on Linux

## WSL2 installation and VSCodium

Satya Nadella really wants you to use Copilot, and thus getting
VS Code to stop making suggestions can be difficult.
LLMs can be detrimental to learning because trying to [recall
information yourself is crucial](https://pmc.ncbi.nlm.nih.gov/articles/PMC12723506/), and LLMs take that away from you.

Using VSCodium is therefor recommended

In PowerShell, run
```PS
winget install vscodium
```

2. Launch VSCodium and get the extension `Open Remote - WSL` by jeanp413.

Now you can connect to WSL2 to VSCodium, and follow the `Linux installation` guide.


## Linux installation:

1. Check which version of GnuCOBOL is recommended: [https://gnucobol.sourceforge.io/](https://gnucobol.sourceforge.io/)

## Install with apt
1. Check if apt has the recommended version
```bash
apt search gnucobol
```

If it is the correct version, it can be installed with

```bash
sudo apt install gnucobol
```

Verify that you got the correct version by running
```bash
cobc -version
```

## Install with brew
Sometimes brew can have newer versions than apt, so here is how to install gnucobol with brew.

1. Check, for example, Homebrew to see if they have it

```bash
brew info gnucobol
```

If it is the correct version, it can be installed with

```bash
brew install gnucobol
```

Verify that you got the correct version by running

```bash
cobc -version
```

Add the path permanently

```bash
sudo nano ~/.bashrc
```

Scroll down to the bottom and add this line with a comment above it

```text
# Add homebrew GnuCOBOL to path
export LD_LIBRARY_PATH="/home/linuxbrew/.linuxbrew/lib:$LD_LIBRARY_PATH"
```

Refresh the terminal with

```bash
source ~/.bashrc
```

## Install extension for VScode and VScodium

Install the `COBOL` extension from `bitlang`

Go to the gear icon in the bottom left corner, select `settings`, search for `coboleditor.intellisense_style`, and select `UPPERCASE`

# 🛠️ Prep your local environment
Create the dist folder
```bash
mkdir dist
```

# ⚙️ Compilation and Execution
Now you are ready to code and compile scripts.

Compile script

```bash
cobc -x Hello.cob
```

Add the `-fixed` flag if it needs to comply with column rules. You can also add `-free` if you are writing modern COBOL and columns do not matter.

Run the compiled file

```bash
./Hello
```

If you want the compiled code to be placed in a specific folder, you can run

```bash
cobc -x Hello.cob -o dist/Hello
./dist/Hello
```

# 📜 License

The code is licensed under the MIT License