# secrets/pubkeys

One `<hostname>.asc` per machine — the **public** half of that machine's GPG
key. Public keys are not secret; committing them is what makes a refresh a
`git pull` instead of an export/import dance between three machines.

Every machine imports all of these at activation (`nix/home-manager/gpg-keys.nix`), so
each one can encrypt to every other one. That is what sops needs in order to
write a secret readable by all three.

Add a machine — `./secrets/enroll-machine`, on the new machine and then on one
that is already a recipient (see `secrets/README.md` §5). By hand that is:

    gpg --export --armor <FPR> > secrets/pubkeys/<hostname>.asc
    # add the fingerprint to .sops.yaml, then
    sops updatekeys secrets/*.env

Keys made by `enroll-machine` do not expire. For an older one that does, change
or clear the expiry (the fingerprint does not change, so no re-encryption).
Only the primary carries an expiry — an expired primary already makes the key
unusable for encryption, so there is nothing to change on the subkeys:

    gpg --quick-set-expire <FPR> never
    gpg --export --armor <FPR> > secrets/pubkeys/<hostname>.asc

Then commit — the other machines pick it up on their next rebuild.
