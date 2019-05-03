# GeoWeb

This is the codebase for MIT's GeoBlacklight instance.

# Deploying

See https://github.mit.edu/mitlibraries/geodeploy for instructions on how to deploy this.

# Local development

The `docker-compose.yml` file can be used to start up a full GeoWeb stack for local development. There are a few environment variables you need to set first. The easiest way to do this is to add them to a `.env` file in the same directory as the `docker-compose.yml` file, but they can be set in any way you normally would set environment variables.

env var | description
--- | ---
`SECRET_KEY_BASE` | The secret key used by Rails
`GEOSERVER_PASSWORD` | The password used to log into GeoServer
`MINIO_PASSWORD` | The password used to log into Minio

Before you can successfully run `docker-compose up` you will need to run the Rails migrations on the PostGres database. You should only have to do this once:

    $ docker-compose up -d db
    $ docker-compose logs -f

Wait until you see a log entry saying something about the database being ready to accept connections, then run:

    $ docker-compose up -d web
    $ docker-compose logs -f web

Wait until you see a log entry about the Rails app starting up. Now you can just use `docker-compose up` and `docker-compose down` as usual. Anytime you delete the PostGres volume you will need to repeat these steps.

Once everything is running you will have the following services running:

* GeoServer: http://localhost:8080/geoserver. Login is `admin` and whatever you set `GEOSERVER_PASSWORD` to.
* Solr: http://localhost:8983/solr
* Minio: http://localhost:9000. Login is `minio` and whatever you set `MINIO_PASSWORD` to.
* GeoBlacklight: http://localhost:3000
* PostGIS running on port 5432

## Adding data to your local instance

You will need to use [slingshot](https://github.com/MITLibraries/slingshot) to add data. The easiest thing to do will be to install slingshot locally using pipenv:

    $ git clone git@github.com:MITLibraries/slingshot.git
    $ cd slingshot
    $ pipenv install

The following will assume you have run the above three commands. Before loading data there are a few things you will need to do.

1. Create the `upload` and `store` buckets in Minio. You can call them whatever you want, just make sure you use these names when you run slingshot.
2. Create a `.env` file in slinghot's project root (note: this is different than the `.env` file you used above for docker-compose) setting the following environment variables:

envvar | value | note
--- | --- | ---
`GEOSERVER` | `http://localhost:8080/geoserver` |
`GEOSERVER_USER` | `admin` |
`GEOSERVER_PASSWORD` | | Use the password you set for `GEOSERVER_PASSWORD` in your compose .env file.
`SOLR` | `http://localhost:8983/solr/geoweb` |
`AWS_ACCESS_KEY_ID` | `minio` |
`AWS_SECRET_ACCESS_KEY` | | Use the password you set for `MINIO_PASSWORD` in your compose .env file.
`PG_DATABASE` | `postgresql://postgres@localhost/postgres` |
`S3_ENDPOINT` | `http://localhost:9000` |
`S3_ALIAS` | `minio` |

3. Initialize GeoServer:

    ```
    $ pipenv run slingshot initialize --db-host db
    ```

4. Upload a data layer to Minio. You can find a test layer in slingshot at `tests/fixtures/bermuda.zip`. Go to Minio and add this layer to your `upload` bucket.

Now you are ready to add some data! Run the following:

    $ pipenv run slingshot publish upload bermuda.zip store

_Note: `upload` and `store` in this command refer to bucket names. If you did not create them yet, see above. If you named them something else, modify this command to match your chosen names._  

If all goes well you should see a message about the layer being published. You can now open up your GeoBlacklight instance and search for your layer.

## Troubleshooting

### Any database errors

If you are running a pg database outside of this docker context, it's probably best to stop it, `docker-compose down` and `docker-compose up` to see if that resolves your problem.

### Bucket doesn't exist errors

There was a setup step where you are supposed to setup `upload` and `store` buckets. Did you do that? Did you name them something else? Did you use that alternate name in your various `.env` files and `slingshot` command?
