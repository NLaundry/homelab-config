# Age custody bootstrap

Date: 2026-09-05

Result: PASS.

- The operator age identity exists outside the repository at the conventional SOPS path.
- Its independently held recovery copy is stored as an encrypted attachment in Bitwarden.
- The retrieved recovery copy produced the same public recipient as the working identity.
- No private identity material was recorded in change evidence.

Public recipient:

```text
age1ppln4es2zdwhk2rjdfv848dckh9nd5c58t39m4345pjmnads9cksg48dsu
```
