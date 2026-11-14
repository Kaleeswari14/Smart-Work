# VPS Hosting & Production Infrastructure Guide (`vps_hosting_guide.md`)

This guide explains cloud hosting options, Virtual Private Server (VPS) architecture, Nginx configuration, SSL certificates, and database backup routines.

---

## 🌐 1. Supabase Cloud vs Self-Hosted VPS
* **Supabase Cloud (Managed):**
  * Built-in automated backups, global CDN, 99.9% uptime, zero DevOps overhead.
  * Free tier is generous and suitable for starting out.
* **Self-Hosted VPS (Docker / Ubuntu):**
  * Recommended when complete data ownership on private servers is required or for long-term cost optimization.
  * We will evaluate if Supabase Cloud is sufficient first before recommending any VPS purchase.

---

## 🛡️ 2. Linux Server Security Checklist (When using VPS)
* **UFW Firewall:** Enable ports 22 (SSH), 80 (HTTP), 443 (HTTPS) only.
* **Fail2ban:** Protect SSH from brute-force attacks.
* **Nginx Reverse Proxy:** Route incoming HTTPS traffic securely to backend containers.
* **Let's Encrypt Certbot:** Free automated TLS/SSL certificates.
* **Automated Cron Backups:** Nightly PostgreSQL `pg_dump` backups pushed to encrypted cloud storage.
