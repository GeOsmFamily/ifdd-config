#!/bin/bash

# Se déplacer dans le répertoire ifdd-services
cd ifdd-services

# Copier le fichier .env.example en .env
cp .env.example .env

# Mettre à jour les valeurs dans le fichier .env
sed -i 's/DB_DATABASE=.*/DB_DATABASE=ifdd/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME=postgres/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=postgres/' .env
sed -i 's/MAIL_MAILER=.*/MAIL_MAILER=smtp/' .env
sed -i 's/MAIL_HOST=.*/MAIL_HOST=smtp.mailgun.org/' .env
sed -i 's/MAIL_PORT=.*/MAIL_PORT=25/' .env
sed -i 's/MAIL_USERNAME=.*/MAIL_USERNAME=app@mail.position.cm/' .env
sed -i 's/MAIL_PASSWORD=.*/MAIL_PASSWORD=6753ec0bdc3575c06cf46ce0dc5bd806-adf6de59-3f205f46/' .env
sed -i 's/MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=TLS/' .env
sed -i 's/MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=infos@ifdd.com/' .env
sed -i 's/MAIL_FROM_NAME=.*/MAIL_FROM_NAME=IFDD/' .env
sed -i 's/ANALYTICS_PROPERTY_ID=.*/ANALYTICS_PROPERTY_ID=321877049/' .env

# Générer la clé d'application
php artisan key:generate

# Effectuer les migrations de la base de données
php artisan migrate

# Installer Passport
php artisan passport:install

# Effectuer le seeding de la base de données
php artisan db:seed

# Générer la clé API pour la démo
API_KEY=$(php artisan apikey:generate demo --no-ansi | awk '/Key:/{print $2}')

# Créer le lien symbolique pour le stockage
php artisan storage:link

# Générer la documentation API avec Scribe
php artisan scribe:generate

# Importer les données pour le modèle Osc dans Scout
php artisan scout:import "App\Models\Osc"

# installer les dépendances tailwindcss du backend
npx tailwindcss --input ./resources/css/filament/admin/theme.css --output ./public/css/filament/admin/theme.css --config ./resources/css/filament/admin/tailwind.config.js --minify

# compiler les assets du backend
npm run prod

# Se déplacer vers le répertoire du frontend
cd /var/www/html/ifdd-frontend/src/environments

# Éditer et ajouter les informations d'API dans environment.prod.ts
echo "
export const environment = {
  production: true,
  apiRoot: 'https://cartodd-api.francophonie.org/api',
  apiKey: '$API_KEY',
};
" > environment.prod.ts

# Construire l'application Angular
npx ng build

# Copier le fichier .htaccess dans le répertoire de distribution
cp /var/www/ifdd-frontend/.htaccess /var/www/ifdd-frontend/dist/ifdd/.htaccess

# Se déplacer vers le répertoire sites-available d'Apache
cd /etc/apache2/sites-available/

# Désactiver la configuration par défaut et activer les configurations de service et de frontend
a2dissite 000-default.conf
a2ensite service.conf
a2ensite frontend.conf

# Recharger le service Apache
service apache2 reload

# Donner les permissions nécessaires sur le répertoire ifdd-services
chmod -R 777 /var/www/html/ifdd-services

echo "Installation terminée avec succès!"
