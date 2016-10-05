openssl req -subj '/CN=log.example.org/' -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout fqdn-log.example.org.key -out fqdn-log.example.org.crt

