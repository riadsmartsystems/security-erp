frappe.ui.form.on("AI Estimate", {
	refresh(frm) {
		if (!frm.doc.__islocal) {
			frm.add_custom_button(__("Apply Template"), () => {
				frappe.prompt(
					{ fieldtype: "Link", fieldname: "template", options: "Estimate Template", label: __("Template"), reqd: 1 },
					(vals) => {
						frm.call("apply_template", { template_name: vals.template }).then(() => frm.reload_doc());
					},
					__("Apply Template")
				);
			}, __("Actions"));

			frm.add_custom_button(__("AI Generate"), () => {
				if (!frm.doc.tz_text) {
					frappe.msgprint(__("Fill in the Technical Specification field first."));
					return;
				}
				frappe.show_alert({ message: __("Generating estimate via AI…"), indicator: "blue" });
				frappe.call({
					method: "security_erp.security_erp.estimate_utils.generate_ai_estimate",
					args: { doc_name: frm.doc.name },
					callback(r) {
						if (!r.exc) {
							frm.reload_doc();
							frappe.show_alert({ message: __("AI estimate applied"), indicator: "green" });
						}
					},
				});
			}, __("Actions"));
		}
	},
});
