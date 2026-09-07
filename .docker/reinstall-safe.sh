#!/bin/bash
# Réinstallation complète de l'application SANS toucher aux données existantes.
# Contrairement à install.sh, ce script n'exécute jamais `migrate:fresh` ni `db:seed` :
# il applique seulement les migrations en attente (`migrate`) sur une base déjà en place.
# À utiliser après avoir recréé le volume applicatif (le volume Docker qui a été compromis),
# une fois le conteneur relancé avec le nouveau build.
set -e

echo "1. Configuration du .env de ifdd-services"
cd /var/www/html/ifdd-services
if [ ! -f .env ]; then
  cp .env.example .env
fi

APP_FRONTEND=$(grep "^APP_FRONTEND=" /var/www/html/.env | cut -d '=' -f 2-)
APP_BACKEND=$(grep "^APP_BACKEND=" /var/www/html/.env | cut -d '=' -f 2-)
DB_DATABASE=$(grep "^DB_DATABASE=" /var/www/html/.env | cut -d '=' -f 2-)
DB_USERNAME=$(grep "^DB_USERNAME=" /var/www/html/.env | cut -d '=' -f 2-)
DB_PASSWORD=$(grep "^DB_PASSWORD=" /var/www/html/.env | cut -d '=' -f 2-)
MAIL_USERNAME=$(grep "^MAIL_USERNAME=" /var/www/html/.env | cut -d '=' -f 2-)
MAIL_PASSWORD=$(grep "^MAIL_PASSWORD=" /var/www/html/.env | cut -d '=' -f 2-)
ANALYTICS_PROPERTY_ID=$(grep "^ANALYTICS_PROPERTY_ID=" /var/www/html/.env | cut -d '=' -f 2-)

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

echo "2. Nouvelle clé d'application (APP_KEY) — invalide les cookies/sessions existants, voulu après l'incident"
php artisan key:generate --force

echo "3. Migrations en attente UNIQUEMENT (pas de migrate:fresh, la base existante n'est pas touchée)"
php artisan migrate --force

echo "4. Réinstallation de Passport (régénère les clés RSA -> invalide les anciens tokens JWT, voulu après l'incident)"
php artisan passport:install --force

echo "5. Nouvelle clé API applicative (l'ancienne, exposée publiquement, sera à désactiver en base ensuite)"
API_KEY=$(php artisan apikey:generate "ifdd-$(date +%s)" --no-ansi | awk '/Key:/{print $2}')
echo "   -> Nouvelle clé API générée : $API_KEY"

echo "6. Lien symbolique de stockage"
php artisan storage:link

echo "7. Documentation API (Scribe)"
php artisan scribe:generate

echo "8. Réindexation Meilisearch"
php artisan scout:import "App\Models\Osc"

echo "9. Assets du panel admin (Filament)"
npm i
npx tailwindcss --input ./resources/css/filament/admin/theme.css --output ./public/css/filament/admin/theme.css --config ./resources/css/filament/admin/tailwind.config.js --minify
npm run prod

echo "10. Build du frontend Angular avec la nouvelle clé API"
cd /var/www/html/ifdd-frontend/src/environments
cat > environment.prod.ts <<EOF
export const environment = {
  production: true,
  apiRoot: '$APP_BACKEND/api',
  apiKey: '$API_KEY',
};
EOF
cp environment.prod.ts environment.ts

cd /var/www/html/ifdd-frontend
npm install
npx ng build --configuration production
cp /var/www/html/ifdd-frontend/htaccess.txt /var/www/html/ifdd-frontend/dist/ifdd/.htaccess

echo "11. Permissions (ciblées, jamais 777)"
chown -R www-data:www-data /var/www/html/ifdd-services
chmod -R 775 /var/www/html/ifdd-services/storage /var/www/html/ifdd-services/bootstrap/cache

echo ""
echo "=== Terminé ==="
echo "Nouvelle clé API : $API_KEY"
echo "Pense a desactiver l'ancienne clé en base :"
echo "  UPDATE api_keys SET active = false WHERE key != '$API_KEY';"
