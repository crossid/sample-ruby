# Readme

First run to install dependancies

```bash
bundler
```

Then you can run the server with rackup

```bash
CLIENT_ID=<client_id>\
CLIENT_SECRET=<client_secret> \
REDIRECT_URI=https://localhost/callback \
ISSUER_BASE_URL=https://<tenant_id>.crossid.io/oauth2/ \
rackup
```
