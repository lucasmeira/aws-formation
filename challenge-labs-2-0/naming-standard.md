# Naming Standard

## Folder naming
- Use lowercase `kebab-case` for all folders.
- Use `YYYY-MM` for single-month periods.
- Use `YYYY-MM-to-YYYY-MM` for merged periods.
- Add a topic suffix only when an official theme exists.

Examples:
- `2025-11`
- `2025-12-to-2026-01`
- `2026-02-performance-security-finops`

## Challenge file naming
- Use one file per challenge.
- Format: `challenge-<nn>-<topic-slug>.md`
- Numbering is mandatory with two digits (`01` to `06`).

Examples:
- `challenge-01-ecs-efs-cdn.md`
- `challenge-02-systems-manager-ecs.md`
- `challenge-06-cloudfront-alb-vpc-origin.md`

## Scripts and supporting files
- Keep short, one-off command snippets in the challenge markdown file.
- Use script files for runnable or reusable commands.
- If a challenge has more than one supporting file, create a companion folder:
  `challenge-<nn>-<topic-slug>/`
- Store Terraform files in `terraform/` inside that companion folder (when applicable).
- Store helper scripts in `scripts/` inside that companion folder.

Example:
- `challenge-01-aws-cli-sts-ec2-s3-kirocli.md`
- `challenge-01-aws-cli-sts-ec2-s3-kirocli/scripts/01-get-session-token.sh`
- `challenge-01-aws-cli-sts-ec2-s3-kirocli/scripts/02-assume-role.sh`
- `challenge-02-terraform-ec2/terraform/main.tf`

## Summary file naming
- Each period folder includes `summary.md`.

## Asset naming (PDF/PPT/etc.)
- Format: `dl2-<period-key>-c<nn>-<topic-slug>.<ext>`
- Filename title (without extension) must be at most 58 characters.

Example:
- `dl2-2025-12-to-2026-01-c05-lambda-sam.pdf`

## Slug rules
- Lowercase only.
- Use `-` between words.
- No spaces, accents, or symbols.
- Replace `+` with `-`.
- Keep AWS acronyms in lowercase in slugs (`ecs`, `waf`, `alb`).

## Migration map
- `FormacaoAWS/DesafioLabs 2.0` -> `formation-aws/challenge-labs-2-0`
- `NOV/25` -> `2025-11`
- `DEZ/25|JAN/26` -> `2025-12-to-2026-01`
- `FEV/26` -> `2026-02-performance-security-finops`
- `MAR/27` -> `2027-03`
- `DesafioLab 2.0-DEZ25JAN26-05-Lambda e SAM.pdf` -> `dl2-2025-12-to-2026-01-c05-lambda-sam.pdf`
- `march-2026/challange-01-march-2026.md` -> `2026-03/challenge-01-aws-cli-sts-ec2-s3-kirocli.md`

## Validation checklist
- Lexical sorting keeps periods in chronological order.
- Period folders include `summary.md`.
- Challenge files follow the naming pattern.
- Terraform files (when present) are kept under `challenge-<nn>-<topic-slug>/terraform/`.
- Script files (when present) are kept under `challenge-<nn>-<topic-slug>/scripts/`.
- No duplicated challenge numbers in the same period.
- Challenge number and topic meaning are preserved after migration.
