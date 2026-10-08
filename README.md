# Minikube Camap

Environnement de développement local de Camap sous Minikube (Windows 11 + Docker Desktop).

> **Ce dépôt est un template.**
> Les `values.yaml` des charts (images, URLs, secrets, ressources…) sont à adapter à votre environnement.
> Cliquer sur **"Use this template"** sur GitHub pour créer votre propre copie, puis travaillez sur celle-ci.
>
> Après le fork, mettre à jour l'URL du dépôt dans les trois fichiers suivants
> (remplacer `CAMAP-APP` par votre compte/organisation GitHub) :
>
> - `root-app.yaml`
> - `apps/camap.yaml`
> - `apps/mailpit.yaml`

---

## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et démarré
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) installé

---

## 1. Installer et démarrer Minikube

```powershell
winget install Kubernetes.minikube

minikube start --driver=docker
minikube addons enable ingress
minikube addons enable metrics-server
```

Tableau de bord (optionnel) :

```powershell
minikube dashboard
```

---

## 2. Installer Argo CD

```powershell
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
```

### Accéder à l'interface Argo CD

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Ouvrir [https://localhost:8080](https://localhost:8080)

Login : `admin`
Password :

```powershell
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### Ajouter le dépôt Git

Dans l'interface Argo CD : **Settings** > **Repositories** > **Connect Repo using HTTPS**

- Repository URL : `https://github.com/<VOTRE_REPO>/minikube-camap.git`

---

## 3. Structure du dépôt

```
.
├── root-app.yaml              # Déclaration de l'application "App of Apps"
├── apps/                      # Applications ArgoCD (camap + mailpit)
└── deployments/               # Charts Helm personnalisés
    ├── camap/
    └── mailpit/
```

---

## 4. Préparer les namespaces et secrets

### Namespaces

```powershell
kubectl create ns camap
kubectl create ns mailpit
```

### Secret MySQL

```powershell
kubectl create secret generic camap-mysql -n camap `
  --from-literal=mysql-root-password=rootpass `
  --from-literal=mysql-database=camap `
  --from-literal=mysql-username=camap `
  --from-literal=mysql-password=camappass
```

### Secret runtime

```powershell
kubectl create secret generic camap-runtime -n camap `
  --from-literal=CAMAP_KEY=une_cle_aleatoire_32chars `
  --from-literal=JWT_ACCESS_TOKEN_SECRET=secret_access `
  --from-literal=JWT_REFRESH_TOKEN_SECRET=secret_refresh `
  --from-literal=SMTP_AUTH_USER="no" `
  --from-literal=SMTP_AUTH_PASS="need"
```

---

## 5. Configurer /etc/hosts

`minikube tunnel` expose les services Ingress sur `127.0.0.1`. Ajouter les entrées suivantes dans `C:\Windows\System32\drivers\etc\hosts` :

```hosts
127.0.0.1   camap.local api.camap.local mailpit.local
```

> ⚠️ `minikube tunnel` doit être actif pour que ces adresses répondent (voir section 6).

---

## 6. Déployer avec Argo CD

Appliquer l'App of Apps :

```powershell
kubectl apply -f root-app.yaml -n argocd
```

Argo CD détecte automatiquement les applications et les synchronise (mailpit en premier, puis camap).
Si la synchronisation ne démarre pas, utiliser **Refresh Apps** dans l'interface.

---

## 7. Lancer Camap

Dans un terminal dédié (à laisser ouvert) :

```powershell
minikube tunnel
```

Puis ouvrir dans l'ordre :

1. **[http://camap.local/install](http://camap.local/install)** — initialisation de la base de données
2. **[http://camap.local/install](http://camap.local/install)** (second accès) — configuration du compte admin et d'un groupe de démonstration

> ⚠️ Un compte admin est créé avec l'adresse `admin@camap.tld` et le mot de passe `admin`

Mailpit (visualisation des emails) : **[http://mailpit.local](http://mailpit.local)**

---

## 8. Utiliser une image locale (build Docker)

Pour tester une image buildée localement sans la publier sur ghcr.io.

### Étape 1 — Builder l'image

```powershell
# Depuis le répertoire camap-ts
docker build -t camap-ts:local -f camap-ts.Dockerfile .
```

### Étape 2 — Charger l'image dans Minikube

```powershell
minikube image load camap-ts:local
```

### Étape 3 — Mettre à jour values.yaml

Dans `deployments/camap/values.yaml` :

```yaml
image:
  api:
    repository: camap-ts
    tag: "local"
    pullPolicy: Never   # ne pas chercher sur un registry distant
```

> `pullPolicy: Never` est indispensable : sans lui Kubernetes tente de puller depuis ghcr.io et échoue.
> Utiliser `IfNotPresent` si on veut un fallback vers le registry quand l'image n'est pas présente en local.

Après modification du `values.yaml`, forcer un sync dans Argo CD ou redémarrer le pod :

```powershell
kubectl rollout restart deployment camap-api -n camap
```

---

## Références

- [Documentation Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentation Argo CD](https://argo-cd.readthedocs.io/)
- [Drivers Minikube](https://minikube.sigs.k8s.io/docs/drivers/)
