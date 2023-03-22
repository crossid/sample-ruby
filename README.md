# sample-ruby

A Ruby project that demonstrates how to perform authentication and authorization via [crossid](crossid.io).

## Prerequisites

- Have a Crossid tenant, or [sign up](https://crossid.io/signup) for free.
- [Add a web application](https://developer.crossid.io/docs/guides/howto/add-web-app)

## Running locally

First, install dependencies (if up to date dependencies are crucial, you should remove Gemfile.lock):

```bash
bundler
```

Depending or your env, you'll might need to install ruby-development, for example (depending on distro):

```bash
sudo apt-get install ruby-dev
sudo yum install ruby-devel
sudo zypper install ruby-devel
```

Then you can run the server with rackup:

```bash
CLIENT_ID=<client_id>\
CLIENT_SECRET=<client_secret> \
REDIRECT_URI=http://localhost:9292/callback \
ISSUER_BASE_URL=https://<tenant_id>.<region>.crossid.io/oauth2/ \
rackup
```

Depending on your "rack" version, you might need to run "bundle exec rackup"

## Deploying on Digital Ocean

Click this button to deploy the app to the DigitalOcean App Platform.

[![Deploy to DigitalOcean](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/crossid/sample-ruby/tree/main)

Note: when creating the web app, put a temporary URLs in _Redirect URI_ and _Logout URI_ until the app is deployed.

Fill the needed environment variables: `ISSUER_BASE_URL`, `CLIENT_ID` and `CLIENT_SECRET`.

Or if you have `doctl` installed then run:

`doctl apps create --spec .do/app.yaml`

Then go to the DigitalOcean admin screen and update the environment variables as stated above.

Take note of the public url of your new app. (replace _{public_url}_ below with the public url)

Finally, go to CrossID admin screen, edit the oauth2 client, and add the correct callback url: `{public_url}/callback` and to post logout redirect uris as: `{public_url}`
