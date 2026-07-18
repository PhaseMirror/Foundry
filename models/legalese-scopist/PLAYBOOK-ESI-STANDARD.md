# Matter Playbook: Standard ESI Hold

This playbook dictates how agents should respond to the `legalese-scopist` risk levels during a standard litigation hold.

## 1. When Risk is `Critical`
- **Action**: Immediately halt all potentially destructive operations (e.g. routine server garbage collection, email deletion policies).
- **Notification**: Issue a `[PRESERVATION ALERT]` requiring explicit manual override or review by lead counsel.
- **Documentation**: Log the `UnifiedWitness` cryptographically tying the decision back to the Rust Engine.

## 2. When Risk is `High`
- **Action**: Apply proactive retention policies.
- **Notification**: Flag the ESI stores for secondary legal review, but destructive operations might still proceed if unrelated to the specific case namespace.

## 3. When Risk is `Medium`
- **Action**: Standard retention policy applies.
- **Notification**: No immediate alerts. 
