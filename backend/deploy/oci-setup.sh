#!/usr/bin/env bash
# One-shot dev-server setup — run ON the OCI instance from ~/backend.
#
#   ./deploy/oci-setup.sh <PUBLIC_IP>
#
# Opens the OS firewall for :8000, installs Docker if missing, writes a .env with
# generated secrets (first run only), and brings up FastAPI + Postgres.
# NOTE: you must ALSO open port 8000 in the OCI console (VCN → Security List → Ingress);
# the OS firewall alone is not enough.
set -euo pipefail

PUBLIC_IP="${1:-}"
if [ -z "$PUBLIC_IP" ]; then
  echo "usage: ./deploy/oci-setup.sh <PUBLIC_IP>"
  echo "  (the instance's public IP — the app will point at http://<PUBLIC_IP>:8000)"
  exit 1
fi

echo "==> 1/4  OS firewall: allow TCP 8000"
if command -v firewall-cmd >/dev/null 2>&1; then          # Oracle Linux
  sudo firewall-cmd --permanent --add-port=8000/tcp
  sudo firewall-cmd --reload
else                                                       # Ubuntu (iptables)
  sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
  if ! command -v netfilter-persistent >/dev/null 2>&1; then
    sudo apt-get update -y && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
  fi
  sudo netfilter-persistent save
fi

echo "==> 2/4  Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" || true
fi

echo "==> 3/4  .env (generated once; edit later for GOOGLE_CLIENT_ID etc.)"
if [ ! -f .env ]; then
  cp .env.prod.example .env
  sed -i "s|change-me-openssl-rand-hex-32|$(openssl rand -hex 32)|" .env
  sed -i "s|change-me-long-random|$(openssl rand -hex 16)|" .env
  sed -i "s|http://CHANGE-ME-PUBLIC-IP:8000|http://${PUBLIC_IP}:8000|" .env
  echo "    wrote .env (JWT_SECRET + POSTGRES_PASSWORD generated; PUBLIC_BASE_URL=http://${PUBLIC_IP}:8000)"
else
  echo "    .env already exists — leaving it as-is"
fi

echo "==> 4/4  docker compose up"
sudo docker compose up -d --build

echo "==> waiting for API health…"
for i in $(seq 1 20); do
  if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ API up locally. From your Mac, verify:  curl http://${PUBLIC_IP}:8000/health"
    echo "   Then tell Claude the IP → it sets TRACE_API_HOST=${PUBLIC_IP}:8000"
    exit 0
  fi
  sleep 2
done
echo "⚠️  API didn't answer /health in time. Check: sudo docker compose logs api"
exit 1
