# Suricata IDS Services #

## Installation ##

```bash
git clone https://github.com/Creased/ids-services.git
cd ids-services/

cp ./etc/default/{barnyard2,snorby,suricata} /etc/default/
chmod 644 /etc/default/{barnyard2,snorby,suricata}

cp ./usr/sbin/{barnyard2,snorby}.sh /usr/sbin/
chmod 755 /usr/sbin/{barnyard2,snorby}.sh
cp ./etc/init.d/suricata /etc/init.d/
chmod 755 /etc/init.d/suricata

cp ./etc/systemd/system/{barnyard2,snorby}.service /etc/systemd/system/

systemctl enable barnyard2.service
systemctl enable snorby.service
systemctl enable suricata.service
```

## Usage ##

### Restart ###

```bash
systemctl restart barnyard2.service
systemctl restart snorby.service
systemctl restart suricata.service
```

### Status ###

```bash
systemctl status barnyard2.service
systemctl status snorby.service
systemctl status suricata.service
```
