# ScoopManager

A simple interactive command-line tool for installing and managing packages and buckets
for the [Scoop](https://scoop.sh) package manager.

## Features

- **Curated package list** — browse and multi-select from a pre-built list of packages.  
- **Bucket manager** — add, update, or remove buckets.
- **Update & remove** — Upgrade or uninstall packages by name or all at once.
- **Fuzzy search** — search the full Scoop package index interactively with `fzf`.
- **Faster downloads** — offers to configure [aria2](https://aria2.github.io/) for
  multi-connection downloads, giving noticeably faster install/update times.

## Requirements

- PowerShell latest version or Windows PowerShell 5.1
- Git is required for Scoop to add/update buckets 
- Everything else (aria2, fzf, scoop-search) is optional but recommended.

## Usage

1. Clone the repository:
   ```cmd
   git clone https://github.com/abderrahmane-707/ScoopManager.git
   ```
2. Double-click `ScoopManager.bat`.
