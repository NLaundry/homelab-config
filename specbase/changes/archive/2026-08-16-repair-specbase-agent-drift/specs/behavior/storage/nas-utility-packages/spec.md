---
id: behavior.storage.nas-utility-packages
---

## Purpose

This pair preserves the small baseline of interactive utility programs expected to be enabled in the evaluated NAS configuration.

## MODIFIED Requirements

### Requirement: vim and git are enabled on the NAS
**ID:** `utility-packages-enabled`
The NAS configuration SHALL enable `vim` and `git` on the box via their
respective NixOS program options.

#### Scenario: vim and git are enabled
**ID:** `vim-git-enabled`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `programs.vim.enable` is `true`
- **AND** `programs.git.enable` is `true`
