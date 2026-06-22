// Frappe desk client script for Access Transfer Act.
// All API calls go directly to Frappe @whitelist methods — no FastAPI JWT needed from desk.

frappe.ui.form.on('Access Transfer Act', {
    refresh: function(frm) {
        if (frm.is_new()) return;

        const hasEntries = frm.doc.included_entries && frm.doc.included_entries.length > 0;
        const alreadyGenerated = frm.doc.delivery_token && !frm.doc.link_burned;

        if (hasEntries) {
            frm.add_custom_button(__('Генерувати акт'), function() {
                if (alreadyGenerated) {
                    frappe.confirm(
                        __('Попередній акт буде анульовано. Клієнт більше не зможе відкрити старе посилання. Продовжити?'),
                        () => riad_mfa_then_generate(frm)
                    );
                } else {
                    riad_mfa_then_generate(frm);
                }
            }, __('Vault'));

            frm.add_custom_button(__('Переглянути акт'), function() {
                riad_desk_preview(frm);
            }, __('Vault'));
        }
    }
});

function riad_mfa_then_generate(frm) {
    frappe.prompt(
        [{ fieldname: 'totp_code', fieldtype: 'Data', label: __('TOTP-код (з застосунку)'), reqd: 1 }],
        function(values) {
            frappe.call({
                method: 'security_erp.vault.mfa.verify_step_up',
                args: { code: values.totp_code },
                freeze: true,
                freeze_message: __('Перевірка MFA…'),
                callback: function(r) {
                    if (!r.message || !r.message.vault_session_token) {
                        frappe.msgprint({ title: __('Помилка'), message: __('MFA-верифікація не вдалася.'), indicator: 'red' });
                        return;
                    }
                    riad_do_generate(frm, r.message.vault_session_token);
                }
            });
        },
        __('Підтвердіть особу (MFA)'),
        __('Підтвердити')
    );
}

function riad_do_generate(frm, vault_session_token) {
    frappe.call({
        method: 'security_erp.vault.act.generate',
        args: { act_name: frm.doc.name, vault_session_token: vault_session_token },
        freeze: true,
        freeze_message: __('Генерація акту…'),
        callback: function(r) {
            if (!r.message || !r.message.ok) {
                frappe.msgprint({ title: __('Помилка'), message: __('Не вдалося згенерувати акт.'), indicator: 'red' });
                return;
            }
            const m = r.message;
            const domain = window.location.origin.replace('erp.', 'api.');
            const fullLink = `${domain}${m.link}`;

            frappe.msgprint({
                title: __('Акт згенеровано'),
                indicator: 'green',
                message: `
                    <p><b>Посилання для клієнта:</b></p>
                    <p><code style="word-break:break-all">${fullLink}</code></p>
                    <p style="margin-top:8px"><a href="#" onclick="navigator.clipboard.writeText('${fullLink}')">[Копіювати посилання]</a></p>
                    <hr style="margin:12px 0">
                    <p><b>OTP-код для клієнта:</b></p>
                    <p style="font-size:28px;letter-spacing:8px;font-weight:700;color:#276749">${m.otp}</p>
                    <p style="color:#e53e3e;margin-top:8px">⚠ Передайте окремим каналом (SMS/Viber/Telegram).<br>⚠ Після закриття цього вікна код більше не відображається.</p>
                    <p style="color:#718096;font-size:12px;margin-top:8px">Дійсно до: ${m.expires_at}</p>
                `
            });

            frm.reload_doc();
        }
    });
}

function riad_desk_preview(frm) {
    const entries = (frm.doc.included_entries || []).map(r => r.vault_entry).filter(Boolean);
    if (!entries.length) {
        frappe.msgprint(__('Акт не містить Vault Entry.'));
        return;
    }

    frappe.prompt(
        [{ fieldname: 'totp_code', fieldtype: 'Data', label: __('TOTP-код (MFA)'), reqd: 1 }],
        function(values) {
            frappe.call({
                method: 'security_erp.vault.mfa.verify_step_up',
                args: { code: values.totp_code },
                freeze: true,
                callback: function(r) {
                    if (!r.message || !r.message.vault_session_token) {
                        frappe.msgprint({ title: __('Помилка MFA'), indicator: 'red', message: __('Невірний код.') });
                        return;
                    }
                    riad_fetch_and_show_entries(entries, r.message.vault_session_token);
                }
            });
        },
        __('MFA підтвердження для перегляду'),
        __('Підтвердити')
    );
}

function riad_fetch_and_show_entries(entry_names, vault_session_token) {
    const enc_fields = ['login_enc', 'password_enc', 'ip_enc', 'domain_enc', 'ddns_enc', 'serial_enc', 'notes_enc'];
    const LABELS = { login_enc: 'Логін', password_enc: 'Пароль', ip_enc: 'IP', domain_enc: 'Домен', ddns_enc: 'DDNS', serial_enc: 'Серійний №', notes_enc: 'Примітки' };
    let results = {};
    let pending = entry_names.length;

    function done() {
        let html = '';
        entry_names.forEach(name => {
            const fields = results[name] || {};
            html += `<div style="margin-bottom:16px"><b style="color:#4299e1">${name}</b>`;
            Object.entries(fields).forEach(([k, v]) => {
                const masked = '•'.repeat(Math.min(v.length, 10));
                html += `<div style="display:flex;justify-content:space-between;padding:4px 0;border-bottom:1px solid #2d3748">
                    <span style="font-size:12px;color:#718096">${LABELS[k] || k}</span>
                    <span>
                        <span id="dv-${name}-${k}" style="font-family:monospace;color:#4a5568">${masked}</span>
                        <a href="#" onclick="document.getElementById('dv-${name}-${k}').textContent='${v.replace(/'/g,"\\'")}';" style="font-size:12px;margin-left:8px">Показати</a>
                    </span>
                </div>`;
            });
            html += '</div>';
        });
        frappe.msgprint({ title: __('Вміст акту (лише перегляд)'), message: html });
    }

    entry_names.forEach(name => {
        frappe.call({
            method: 'security_erp.vault.api.decrypt_vault_entry',
            args: { name: name, fields: JSON.stringify(enc_fields), vault_session_token: vault_session_token },
            callback: function(r) {
                results[name] = r.message || {};
                if (--pending === 0) done();
            }
        });
    });
}
