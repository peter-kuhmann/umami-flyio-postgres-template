![Umami Logo x Fly.io Logo](umami-x-flyio.png)

# Umami Fly.io Template

This repo features a [Fly.io](https://fly.io) configuration template that allows you to

- **self-host [Umami](https://umami.is/)**,
- with an **integrated Postgres** database,
- daily database snapshots,
- and an auto-growing disk-space.

➡️ **For ~$3.67 per month**; see [pricing](#-pricing) (*).

# 📖 Table Of Contents

<!-- TOC -->
* [Umami Fly.io Template](#umami-flyio-template)
* [📖 Table Of Contents](#-table-of-contents)
* [ℹ️ General](#ℹ-general)
* [👀 Comparison With Umami Cloud](#-comparison-with-umami-cloud)
* [🛠️ Requirements](#-requirements)
* [📝 Set Up](#-set-up)
  * [Optional: Fork repository](#optional-fork-repository)
  * [Step 1: Copy config template](#step-1-copy-config-template)
  * [Step 2: Launch app without deploy](#step-2-launch-app-without-deploy)
  * [Step 3: Set `APP_SECRET`](#step-3-set-app_secret)
  * [Step 4: Deploy app](#step-4-deploy-app)
  * [Step 5: Change admin password](#step-5-change-admin-password)
  * [Optional: Configure custom domain](#optional-configure-custom-domain)
* [🆕 Updating Umami](#-updating-umami)
* [🌱 Scaling](#-scaling)
  * [Performance](#performance)
  * [Database](#database)
* [💾 Snapshot Recovery](#-snapshot-recovery)
* [🤑 Pricing](#-pricing)
<!-- TOC -->

# ℹ️ General

In the end, you will have a Fly machine, that is running a docker container. That
docker container is built using the custom `Dockerfile`.

This `Dockerfile` uses the official Umami Postgres docker image as a base image.
The `Dockerfile` adds a postgres installation on top and configures a start routine
that initializes the database **and** starts the Umami server in the end.

This means you will have exactly one machine that hosts the (internal-only) Postgres
database and the Umami server.

The Postgres database will be persisted via a Fly volume (initially 3GB).

# 👀 Comparison With Umami Cloud

Please check out Umami's cloud offer: [https://umami.is/docs/cloud](https://umami.is/docs/cloud)

Be recommend the cloud offer if you are non-technical, need support, and/or don't
want to care updating the hosting.

As a self-hosted Umami offers the same functionality, this solution comes only with the following
downsides:
- no dedicated database backup strategy (only the Fly volume snapshots)
- does not scale automatically (you have to increase the Fly machine and volume when necessary)
- no automatic updates

# 🛠️ Requirements

- Fly.io account
- [`flyctl` 🔗](https://fly.io/docs/flyctl/install/) is installed

# 📝 Set Up

## Optional: Fork repository

If you want, you can fork this repository.

Fork it via the following link: [https://github.com/peter-kuhmann/umami-flyio-template/fork](https://github.com/peter-kuhmann/umami-flyio-template/fork)

## Step 1: Copy config template

Duplicate the file `fly.toml.template` and name it `fly.toml`:

```bash
cp fly.toml.template fly.toml
```

**Attention**: The `.gitignore` causes the `fly.toml` to be not
versioned by git. If you consciously want to commit your final
`fly.toml`, remove it from the `.gitignore`.

## Step 2: Launch app without deploy

Now we need to "launch" the app. But we don't want to deploy it yet.

```bash
fly launch --no-deploy
```

You will be asked if you want to apply the config of the existing `fly.toml`.
Confirm that with `Y`.

Afterwards, you are also prompted with the option to tweak the settings.
You may use that opportunity to tweak the app's name and region.

## Step 3: Set `APP_SECRET`

Now you need to set a random `APP_SECRET` for you application. Umami uses that for
authentication.

**You should definitely set the `APP_SECRET` to have a secure and "unique" installation.**

Set the `APP_SECRET` like so:

```bash
fly secrets set APP_SECRET=<app_secret>
```

If you have the `openssl` command, you can automatically generate an `APP_SECRET` like so:

```bash
fly secrets set APP_SECRET=$(openssl rand -hex 64)
```

## Step 4: Deploy app

Now it's time to deploy your Fly app:

```bash
fly deploy
```

This will automatically provision the Fly machine and the Fly volume.

## Step 5: Change admin password

The output of `fly deploy` should contain a `fly.dev` subdomain via which
you can reach your Umami installation.

**Now, you have to change the default password**:

- Open the URL,
- log in (user = `admin`, password = `umami`),
- go to settings,
- and change the default password of the `admin` user.

## Optional: Configure custom domain

You can also configure a custom domain or subdomain for your
Umami installation.

Therefor, issue a certificate via `flyctl`:

```bash
fly certs add <hostname>
```

Then:

- Configure the DNS records according to the output of `fly certs add`.
- Wait for the SSL certificate to be issued. Can be verified via `fly certs list`; `status` must be `ready`.

# 🆕 Updating Umami

This is very simple. As the custom `Dockerfile` uses the official Postgres image
as the base, you simply need to redeploy the app (without cache):
```bash
fly deploy --no-cache
```

This will rebuild the app using the newest base docker image from Umami.
On start, database migrations will be executed automatically by the Umami server.

# 🌱 Scaling

## Performance

If you need a more performant machine, you can change the machine type of the one Fly machine.

You can update a Fly machine via `flyctl`. Check out the docs about updating a machine:
[`flyctl` Machine Update 🔗](https://fly.io/docs/flyctl/machine-update/)

Imagine you want to upgrade your `shared-1x 512MB` machine to a
`shared-4x 2GB` one, then your command will likely look something like this:

```bash
fly machine update <machine_id> \
    --vm-cpu-kind shared \
    --vm-cpus 4 \
    --vm-memory 2GB \
```

(To get the ID of the machine you want to update, use `fly machine list`.)

**Attention: You can not create multiple machines.** The reason for that is, that this setup
does not support a multi machine and multi volume configuration with automatic data replication.
**So scale vertically. It should be sufficient for a very long time.**

## Database

The volume used for the Postgres database is defined in the `fly.toml`
respectively `fly.toml.template` will be/is configured to:

- have an initial size of 3GB
- automatically increase in size
    - once a 90% disk usage is reached
    - by 1GB every time
    - with a max limit of 20GB
- produce daily snapshots with a 14 days retention

If you need more disk space for the Postgres database, you can always manually extend the volume:
[`flyctl` Volume Management 🔗](https://fly.io/docs/flyctl/volumes/)

# 💾 Snapshot Recovery

You can recover a snapshot the following way:

- create a new volume from a given snapshot (ID)
- use the newly created volume for the application

Check out the docs for creating a volume from a snapshot (arg `--snapshot-id`)
[`flyctl` Volume Creation 🔗](https://fly.io/docs/flyctl/volumes-create/)

Your command will probably look something like this:

```bash
fly vol create umami_database_data_recovered \
    --size 3GB
    --snapshot-retention 14
    --snapshot-id <snapshot_id>
    -r <region>
    -a <app_name>
```

Afterwards:

- Update the `fly.toml` to use the volume in the `[mount]` sections.
- Redeploy your app via `fly deploy`

**Attention: The volume has to be created in the same region as the machine!**

# 🤑 Pricing

The following pricing table has been calculated as per [Fly.io's pricing](https://fly.io/docs/about/pricing/)
from September 2024 for the Amsterdam region (`ams`):

| CPUs                          | Memory | Disk Space | Machine Price | Volume Price | Total Price |
|-------------------------------|--------|------------|---------------|--------------|-------------|
| shared-1x (*) (this template) | 512MB  | 3GB        | $3.22         | $0.45        | **$3.67**   |
| shared-2x                     | 1GB    | 10GB       | $6.64         | $1.50        | **$8.14**   |
| shared-4x                     | 2GB    | 20GB       | $13.27        | $3.00        | **$16.27**  |
| performance-1x                | 2GB    | 20GB       | $32.19        | $3.00        | **$35.19**  |
| performance-2x                | 4GB    | 50GB       | $64.39        | $7.50        | **$71.89**  |

**All prices above are for machines that run the whole month!** If you have very little traffic, the price is going
to be lower as the machine will be automatically paused when there is no traffic.

This table shall only demonstrate how expensive the simplest option is (you need at least a `512MB` memory machine)
and how expensive more powerful setups with larger databases can be.

Feel free to check out the Umami cloud pricing here: [https://umami.is/pricing](https://umami.is/pricing)
