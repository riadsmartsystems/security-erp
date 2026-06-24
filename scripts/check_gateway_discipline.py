"""
CI script: scan app/routes/*.py for direct frappe_* calls (gateway discipline).

Gateway discipline rule: route files must NOT call frappe_get/post/put/delete
directly — all Frappe I/O must go through the service layer.

Exit code:
  0 — no unexpected violations (KNOWN_PENDING files are OK)
  1 — unexpected violation found (regression guard triggered)

Output format:
  [OK]        visits.py    — no direct frappe_* calls
  [TODO]      serial.py    — known pending refactor (FIX-7)
  [VIOLATION] bad.py       — unexpected frappe_get — move to service layer

Usage:
  python scripts/check_gateway_discipline.py
"""
import pathlib
import sys

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Fully excluded: these files legitimately call frappe_* for system reasons.
# act.py  / vault.py  — vault isolation track (separate CI gate already exists)
# auth.py             — session/login flow — direct Frappe SID exchange
# proxy.py            — legacy /api/v1 pass-through
# doctypes.py         — settings CRUD, excluded per FIX-6 scope
EXCLUDED = frozenset({"act.py", "vault.py", "auth.py", "proxy.py", "doctypes.py"})

# Known pending: these still have frappe_* calls but are scheduled for FIX-7.
# Reported as [TODO], but do NOT fail CI (not a regression — pre-existing).
KNOWN_PENDING = frozenset({"serial.py", "scenarios.py"})

# Forbidden patterns in general route files
FRAPPE_PATTERNS = ("frappe_get", "frappe_post", "frappe_put", "frappe_delete")

# ai.py special case: frappe_post to the Frappe @whitelist endpoint is the
# documented Administrator whitelist pattern (thin proxy, same as vault.py).
# frappe_get / frappe_put / frappe_delete are still forbidden there.
_AI_FORBIDDEN = ("frappe_get", "frappe_put", "frappe_delete")


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------


def check_file(filename: str, content: str) -> tuple:
    """
    Classify one route file for gateway discipline.

    Returns (status, reason):
      "EXCLUDED"  — file is exempt
      "TODO"      — known pending refactor, not a regression
      "OK"        — no violations
      "VIOLATION" — unexpected direct frappe_* call
    """
    if filename in EXCLUDED:
        return "EXCLUDED", "system/vault file — excluded from gateway discipline check"

    if filename in KNOWN_PENDING:
        return "TODO", "known pending refactor (FIX-7)"

    if filename == "ai.py":
        # frappe_post to security_erp.ai.api.execute_ai is the Administrator
        # whitelist pattern (documented in routes/ai.py header). Allowed.
        # frappe_get/put/delete remain forbidden even in ai.py.
        violations = [p for p in _AI_FORBIDDEN if p in content]
        if violations:
            return (
                "VIOLATION",
                f"unexpected {', '.join(violations)} in ai.py "
                f"(only frappe_post to whitelist allowed — Administrator pattern)",
            )
        return "OK", "only allowed frappe_post (Administrator whitelist pattern, documented)"

    violations = [p for p in FRAPPE_PATTERNS if p in content]
    if violations:
        return (
            "VIOLATION",
            f"unexpected {', '.join(violations)} — move to service layer",
        )

    return "OK", "no direct frappe_* calls"


def scan_routes(routes_dir: str) -> list:
    """
    Scan all *.py files in routes_dir (skipping __init__.py).

    Returns list of (filename, status, reason) tuples, sorted by filename.
    """
    results = []
    for path in sorted(pathlib.Path(routes_dir).glob("*.py")):
        filename = path.name
        if filename == "__init__.py":
            continue
        content = path.read_text(encoding="utf-8")
        status, reason = check_file(filename, content)
        results.append((filename, status, reason))
    return results


def main(routes_dir: str = None) -> int:
    """
    Run the gateway discipline check and print results.

    Returns 0 if no unexpected violations, 1 if a regression is detected.
    """
    if routes_dir is None:
        routes_dir = str(
            pathlib.Path(__file__).parent.parent
            / "services"
            / "security-api"
            / "app"
            / "routes"
        )

    results = scan_routes(routes_dir)
    has_violations = False

    for filename, status, reason in results:
        if status == "EXCLUDED":
            pass  # Silent — excluded files don't clutter output
        elif status == "OK":
            print(f"[OK]        {filename} — {reason}")
        elif status == "TODO":
            print(f"[TODO]      {filename} — {reason}")
        elif status == "VIOLATION":
            print(f"[VIOLATION] {filename} — {reason}")
            has_violations = True

    print()
    if has_violations:
        print("FAIL: unexpected frappe_* violations found — gateway discipline regression")
        return 1

    print("OK: gateway discipline maintained  (serial.py + scenarios.py pending FIX-7)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
