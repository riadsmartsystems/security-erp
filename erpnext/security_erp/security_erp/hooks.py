app_name = "security_erp"
app_title = "Security ERP"
app_publisher = "Riad Smart Systems"
app_description = "Security ERP Platform customizations"
app_email = "info@riad.fun"
app_license = "mit"

# --------------------------------------------------------------------------
# Includes
# --------------------------------------------------------------------------

app_include_css = "/assets/security_erp/css/security_erp.css"
app_include_js = "/assets/security_erp/js/security_erp.js"

# --------------------------------------------------------------------------
# Installation
# --------------------------------------------------------------------------

after_install = "security_erp.events.after_install"

# --------------------------------------------------------------------------
# Document Events
# --------------------------------------------------------------------------

doc_events = {
    "Address": {
        "validate": "security_erp.events.address_validate",
    },
    "Lead": {
        "on_update": "security_erp.events.lead_on_update",
    },
    "Customer": {
        "after_insert": "security_erp.events.customer_after_insert",
    },
    "Quotation": {
        "on_update": "security_erp.events.quotation_on_update",
    },
    "Sales Order": {
        "on_update": "security_erp.events.sales_order_on_update",
    },
    "Project": {
        "on_update": "security_erp.events.project_on_update",
    },
    "Service Ticket": {
        "on_update": "security_erp.events.ticket_on_update",
        "after_insert": "security_erp.events.ticket_after_insert",
    },
}

# --------------------------------------------------------------------------
# Scheduled Tasks
# --------------------------------------------------------------------------

scheduler_events = {
    "daily": [
        "security_erp.tasks.daily.check_warranty_expiry",
        "security_erp.tasks.daily.check_sla_compliance",
    ],
    "hourly": [
        "security_erp.tasks.hourly.check_sla_breaches",
    ],
}

# --------------------------------------------------------------------------
# RQ Jobs (A3: Whisper + AI Estimate)
# --------------------------------------------------------------------------

doc_events["Media Asset"] = {
    "after_insert": "security_erp.tasks.transcribe.on_media_asset_insert",
}

# --------------------------------------------------------------------------
# Override DocType Class
# --------------------------------------------------------------------------

override_doctype_class = {
    "Address": "security_erp.overrides.CustomAddress",
}

# --------------------------------------------------------------------------
# Permissions
# --------------------------------------------------------------------------

has_permission = {
    "Contract": "security_erp.permissions.contract_has_permission",
}

# --------------------------------------------------------------------------
# Fixtures (exported on `bench export-fixtures`)
# --------------------------------------------------------------------------

fixtures = [
    {"dt": "Custom Field", "filters": [["module", "=", "Security ERP"]]},
    {"dt": "Property Setter", "filters": [["module", "=", "Security ERP"]]},
    {"dt": "Workspace", "filters": [["module", "=", "Security ERP"]]},
    {"dt": "Print Format", "filters": [["module", "=", "Security ERP"]]},
    {"dt": "Client Script", "filters": [["module", "=", "Security ERP"]]},
    {"dt": "Role Profile"},
    {"dt": "Security Scenario"},
    {"dt": "Security Scenario Item"},
]

# --------------------------------------------------------------------------
# Jinja
# --------------------------------------------------------------------------

jinja = {
    "methods": [
        "security_erp.jinja_methods.get_sla_status",
    ],
}

# --------------------------------------------------------------------------
# Translation
# --------------------------------------------------------------------------

# setup_source_parsers = {
#     "py": "security_erp.source_parsers.get_translations",
# }
