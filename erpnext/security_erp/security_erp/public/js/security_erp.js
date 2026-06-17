frappe.provide("security_erp");

security_erp = {
    version: "1.0.0",

    get_priority_color: function(priority) {
        const colors = {
            'Critical': '#dc3545',
            'High': '#ea580c',
            'Medium': '#2563eb',
            'Low': '#16a34a',
        };
        return colors[priority] || '#757575';
    },

    get_status_class: function(status) {
        const classes = {
            'Open': 'ticket-status-open',
            'In Progress': 'ticket-status-in-progress',
            'Assigned': 'ticket-status-open',
            'Resolved': 'ticket-status-resolved',
            'Closed': 'ticket-status-closed',
        };
        return classes[status] || '';
    },

    format_sla_time: function(due_date) {
        if (!due_date) return '';
        const now = frappe.datetime.now_datetime();
        const diff = frappe.datetime.get_diff(due_date, now);
        if (diff < 0) return `<span class="sla-breached">${Math.abs(diff)}d overdue</span>`;
        if (diff <= 1) return `<span class="sla-warning">${diff}d left</span>`;
        return `<span class="sla-ok">${diff}d left</span>`;
    },
};
