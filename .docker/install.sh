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
APP_URL=$(grep "^APP_URL=" ../.env | cut -d '=' -f 2-)
ASSET_URL=$(grep "^ASSET_URL=" ../.env | cut -d '=' -f 2-)
ANALYTICS_PROPERTY_ID=$(grep "^ANALYTICS_PROPERTY_ID=" ../.env | cut -d '=' -f 2-)

# 4. Mettre à jour les valeurs dans le fichier .env
echo "4. Mettre à jour les valeurs dans le fichier .env"
sed -i "s/APP_FRONTEND=.*/APP_FRONTEND=$APP_FRONTEND/" .env
sed -i "s/APP_BACKEND=.*/APP_BACKEND=$APP_BACKEND/" .env
sed -i "s/APP_URL=.*/APP_URL=$APP_URL/" .env
sed -i "s/ASSET_URL=.*/ASSET_URL=$ASSET_URL/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=ifdd/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=postgres/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=postgres/" .env
sed -i "s/MAIL_MAILER=.*/MAIL_MAILER=smtp/" .env
sed -i "s/MAIL_HOST=.*/MAIL_HOST=smtp.mailgun.org/" .env
sed -i "s/MAIL_PORT=.*/MAIL_PORT=25/" .env
sed -i "s/MAIL_USERNAME=.*/MAIL_USERNAME=app@mail.position.cm/" .env
sed -i "s/MAIL_PASSWORD=.*/MAIL_PASSWORD=6753ec0bdc3575c06cf46ce0dc5bd806-adf6de59-3f205f46/" .env
sed -i "s/MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=TLS/" .env
sed -i "s/MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=infos@ifdd.com/" .env
sed -i "s/MAIL_FROM_NAME=.*/MAIL_FROM_NAME=IFDD/" .env
sed -i "s/ANALYTICS_PROPERTY_ID=.*/ANALYTICS_PROPERTY_ID=$ANALYTICS_PROPERTY_ID/" .env

# 5. Générer la clé d'application
echo "5. Générer la clé d'application"
php artisan key:generate

# 6. Effectuer les migrations de la base de données
echo "6. Effectuer les migrations de la base de données"
php artisan migrate

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

# 17. Construire l'application Angular
echo "17. Construire l'application Angular"
npx ng build

# 18. Copier le fichier .htaccess dans le répertoire de distribution
echo "18. Copier le fichier .htaccess dans le répertoire de distribution"
cp /var/www/ifdd-frontend/.htaccess /var/www/ifdd-frontend/dist/ifdd/.htaccess

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
