# Native customization rules
- Keep Panther presentation and category navigation separate from the original patch transaction engine so validation, backups and restore are preserved.
- Compile category matching with the existing model source and test it before archiving so no extra target-source wiring is required.
- Keep the original bundle identity and shared scheme target so existing container access and unattended builds remain compatible.
- Deliver unsigned artifacts only; certificates and provisioning profiles must never enter the source repository.
