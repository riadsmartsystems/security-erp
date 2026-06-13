import enum


class Role(str, enum.Enum):
    OWNER = "owner"
    DIRECTOR = "director"
    SALES_MANAGER = "sales_manager"
    PROJECT_MANAGER = "project_manager"
    SERVICE_MANAGER = "service_manager"
    ENGINEER = "engineer"
    WAREHOUSE = "warehouse"
    ACCOUNTANT = "accountant"
    VIEWER = "viewer"


class Permission(str, enum.Enum):
    CRM_FULL = "crm_full"
    CRM_READ = "crm_read"
    SALES_FULL = "sales_full"
    SALES_READ = "sales_read"
    PROJECTS_FULL = "projects_full"
    PROJECTS_READ = "projects_read"
    PROJECTS_OWN = "projects_own"
    FSM_FULL = "fsm_full"
    FSM_OWN = "fsm_own"
    CMDB_FULL = "cmdb_full"
    CMDB_READ = "cmdb_read"
    INVENTORY_FULL = "inventory_full"
    INVENTORY_READ = "inventory_read"
    INVENTORY_USE = "inventory_use"
    FINANCE_FULL = "finance_full"
    FINANCE_READ = "finance_read"
    AI_FULL = "ai_full"
    AI_LIMITED = "ai_limited"
    AI_OWN = "ai_own"


ROLE_PERMISSIONS: dict[Role, set[Permission]] = {
    Role.OWNER: {p for p in Permission},
    Role.DIRECTOR: {
        Permission.CRM_READ, Permission.SALES_READ,
        Permission.PROJECTS_FULL, Permission.PROJECTS_READ,
        Permission.FSM_READ if hasattr(Permission, 'FSM_READ') else Permission.FSM_FULL,
        Permission.CMDB_READ, Permission.INVENTORY_READ,
        Permission.FINANCE_FULL, Permission.AI_FULL,
    },
    Role.SALES_MANAGER: {
        Permission.CRM_FULL, Permission.SALES_FULL,
        Permission.PROJECTS_READ, Permission.INVENTORY_READ,
        Permission.FINANCE_READ, Permission.AI_LIMITED,
    },
    Role.PROJECT_MANAGER: {
        Permission.CRM_READ, Permission.SALES_READ,
        Permission.PROJECTS_FULL, Permission.CMDB_FULL,
        Permission.INVENTORY_FULL, Permission.FINANCE_READ,
        Permission.AI_LIMITED,
    },
    Role.SERVICE_MANAGER: {
        Permission.CRM_READ, Permission.PROJECTS_READ,
        Permission.FSM_FULL, Permission.CMDB_FULL,
        Permission.INVENTORY_READ, Permission.AI_LIMITED,
    },
    Role.ENGINEER: {
        Permission.PROJECTS_OWN, Permission.FSM_OWN,
        Permission.CMDB_READ, Permission.INVENTORY_USE,
        Permission.AI_OWN,
    },
    Role.WAREHOUSE: {
        Permission.PROJECTS_READ, Permission.CMDB_READ,
        Permission.INVENTORY_FULL,
    },
    Role.ACCOUNTANT: {
        Permission.CRM_READ, Permission.SALES_READ,
        Permission.PROJECTS_READ, Permission.FSM_READ if hasattr(Permission, 'FSM_READ') else Permission.FSM_FULL,
        Permission.INVENTORY_READ, Permission.FINANCE_FULL,
    },
    Role.VIEWER: {
        Permission.CRM_READ, Permission.SALES_READ,
        Permission.PROJECTS_READ, Permission.CMDB_READ,
        Permission.INVENTORY_READ, Permission.FINANCE_READ,
    },
}


def has_permission(role: Role, permission: Permission) -> bool:
    return permission in ROLE_PERMISSIONS.get(role, set())


def get_permissions(role: Role) -> set[Permission]:
    return ROLE_PERMISSIONS.get(role, set())
