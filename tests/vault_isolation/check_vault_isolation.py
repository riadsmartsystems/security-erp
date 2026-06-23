"""Vault isolation linter — CI gate for V2.

Scans 7 restricted paths for any import of security_erp.vault modules.
Exit code 1 if any violation found.

Run: python tests/vault_isolation/check_vault_isolation.py
"""

import ast
import sys
from pathlib import Path

RESTRICTED_PATHS = [
    "services/security-api/",
    "erpnext/security_erp/security_erp/doctype/ai_provider/",
    "erpnext/security_erp/security_erp/doctype/ai_request_log/",
    "erpnext/security_erp/security_erp/doctype/ai_estimate/",
    "erpnext/security_erp/security_erp/doctype/remote_inspection/",
    "erpnext/security_erp/security_erp/doctype/site_brief/",
    "erpnext/security_erp/security_erp/tasks/",
]

VAULT_IMPORT_NAMES = [
    "security_erp.vault",
    "security_erp.vault._crypto",
    "security_erp.vault._hooks",
    "security_erp.vault._key",
    "security_erp.vault.api",
    "security_erp.vault.audit",
    "security_erp.vault.mfa",
    "security_erp.vault.act",
]


def _check_file(filepath: Path) -> list[str]:
    """Check a single Python file for vault imports. Returns list of violations."""
    violations = []
    try:
        source = filepath.read_text(encoding="utf-8")
        tree = ast.parse(source, filename=str(filepath))
    except (SyntaxError, UnicodeDecodeError):
        return violations

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if any(alias.name.startswith(v) for v in VAULT_IMPORT_NAMES):
                    violations.append(
                        f"{filepath}:{node.lineno}: import {alias.name}"
                    )

        elif isinstance(node, ast.ImportFrom):
            module = node.module or ""
            if any(module.startswith(v) for v in VAULT_IMPORT_NAMES):
                violations.append(
                    f"{filepath}:{node.lineno}: from {module} import ..."
                )

    return violations


def main():
    root = Path(__file__).resolve().parent.parent.parent
    all_violations = []
    files_scanned = 0

    for restricted in RESTRICTED_PATHS:
        restricted_dir = root / restricted
        if not restricted_dir.exists():
            continue
        for py_file in restricted_dir.rglob("*.py"):
            if py_file.name == "__pycache__":
                continue
            files_scanned += 1
            violations = _check_file(py_file)
            all_violations.extend(violations)

    if all_violations:
        print("FAIL: Vault import violations found:")
        for v in all_violations:
            print(f"  {v}")
        print(f"\n{len(all_violations)} violation(s) in {files_scanned} files scanned across {len(RESTRICTED_PATHS)} restricted paths.")
        sys.exit(1)

    print(f"OK: {files_scanned} files scanned across {len(RESTRICTED_PATHS)} restricted paths")
    sys.exit(0)


if __name__ == "__main__":
    main()
