# GeoWeb

This is the codebase for MIT's GeoBlacklight instance.

## Deploying

See [geodeploy](https://github.mit.edu/mitlibraries/geodeploy) for instructions on how to deploy this. **Note: This is out of date!**

## Shapefile downloads

We are using pre-signed download URLs to directly provide links to S3 for
public layers or if the user is authenticated.

The following ENV are required for this functionality:

- AWS_REGION
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_S3_BUCKET

In development / test it is assumed Minio is in use and you must also set:

- MINIO_URL. `http://localhost:9000` is likely what you want

The download link is set in the metadata for the objects, so in development / test / staging environments this will very likely send you to a production instance when you click the Download links in-app. If you copy the URL and manually change the server to the domain appropriate to your environment you should be able to see the downloads work. Alternately, you can load metadata that has been constructed to have appropriate URLs for your environment.

## Local development

The `docker-compose.yml` file can be used to start up a full GeoWeb stack for local development. There are a few environment variables you need to set first. The easiest way to do this is to add them to a `.env` file in the same directory as the `docker-compose.yml` file, but they can be set in any way you normally would set environment variables.

env var | description
--- | ---
`SECRET_KEY_BASE` | The secret key used by Rails
`GEOSERVER_PASSWORD` | The password used to log into GeoServer
`MINIO_PASSWORD` | The password used to log into Minio

Before you can successfully run `docker-compose up` you will need to run the Rails migrations on the PostGres database. You should only have to do this once:

```bash
docker-compose up -d db
docker-compose logs -f
```

Wait until you see a log entry saying something about the database being ready to accept connections, then run:

```bash
docker-compose up -d web
docker-compose logs -f web
```

Wait until you see a log entry about the Rails app starting up. Now you can just use `docker-compose up` and `docker-compose down` as usual. Anytime you delete the PostGres volume you will need to repeat these steps.

Once everything is running you will have the following services running:

- GeoServer: [http://localhost:8080/geoserver](http://localhost:8080/geoserver). Login is `admin` and whatever you set `GEOSERVER_PASSWORD` to.
- Solr: [http://localhost:8983/solr](http://localhost:8983/solr)
- Minio: [http://localhost:9000](http://localhost:9000). Login is `minio` and whatever you set `MINIO_PASSWORD` to.
- GeoBlacklight: [http://localhost:8001](http://localhost:8001)
- PostGIS running on port 5432

## Adding data to your local instance

You will need to use [slingshot](https://github.com/MITLibraries/slingshot) to add data. The easiest thing to do will be to install slingshot locally using pipenv:

```bash
git clone git@github.com:MITLibraries/slingshot.git
cd slingshot
pipenv install
```

The following will assume you have run the above three commands. Before loading data there are a few things you will need to do.

1. Create the `upload` and `store` buckets in Minio. You can call them whatever you want, just make sure you use these names when you run slingshot.
2. Create a `.env` file in slinghot's project root (note: this is different than the `.env` file you used above for docker-compose) setting the following environment variables:

envvar | value | note
--- | --- | ---
`GEOSERVER` | `http://localhost:8080/geoserver` |
`GEOSERVER_USER` | `admin` |
`GEOSERVER_PASSWORD` | | Use the password you set for `GEOSERVER_PASSWORD` in your compose `.env` file.
`SOLR` | `http://localhost:8983/solr/geoweb` |
`AWS_ACCESS_KEY_ID` | `minio` |
`AWS_SECRET_ACCESS_KEY` | | Use the password you set for `MINIO_PASSWORD` in your compose `.env` file.
`PG_DATABASE` | `postgresql://postgres@localhost/postgres` |
`S3_ENDPOINT` | `http://localhost:9000` |
`S3_ALIAS` | `minio` |

3. Initialize GeoServer:

```bash
pipenv run slingshot initialize --db-host db
```

4. Upload a data layer to Minio. You can find a test layer in slingshot at `tests/fixtures/bermuda.zip`. Go to Minio and add this layer to your `upload` bucket.

Now you are ready to add some data! Run the following:

```bash
pipenv run slingshot publish upload bermuda.zip store
```

*Note: `upload` and `store` in this command refer to bucket names. If you did not create them yet, see above. If you named them something else, modify this command to match your chosen names.*

If all goes well you should see a message about the layer being published. You can now open up your GeoBlacklight instance and search for your layer.

## Authentication

### Developer (aka fakeauth)

For local development, adding `AUTH_TYPE=developer` to .env is probably easiest.

### SAML

For production, or for when you need to test some SAML integration locally, set a bunch of variables as indicated here. For Touchstone, you can grab the `IDP_*` values from one of our production apps.

- `AUTH_TYPE=saml`
- `IDP_METADATA_URL` - URL from which the IDP metadata can be obtained. This is loaded at application start to ensure it remains up to date.
- `IDP_ENTITY_ID` - If `IDP_METADATA_URL` returns more than one IdP (like MIT does) entry, this setting signifies which IdP to use.
- `IDP_SSO_URL` - the URL from the IdP metadata to use for authentication. I was unable to reliably extract this directly from the metadata with the ruby-saml tool even though it for sure exists.
- `SP_ENTITY_ID` - unique identifier to this application, ex: [https://example.com/shibboleth](https://example.com/shibboleth)
- `SP_PRIVATE_KEY` - Base64 strict encoded version of the SP Private Key. note: Base64 is required due to multiline ENV being weird to deal with.
- `SP_CERTIFICATE` - Base64 strict encoded version of the SP Certificate. note: Base64 is required due to multiline ENV being weird to deal with.- URN_EMAIL
- `URN_EMAIL` - URN to extract from SAML response. For MIT, `urn:oid:0.9.2342.19200300.100.1.3` for testshib `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` is close enough for testing. For onelogin, I just added a new parameter field of `urn:oid:1.3.6.1.4.1.5923.1.1.1.6` to match MIT which seems to work.

### Shibboleth / mod_shib

If you *need* to use this, good luck to you. Don't set any `AUTH_TYPE` in `.env` and figure out how to make mod_shib work. :shrug:

## Troubleshooting

### Any database errors

If you are running a pg database outside of this docker context, it's probably best to stop it, `docker-compose down` and `docker-compose up` to see if that resolves your problem.

### Bucket doesn't exist errors

There was a setup step where you are supposed to setup `upload` and `store` buckets. Did you do that? Did you name them something else? Did you use that alternate name in your various `.env` files and `slingshot` command?
