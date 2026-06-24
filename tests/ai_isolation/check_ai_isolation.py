"""AI↔Vault isolation linter — checks that AI code never imports vault modules.

Scans security_erp/ai/ and services/security-api/ for forbidden imports of
security_erp.vault.* or relative vault imports. Exit code 1 if violations found.
"""

import ast
import pathlib
import sys

SCAN_PATHS = [
    "erpnext/security_erp/security_erp/ai",
    "erpnext/security_erp/security_erp/tasks",
    "services/security-api",
    "services/whisper",
]

RELATIVE_VAULT = {"vault", "_crypto", "_hooks", "_key", "audit", "mfa", "act", "api"}


def _check_file(filepath: pathlib.Path) -> list[str]:
    errors = []
    try:
        tree = ast.parse(filepath.read_text(), filename=str(filepath))
    except SyntaxError:
        return []

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name.startswith("security_erp.vault"):
                    errors.append(f"{filepath}:{node.lineno}: import {alias.name}")
        elif isinstance(node, ast.ImportFrom):
            if node.module and node.module.startswith("security_erp.vault"):
                errors.append(f"{filepath}:{node.lineno}: from {node.module} import ...")
            if node.level and node.module and node.module in RELATIVE_VAULT:
                errors.append(f"{filepath}:{node.lineno}: from .{node.module} import ...")

    return errors


def main():
    all_errors: list[str] = []
    files_scanned = 0
    root = pathlib.Path(".")

    for scan_path in SCAN_PATHS:
        for filepath in root.glob(f"{scan_path}/**/*.py"):
            files_scanned += 1
            all_errors.extend(_check_file(filepath))

    if all_errors:
        print("FAIL: AI↔Vault isolation violations found:")
        for e in all_errors:
            print(f"  {e}")
        sys.exit(1)

    print(f"OK: {files_scanned} files scanned across {len(SCAN_PATHS)} restricted paths — no vault imports")


if __name__ == "__main__":
    main()
