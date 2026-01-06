> This is just a simple notation doc for the manifests contained throughout this repo. Optional values are listed here for future reference.
### external-dns
To expose a service to the world-wide web, the following values need to be added to the service's Ingress manifest:
```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: prefix.nostramo.cloud
    # For cloudflare's DNS proxy...
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
```
