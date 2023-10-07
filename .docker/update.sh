#!/bin/bash

# Se déplacer dans le répertoire du projet backend
cd /var/www/html/ifdd-services

# Mettre à jour le code du backend depuis le dépôt Git (assurez-vous que votre dépôt est configuré correctement)
git pull origin main

# Installer les dépendances du backend
composer update

# Exécuter les migrations de base de données si nécessaire
php artisan migrate

# installer les dépendances tailwindcss du backend
npx tailwindcss --input ./resources/css/filament/admin/theme.css --output ./public/css/filament/admin/theme.css --config ./resources/css/filament/admin/tailwind.config.js --minify

# compiler les assets du backend
npm run prod

# Se déplacer dans le répertoire du projet frontend
cd /var/www/ifdd-frontend

# Mettre à jour le code du frontend depuis le dépôt Git (assurez-vous que votre dépôt est configuré correctement)
git pull origin master

# Installer les dépendances du frontend et reconstruire l'application
npm install
npx ng build

# Copier le fichier .htaccess dans le répertoire de distribution du frontend
cp .htaccess dist/ifdd/.htaccess

# Recharger le service Apache pour prendre en compte les changements
service apache2 reload

echo "Mise à jour terminée avec succès!"
