#!/bin/bash

# 1. Se déplacer dans le répertoire ifdd-services
echo "1. Se déplacer dans le répertoire ifdd-services"
cd ifdd-services

# 2. Copier le fichier .env.example en .env
echo "2. Copier le fichier .env.example en .env"
cp .env.example .env

# 3. Récupérer les valeurs des variables du fichier initial .env
echo "3. Récupérer les valeurs des variables du fichier initial .env"
APP_FRONTEND=$(grep "^APP_FRONTEND=" ../.env | cut -d '=' -f 2-)
APP_BACKEND=$(grep "^APP_BACKEND=" ../.env | cut -d '=' -f 2-)
APP_URL=$(grep "^APP_BACKEND=" ../.env | cut -d '=' -f 2-)
ASSET_URL=$(grep "^APP_BACKEND=" ../.env | cut -d '=' -f 2-)
ANALYTICS_PROPERTY_ID=$(grep "^ANALYTICS_PROPERTY_ID=" ../.env | cut -d '=' -f 2-)
DB_DATABASE=$(grep "^DB_DATABASE=" ../.env | cut -d '=' -f 2-)
DB_USERNAME=$(grep "^DB_USERNAME=" ../.env | cut -d '=' -f 2-)
DB_PASSWORD=$(grep "^DB_PASSWORD=" ../.env | cut -d '=' -f 2-)
MAIL_USERNAME=$(grep "^MAIL_USERNAME=" ../.env | cut -d '=' -f 2-)
MAIL_PASSWORD=$(grep "^MAIL_PASSWORD=" ../.env | cut -d '=' -f 2-)


# 4. Mettre à jour les valeurs dans le fichier .env
echo "4. Mettre à jour les valeurs dans le fichier .env"
sed -i "s+url_frontend+$APP_FRONTEND+g" .env
sed -i "s+url_backend+$APP_BACKEND+g" .env
sed -i "s+database_name+$DB_DATABASE+g" .env
sed -i "s+database_user+$DB_USERNAME+g" .env
sed -i "s+database_password+$DB_PASSWORD+g" .env
sed -i "s+mail_host+smtp.mailgun.org+g" .env
sed -i "s+mail_port+25+g" .env
sed -i "s+mail_username+$MAIL_USERNAME+g" .env
sed -i "s+mail_password+$MAIL_PASSWORD+g" .env
sed -i "s+mail_encryption+TLS+g" .env
sed -i "s+mail_from_address+infos@ifdd.com+g" .env
sed -i "s+mail_from_name+IFDD+g" .env
sed -i "s+analytics_property_id+$ANALYTICS_PROPERTY_ID+g" .env

# 5. Générer la clé d'application
echo "5. Générer la clé d'application"
php artisan key:generate

# 6. Effectuer les migrations de la base de données
echo "6. Effectuer les migrations de la base de données"
php artisan migrate:fresh

# 7. Installer Passport
echo "7. Installer Passport"
php artisan passport:install

# 8. Effectuer le seeding de la base de données
echo "8. Effectuer le seeding de la base de données"
php artisan db:seed

# 9. Générer la clé API pour l'application
echo "9. Générer la clé API pour l'application"
API_KEY=$(php artisan apikey:generate ifdd --no-ansi | awk '/Key:/{print $2}')

# 10. Créer le lien symbolique pour le stockage
echo "10. Créer le lien symbolique pour le stockage"
php artisan storage:link

# 11. Générer la documentation API avec Scribe
echo "11. Générer la documentation API avec Scribe"
php artisan scribe:generate

# 12. Importer les données pour le modèle Osc dans Scout
echo "12. Importer les données pour le modèle Osc dans Scout"
php artisan scout:import "App\Models\Osc"

# 13. Installer les dépendances Tailwind CSS du backend
echo "13. Installer les dépendances Tailwind CSS du backend"
npm i
npx tailwindcss --input ./resources/css/filament/admin/theme.css --output ./public/css/filament/admin/theme.css --config ./resources/css/filament/admin/tailwind.config.js --minify

# 14. Compiler les assets du backend
echo "14. Compiler les assets du backend"
npm run prod

# 15. Se déplacer vers le répertoire du frontend
echo "15. Se déplacer vers le répertoire du frontend"
cd /var/www/html/ifdd-frontend/src/environments

# 16. Éditer et ajouter les informations d'API dans environment.prod.ts
echo "16. Éditer et ajouter les informations d'API dans environment.prod.ts"
echo "
export const environment = {
  production: true,
  apiRoot: '$APP_BACKEND/api',
  apiKey: '$API_KEY',
};
" > environment.prod.ts

echo "
export const environment = {
  production: true,
  apiRoot: '$APP_BACKEND/api',
  apiKey: '$API_KEY',
};
" > environment.ts

# 17. Construire l'application Angular
echo "17. Construire l'application Angular"
npx ng build

# 18. Copier le fichier .htaccess dans le répertoire de distribution
echo "18. Copier le fichier .htaccess dans le répertoire de distribution"
cp /var/www/html/ifdd-frontend/htaccess.txt /var/www/html/ifdd-frontend/dist/ifdd/.htaccess

# 19. Se déplacer vers le répertoire sites-available d'Apache
echo "19. Se déplacer vers le répertoire sites-available d'Apache"
cd /etc/apache2/sites-available/

# 20. Désactiver la configuration par défaut et activer les configurations de service et de frontend
echo "20. Désactiver la configuration par défaut et activer les configurations de service et de frontend"
a2dissite 000-default.conf
a2ensite service.conf
a2ensite frontend.conf

# 21. Recharger le service Apache
echo "21. Recharger le service Apache"
service apache2 reload

# 22. Donner les permissions nécessaires sur le répertoire ifdd-services
echo "22. Donner les permissions nécessaires sur le répertoire ifdd-services"
chmod -R 777 /var/www/html/ifdd-services

# 23. Afficher un message de fin
echo "23. Installation terminée avec succès!"
