openssl req -subj '/CN=log.example.org/' -x509 -days 3650 -nodes -newkey rsa:2048 -keyout fqdn-log.example.org.key -out fqdn-log.example.org.crt
openssl pkcs8 -topk8 -inform PEM -outform DER -in fqdn-log.example.org.key -out fqdn-log.example.org.pkcs8 -nocrypt

