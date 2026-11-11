#!/usr/bin/env bash
# Builds a repo whose feature/billing branch mixes a schema change, a new service, API wiring, a rename and tests.
set -eu
git init -q && echo repo-setup.sh >> .git/info/exclude -b main && git config user.email dev@example.com && git config user.name dev
mkdir -p app/models app/api tests
printf 'class Customer:\n    def __init__(self, id, email):\n        self.id = id\n        self.email = email\n' > app/models/customer.py
printf 'from app.models.customer import Customer\n\ndef get_customer(id):\n    return Customer(id, "a@b.c")\n' > app/api/customers.py
printf 'def test_placeholder():\n    assert True\n' > tests/test_smoke.py
git add . && git commit -qm "initial"
git switch -qc feature/billing
printf 'class Customer:\n    def __init__(self, id, email, plan="free", stripe_id=None):\n        self.id = id\n        self.email = email\n        self.plan = plan\n        self.stripe_id = stripe_id\n' > app/models/customer.py
printf 'class Invoice:\n    def __init__(self, id, customer_id, amount_cents, status="draft"):\n        self.id = id\n        self.customer_id = customer_id\n        self.amount_cents = amount_cents\n        self.status = status\n' > app/models/invoice.py
mkdir -p app/services
printf 'from app.models.invoice import Invoice\n\nPRICES = {"free": 0, "pro": 2000, "team": 9900}\n\ndef create_invoice(customer):\n    return Invoice(id=None, customer_id=customer.id, amount_cents=PRICES[customer.plan])\n\ndef finalize(invoice):\n    if invoice.amount_cents == 0:\n        invoice.status = "void"\n    else:\n        invoice.status = "open"\n    return invoice\n' > app/services/billing.py
printf 'from app.services.billing import create_invoice, finalize\nfrom app.api.customers import get_customer\n\ndef post_invoice(customer_id):\n    c = get_customer(customer_id)\n    return finalize(create_invoice(c))\n' > app/api/invoices.py
sed -i.bak 's/get_customer/fetch_customer/' app/api/customers.py app/api/invoices.py && rm -f app/api/*.bak
printf 'from app.services.billing import create_invoice, finalize\nfrom app.models.customer import Customer\n\ndef test_free_is_void():\n    assert finalize(create_invoice(Customer(1, "x", "free"))).status == "void"\n\ndef test_pro_is_open():\n    assert finalize(create_invoice(Customer(1, "x", "pro"))).status == "open"\n' > tests/test_billing.py
mkdir -p app/reports
for r in revenue churn usage invoices_aging mrr arr seats refunds; do
  {
    echo "\"\"\"$r report.\"\"\""
    echo "from app.models.invoice import Invoice"
    echo ""
    for i in $(seq 1 12); do
      echo "def ${r}_metric_$i(invoices):"
      echo "    total = 0"
      echo "    for inv in invoices:"
      echo "        if inv.status == \"open\":"
      echo "            total += inv.amount_cents * $i"
      echo "    return total"
      echo ""
    done
  } > app/reports/$r.py
done
printf 'from app.reports import revenue, churn\n\ndef test_revenue_empty():\n    assert revenue.revenue_metric_1([]) == 0\n' > tests/test_reports.py
git add . && git commit -qm "billing: models, service, api, rename, tests, reporting"
