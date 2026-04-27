# AutoTrack — Brief Agent

Application Flutter de suivi de véhicule. Ce README est un brief complet pour qu'un agent Claude puisse déployer l'infrastructure et mettre l'app en production sans intervention humaine.

---

## Accès SSH

| Machine | IP | User | Clé SSH |
|---|---|---|---|
| Proxmox VE (host) | 192.168.1.32 | root | `~/.ssh/rocaraid_server` |
| VM autotrack-db (à créer) | à définir | root | même clé |
| VM autotrack-app (à créer) | à définir | root | même clé |

Commande de connexion : `ssh -i ~/.ssh/rocaraid_server root@192.168.1.32`

---

## Infrastructure cible (ZÉRO DOCKER — services systemd natifs)

### Machine hôte Proxmox
- OS : Proxmox VE (Debian 13)
- CPU : Intel i3-2120, 4 threads
- RAM : 7.7 GB
- sda : Samsung SSD 850 EVO 250 GB — Proxmox installé (ne pas toucher)
- sdb : Samsung SSD 750 EVO 500 GB — partition sdb1 NTFS à reformater en ext4 pour PostgreSQL

### VM 1 — autotrack-db (backend)
- OS : Ubuntu 24.04 Server (télécharger cloud image depuis Proxmox)
- RAM : 3 GB, vCPU : 2
- Disque OS : 30 GB sur local-lvm
- Disque données : sdb monté sur /mnt/data, lien symbolique /var/lib/postgresql → /mnt/data/postgresql
- Services natifs (apt/binary, PAS Docker) :
  - PostgreSQL 17 (port 5432)
  - PostgREST v12 binary (port 3000)
  - GoTrue v2 binary (port 9999)
  - Nginx reverse proxy (expose tout sur port 54321)

### VM 2 — autotrack-app (frontend)
- OS : Ubuntu 24.04 Server
- RAM : 2 GB, vCPU : 2
- Disque OS : 20 GB sur local-lvm
- Services :
  - Flutter SDK (~/flutter)
  - Nginx (sert build/web sur port 80)
  - Git (clone de ce repo)
- Workflow déploiement : `git pull` → `flutter build web` → Nginx sert build/web

---

## Stack technique

- Flutter 3.35 / Dart 3.9
- Supabase = PostgreSQL 17 + PostgREST v12 + GoTrue v2 (self-hosted, sans Docker)
- RLS activé sur toutes les tables — isolation par `auth.uid()`
- Provider pattern (ChangeNotifier) pour la gestion d'état

---

## Configuration Flutter

Fichier : `lib/main.dart`

```dart
await Supabase.initialize(
  url: 'http://<IP-VM-DB>:54321',   // à remplacer après création VM
  anonKey: '<JWT_ANON_KEY>',         // à générer depuis GoTrue
);
```

La clé anon est un JWT HS256 signé avec le secret JWT configuré dans GoTrue (`GOTRUE_JWT_SECRET`).

---

## Schéma base de données

Tables :
- `vehicles` — véhicules avec `user_id` FK vers auth.users
- `fuel_entries` — pleins carburant
- `maintenance_entries` — entretiens
- `technical_controls` — contrôles techniques
- `insurance` — assurances
- `expenses` — dépenses génériques

RLS activé sur toutes les tables : `USING (user_id = auth.uid())`.

Le schéma complet SQL est à appliquer sur PostgreSQL. Il se trouve localement sur la machine de dev à :
`D:\Documents\Coding_project\Ia_Agentique_rocaraid\dart_files\schema_v2.sql`

---

## Tâches à accomplir (dans l'ordre)

1. Formater sdb : `wipefs -a /dev/sdb && mkfs.ext4 /dev/sdb`, monter sur `/mnt/data`
2. Créer VM autotrack-db via API Proxmox (Ubuntu 24.04 cloud image)
3. Installer PostgreSQL 17 : `apt install postgresql-17`, data dir → /mnt/data/postgresql
4. Installer PostgREST v12 binary, configurer service systemd sur port 3000
5. Installer GoTrue v2 binary, configurer service systemd sur port 9999, générer JWT secret + anon key
6. Configurer Nginx sur autotrack-db : reverse proxy port 54321 → PostgREST + GoTrue
7. Appliquer le schéma SQL sur PostgreSQL
8. Créer VM autotrack-app (Ubuntu 24.04)
9. Installer Flutter SDK sur autotrack-app
10. Cloner ce repo, `flutter build web`, configurer Nginx pour servir build/web
11. Mettre à jour `lib/main.dart` avec l'IP réelle et la vraie anonKey, committer et pusher
12. Configurer Wake-on-LAN sur le host Proxmox
13. Mettre en place pg_dump cron pour backups vers /mnt/data/backups

---

## Contraintes importantes

- ZÉRO DOCKER — tout installé nativement comme services systemd
- Déploiement MANUEL : ne jamais builder/déployer sans validation utilisateur
- Accès local uniquement (pas d'exposition internet)
- Architecture multi-tenant prévue : table `subscriptions` + RLS Stripe à ajouter plus tard
