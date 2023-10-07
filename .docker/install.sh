#!/bin/bash

# Se déplacer dans le répertoire ifdd-services
cd ifdd-services

# Copier le fichier .env.example en .env
cp .env.example .env

# Mettre à jour les valeurs dans le fichier .env
sed -i 's/DB_DATABASE=.*/DB_DATABASE=nom_de_la_base_de_donnees/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME=nom_d_utilisateur_de_la_base_de_donnees/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=mot_de_passe_de_la_base_de_donnees/' .env
sed -i 's/MAIL_MAILER=.*/MAIL_MAILER=smtp/' .env
sed -i 's/MAIL_HOST=.*/MAIL_HOST=votre_hote/' .env
sed -i 's/MAIL_PORT=.*/MAIL_PORT=votre_port/' .env
sed -i 's/MAIL_USERNAME=.*/MAIL_USERNAME=votre_nom_d_utilisateur/' .env
sed -i 's/MAIL_PASSWORD=.*/MAIL_PASSWORD=votre_mot_de_passe/' .env
sed -i 's/MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=TLS/' .env
sed -i 's/MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=infos@ifdd.com/' .env
sed -i 's/MAIL_FROM_NAME=.*/MAIL_FROM_NAME=IFDD/' .env
sed -i 's/APP_FRONTEND=.*/APP_FRONTEND=url_vers_le_frontend/' .env
sed -i 's/MEILISEARCH_HOST=.*/MEILISEARCH_HOST=host/' .env
sed -i 's/ANALYTICS_PROPERTY_ID=.*/ANALYTICS_PROPERTY_ID=host/' .env

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
  apiRoot: 'votre_racine_api',
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
