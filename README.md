Here is the English translation of the text:

# Installation on Linux

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

Install the `COBOL` extension from `bitlang`

Go to the gear icon in the bottom left corner, select `settings`, search for `coboleditor.intellisense_style`, and select `UPPERCASE`

# Compilation and Execution

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
