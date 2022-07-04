# IFDD Install

## Installation

```sh
$ git clone https://github.com/GeOsmFamily/ifdd-config.git
$ cd ifdd-config
```

- edit & add infos in .env

```
APP_PORT=
APP_FRONTEND_PORT=
APP_ADMIN_PORT=

FORWARD_DB_PORT=
PG_PASSWORD=
DB_DATABASE=ifdd
DB_USERNAME=
DB_PASSWORD=

MEILI_PORT=
```

```
$ docker-compose up -d
$ docker exec -it ifdd-app bash
$ cd ifdd-services
$ cp .env.example .env
```

- edit & add DB & Email infos in .env

```
DB_DATABASE=database name
DB_USERNAME=database username
DB_PASSWORD=database password

MAIL_MAILER=smtp
MAIL_HOST=your host
MAIL_PORT=your port
MAIL_USERNAME=your username
MAIL_PASSWORD=your password
MAIL_ENCRYPTION=TLS
MAIL_FROM_ADDRESS=infos@ifdd.com
MAIL_FROM_NAME=IFDD


APP_FRONTEND=url_to_frontend

MEILISEARCH_HOST=host

```

```
$ php artisan key:generate
$ php artisan migrate
$ php artisan passport:install
$ php artisan db:seed
$ php artisan apikey:generate demo
$ php artisan storage:link
$ php artisan scribe:generate
$ php artisan scout:import "App\Models\Osc"

$ cd /var/www/html/ifdd-frontend
$ cd /src/environments
```

- edit & add apiRoot & apiKey infos in environment.prod.ts

```
export const environment = {
  production: true,
  apiRoot: ,
  apiKey: ,
};

```

- comment last 2 Safari major versions from the .browserslistrc file.

```
$ npx ng build
$ cd /etc/apache2/sites-available/
$ a2dissite 000-default.conf
$ a2ensite service.conf
$ a2ensite frontend.conf
$ service apache2 reload
$ chmod -R 777 /var/www/html/ifdd-services

```
