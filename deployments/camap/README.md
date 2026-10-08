# README.md — Chart Helm **camap**

Ce chart Helm déploie l’application **Camap** dans Kubernetes avec une approche GitOps propre (ArgoCD + SealedSecrets).

## ⚙️ Composants déployés

- API Camap (`camap-api`)
- Frontend Web (`camap-web`)
- Base MySQL (optionnelle)
- Ingress HTTP/S (cert-manager)
- Templates de configuration applicative

---

# 📦 Structure du Chart

```

camap/
├── Chart.yaml
├── values.yaml
├── files/
│   ├── camapts.env.tpl
│   └── camaphx-config.xml.tpl
├── templates/
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── apache-overlay-configmap.yaml
│   ├── certificate-api.yaml
|   ├── certificate-web.yaml
│   ├── deployment-api.yaml
│   ├── deployment-web.yaml
│   ├── service-api.yaml
│   ├── service-web.yaml
│   ├── ingress-api.yaml
│   ├── ingress-web.yaml
│   ├── ingress-web-redirects.yaml
│   ├── web-hpa.yaml
│   └── statefulset-mysql.yaml

````

---

# 🔐 Gestion des secrets (IMPORTANT)

👉 **Aucun secret ne doit être présent dans `values.yaml`**

Tous les secrets sont :

- créés via `kubectl create secret`
- convertis en `SealedSecret`
- stockés dans Git

---

## 🔑 Secrets attendus

### 1. Secret MySQL

Nom : `camap-mysql`

Clés :

- `mysql-root-password`
- `mysql-database`
- `mysql-username`
- `mysql-password`

---

### 2. Secret runtime

Nom : `camap-runtime`

Clés :

- `CAMAP_KEY`
- `JWT_ACCESS_TOKEN_SECRET`
- `JWT_REFRESH_TOKEN_SECRET`
- `SMTP_AUTH_USER`
- `SMTP_AUTH_PASS`

---

## 🛠️ Création des secrets (avant sealing)

### MySQL

```bash
kubectl create secret generic camap-mysql \
  --namespace camap \
  --from-literal=mysql-root-password='ROOT_PASSWORD' \
  --from-literal=mysql-database='camap' \
  --from-literal=mysql-username='docker' \
  --from-literal=mysql-password='USER_PASSWORD' \
  --dry-run=client -o yaml
````

---

### Runtime

```bash
kubectl create secret generic camap-runtime \
  --namespace camap \
  --from-literal=CAMAP_KEY='CHANGE_ME' \
  --from-literal=JWT_ACCESS_TOKEN_SECRET='CHANGE_ME' \
  --from-literal=JWT_REFRESH_TOKEN_SECRET='CHANGE_ME' \
  --from-literal=SMTP_AUTH_USER='smtp-user' \
  --from-literal=SMTP_AUTH_PASS='smtp-pass' \
  --dry-run=client -o yaml
```

---

## 🔒 Conversion en SealedSecret

```bash
kubectl create secret generic camap-runtime ... --dry-run=client -o yaml \
| kubeseal --controller-name sealed-secrets \
           --controller-namespace kube-system \
           -o yaml > camap-runtime-sealed.yaml
```

---

# 🧩 Configuration applicative

## 🧠 Principe

Les fichiers :

* `camapts.env`
* `camaphx-config.xml`

NE sont plus stockés en clair.

👉 Ils sont générés dynamiquement à partir de templates :

```
files/*.tpl
```

---

## ⚙️ Mécanisme

1. `ConfigMap` contient les templates
2. `SealedSecret` fournit les variables sensibles
3. `initContainer` génère les fichiers finaux via `envsubst`
4. Les pods utilisent les fichiers générés

---

## 📁 Exemple

```
files/camapts.env.tpl
files/camaphx-config.xml.tpl
```

Contiennent :

```bash
DB_PASSWORD=${DB_PASSWORD}
JWT_ACCESS_TOKEN_SECRET=${JWT_ACCESS_TOKEN_SECRET}
```

---

# 🧩 MySQL

* StatefulSet avec PVC
* Config injectée via `my.cnf`
* Secret externe (SealedSecret)

⚠️ Le chart **ne crée plus de Secret MySQL**

---

# 🌐 Ingress & TLS

TLS est géré par **cert-manager uniquement**

```yaml
ingress:
  web:
    tls:
      enabled: true
      clusterIssuer: letsencrypt-prod
```

👉 Aucun `Certificate` dans ce chart

---

# 🌍 Routing

### API

```
https://api.camap.amap44.org → camap-api:3010
```

### Web

```
https://camap.amap44.org → camap-web:80
```

---

# 🔄 Apache overlay (web)

Le frontend utilise Apache avec proxy vers l’API :

* `/neostatic`
* `/graphql`
* `/locales`

---

## ⚠️ Ordre de déploiement

Utiliser des sync-waves :

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
```

| Ressource     | Wave |
| ------------- | ---- |
| SealedSecrets | -1   |
| MySQL         | 0    |
| API / Web     | 1    |

---

## ⚠️ Champs immuables

Après modification du chart :

```bash
argocd app sync camap --force
```

Sinon erreurs :

* `spec.selector immutable`
* `StatefulSet forbidden update`

---

# 🚀 Bonnes pratiques

✔ Aucun secret dans Git
✔ Templates versionnés (`files/`)
✔ Secrets via SealedSecrets
✔ Chart réutilisable dev/prod
✔ InitContainer pour config dynamique

