# Cloudflare token

Create Cloudflare API token in their Management portal with these permissions:

| Token name   | Permissions                       | Resources           |
| ------------ | --------------------------------- | ------------------- |
| {token name} | Zone.Zone (Read), Zone.DNS (Edit) | Include (All zones) |

You will need this token when creating a certificate issued by LetsEncrypt using Certbot in the next step.

# Manual certificate creation (without cert-manager)

https://eff-certbot.readthedocs.io/en/stable/install.html

Note that its possible to use the manual (interactive) mode or automated one.

For the automated mode:

```
docker-compose build
source <(security find-generic-password -w -s 'cli_keys' -a '$(id -un)' | base64 --decode) (on mac)
source <(cat ~/.secrets/cli_keys.json) (on linux)
ID=$(docker-compose run -d --rm certbot)
docker exec $ID sh /src/cert_init.sh $CLOUDFLARE_TOKEN
docker exec -it $ID sh

certbot certonly \
  --non-interactive \
  --agree-tos \
  --preferred-challenges dns \
  --test-cert \
  --dns-cloudflare \
  --dns-cloudflare-credentials ./cloudflare.ini \
  -m jeroen_bijlsma@yahoo.com \
  -d \*.dotnet-works.com

# For wildcard domains escape *
#-d \*.your-domain.com

# to see details (such as issuer)
openssl x509 -in /etc/letsencrypt/live/dotnet-works.com/fullchain.pem -text
openssl x509 -in /etc/letsencrypt/live/dotnet-works.com/privkey.pem -text
```

The manual mode:

```
certbot certonly \
  --manual \
  --preferred-challenges dns \
  --debug-challenges \
  --test-cert \
  --dry-run \
  --dns-cloudflare \
  --dns-cloudflare-credentials ./cloudflare.ini \
  -m jeroen_bijlsma@yahoo.com \
  -d \*.dotnet-works.com

docker kill $ID
```

```
openssl pkcs12 -inkey /etc/letsencrypt/live/dotnet-works.com/privkey.pem -in /etc/letsencrypt/live/dotnet-works.com/fullchain.pem -export -out cert.pfx -passout pass:$CERT_PWD

chmod 777 cert.pfx
mv cert.pfx /src
```

https://adolfi.dev/blog/tls-kubernetes/

```
openssl pkcs12 -in /src/cert.pfx -nocerts -password pass:$CERT_PWD -passout pass:$CERT_PWD -out /src/cert.key
chmod 777 /src/cert.key

openssl rsa -in /src/cert.key -passin pass:$CERT_PWD -out /src/cert-decrypted.key
chmod 777 /src/cert-decrypted.key

openssl pkcs12 -in /src/cert.pfx -clcerts -password pass:$CERT_PWD -nokeys -out /src/cert.crt ##remove clcerts to get the full chain in your cert
chmod 777 /src/cert.crt
```

```
kubectl create secret tls your-secret-name --cert cert.crt --key cert-decrypted.key

kubectl get secret your-secret-name -o yaml > your-secret-name.yml
```
