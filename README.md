# PolicyNet: zero-trust 3-tier network on Azure

Web, app and db tiers in one VNet. Only web -> app (8080) and app -> db (5432) are allowed; everything else is denied.
A GitHub Actions pipeline applies the change and tests six allow/deny rules.

See START-HERE.md to build it. Replace this README with your own write-up at the end (problem, diagram, six rules, evidence screenshots, known gaps).
