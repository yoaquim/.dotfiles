# Mountain Duck

Bookmarks for [Mountain Duck](https://mountainduck.io), symlinked into the
Mountain Duck bookmarks directory by `install.sh::setup_mountainduck()`.

## Files

- `cave.duck` — connects to the `terra-cave-us-east-1` S3 bucket via the
  `cave-mountainduck` IAM user. Bucket and user are managed in
  `~/Projects/betabit/infrastructure/live/management/workloads/cave/`.

The `.duck` file contains only the access key ID; the secret is **not**
checked in. On first connect Mountain Duck prompts for the secret and stores
it in the macOS Keychain.

## Bootstrap on a new machine

1. Run `install.sh` — it symlinks `cave.duck` into Mountain Duck's bookmarks
   directory.
2. Open Mountain Duck → the **Cave** bookmark appears.
3. Right-click → **Connect** (or **Open in Finder**).
4. When prompted, paste the secret access key (retrieve via `tofu output -raw
   mountainduck_secret_access_key` in the infra repo). Tick "Save Password"
   so it lands in Keychain.
5. Approve the system extension if macOS asks (Privacy & Security).

## Rotating the access key

```bash
cd ~/Projects/betabit/infrastructure/live/management/workloads/cave
AWS_PROFILE=management tofu apply -replace=aws_iam_access_key.mountainduck
AWS_PROFILE=management tofu output -raw mountainduck_secret_access_key
```

Then in Mountain Duck: right-click Cave → Info → paste new access key ID +
secret. The bookmark file's `Username` field should be updated to match the
new key ID.
