These certificates are copied from https://github.com/ConsultingMD/paloaltonetworks/tree/master/certs

They are the internal Grand Rounds root and DLP CAs. The OS trusts them through the System
keychain. The core.certificates step copies them to ~/.ih/certs for tools that read them from
there, such as docker-compose files that mount mozilla.pem.

If these certs expire John Walsh is probably the person to talk to.

~/.ih/certs/mozilla.pem is a symlink to /etc/ssl/cert.pem, which device management maintains.
