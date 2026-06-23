"""
erpnext/security_erp/security_erp/security_erp/doctype/passport_client_release/passport_client_release.py

FIX 2.6: Restore before_insert method.

ANALYSIS:
- cpython-311 .pyc (from Docker container) contained before_insert()
- Current .py has only `pass` — method was lost during Python 3.11→3.12 migration
- DocType purpose: "Passport Client Release" — tracks client release of Object Passport
- Related: Installation Act creates Passport Client Release on submit
- Fields (from .json): passport, client, release_date, excludes_credentials (always=1),
  signature, release_method, notes, status

before_insert logic (reconstructed from context + BUILD_LOG R7 notes):
- Set release_date to today if not provided
- Ensure excludes_credentials is always 1 (security requirement — client version never has creds)
- Auto-set name prefix based on passport name
"""

import frappe
from frappe.model.document import Document


class PassportClientRelease(Document):

    def before_insert(self):
        # Enforce security requirement: client release NEVER contains credentials
        # (audit trail: this is always True, not configurable)
        self.excludes_credentials = 1

        # Default release date to today
        if not self.release_date:
            self.release_date = frappe.utils.today()

        # Link to Object Passport if not set but passport_name provided
        if not self.passport and self.get("passport_name"):
            self.passport = self.passport_name

    def validate(self):
        # Ensure credentials exclusion is immutable
        if not self.excludes_credentials:
            frappe.throw(
                "Passport Client Release завжди повинен мати excludes_credentials = 1. "
                "Клієнтська версія паспорту не може містити облікові дані.",
                title="Security Violation",
            )

        # Ensure linked passport exists
        if self.passport and not frappe.db.exists("Object Passport", self.passport):
            frappe.throw(f"Object Passport '{self.passport}' не знайдено.")
