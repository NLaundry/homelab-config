# AI gateway stack notes

## Order

1. `establish-ai-secret-operations`
2. `launch-ai-gateway-microvm`
3. `route-ai-through-litellm`
4. `add-openmemory-to-ai-gateway`

Each prefix is independently deployable and reversible. Later members depend on the behavior introduced by earlier members.

## Deferred scope

Estate inventory, site topology, and address-allocation governance are intentionally excluded from this stack. The MicroVM change still verifies and reserves its selected address in OPNsense before activation. Estate/network modelling can be proposed separately later.

## Validation lifecycle

Each planning change passes normal Specbase validation. Strict projected stack validation is an implementation gate: it remains blocked before apply because the enforcement sources named in the plans do not exist until their implementation tasks are completed.
