from erpnext.accounts.custom.address import ERPNextAddress


class CustomAddress(ERPNextAddress):
    def validate_reference(self):
        self.is_your_company_address = getattr(self, 'is_your_company_address', False)
        super().validate_reference()
