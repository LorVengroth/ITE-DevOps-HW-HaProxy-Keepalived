# High-Availability Web Cluster Deployment

An automated high-availability infrastructure utilizing Vagrant, VirtualBox, Next.js (React), systemd, HAProxy, and Keepalived to deliver zero-downtime traffic distribution and failover capabilities.

---

## 1. Infrastructure Overview

The cluster consists of four Ubuntu 22.04 LTS virtual machines communicating over an isolated private host-only network (`192.168.56.0/24`).
Client / Windows Host
                         (192.168.56.1)
                               |
                   Requests to Shared VIP:
                    [http://192.168.56.100](http://192.168.56.100)
                               |
    +--------------------------+--------------------------+
    |                                                     |
    v                                                     v
+-------------------------------+     VRRP Heartbeat   +-------------------------------+
|  lb-01 (192.168.56.10)        |<====================>|  lb-02 (192.168.56.11)        |
|  Role: MASTER (Priority 101)  |   (Unicast Peering)  |  Role: BACKUP (Priority 100)  |
|  Holds: 192.168.56.100 (VIP)  |                      |  Standby for VIP              |
|  Service: HAProxy (Port 80)   |                      |  Service: HAProxy (Port 80)   |
+-------------------------------+                      +-------------------------------+
|                                                     |
+--------------------------+--------------------------+
|
Round Robin HTTP Load Balancing
|
+-----------------+-----------------+
|                                   |
v                                   v
+---------------------------------+ +---------------------------------+
|  web-01 (192.168.56.20)         | |  web-02 (192.168.56.21)         |
|  Node.js / Next.js Production   | |  Node.js / Next.js Production   |
|  Port: 3000                     | |  Port: 3000                     |
|  Daemon: systemd (next-app)     | |  Daemon: systemd (next-app)     |
|  Runs As: appuser               | |  Runs As: appuser               |
+---------------------------------+ +---------------------------------+

### Node Network Matrix

| Node Name | Role | IP Address | Port(s) | Services Running |
| :--- | :--- | :--- | :--- | :--- |
| **lb-01** | Load Balancer (Primary) | `192.168.56.10` / `192.168.56.100` (VIP) | 80 | HAProxy, Keepalived (Master) |
| **lb-02** | Load Balancer (Backup) | `192.168.56.11` | 80 | HAProxy, Keepalived (Backup) |
| **web-01** | Application Node | `192.168.56.20` | 3000 | Next.js Server (`next-app.service`) |
| **web-02** | Application Node | `192.168.56.21` | 3000 | Next.js Server (`next-app.service`) |

3. Installation & Deployment Guide
Prerequisites
Oracle VM VirtualBox (v7.0+)
Vagrant (v2.3+)

Step 1: Provision the Virtual Machines
From the repository root on your host machine:

Bash
vagrant up
Verification: Run vagrant status to confirm all 4 nodes (lb-01, lb-02, web-01, web-02) show running.

Step 2: Deploy Web Backend Nodes (web-01 & web-02)
Provision and deploy the application on web-01:

Bash
vagrant ssh web-01
bash /vagrant/scripts/setup-web.sh
bash /vagrant/scripts/deploy-react.sh
exit

Repeat on web-02:

Bash
vagrant ssh web-02
bash /vagrant/scripts/setup-web.sh
bash /vagrant/scripts/deploy-react.sh
exit

Step 3: Configure Load Balancers (lb-01 & lb-02)
Set up primary load balancer (lb-01):

bash
vagrant ssh lb-01
sudo apt-get update && sudo apt-get install -y haproxy keepalived psmisc
sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
echo "net.ipv4.ip_nonlocal_bind=1" | sudo tee -a /etc/sysctl.d/99-haproxy.conf

sudo cp /vagrant/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo cp /vagrant/keepalived/lb01.conf /etc/keepalived/keepalived.conf

sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl enable --now haproxy keepalived
exit

Set up backup load balancer (lb-02):

Bash
vagrant ssh lb-02
sudo apt-get update && sudo apt-get install -y haproxy keepalived psmisc
sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
echo "net.ipv4.ip_nonlocal_bind=1" | sudo tee -a /etc/sysctl.d/99-haproxy.conf

sudo cp /vagrant/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo cp /vagrant/keepalived/lb02.conf /etc/keepalived/keepalived.conf

sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl enable --now haproxy keepalived
exit

5. Automated Operational Scripts
scripts/setup-web.sh: Installs Node.js 20 LTS, builds required toolchains, and provisions appuser.

scripts/deploy-react.sh: Syncs code from /vagrant/next-app/ to /home/appuser/next-app/, executes npm run build, updates systemd files, restarts the unit, and runs a local smoke test.

scripts/check-health.sh: Evaluates individual backend ports, load balancer listeners, VIP response status, and round-robin alternation.

scripts/service-manager.sh: Standardizes control commands (start, stop, restart, status, logs) across web nodes and load balancers.

scripts/server-report.sh: Displays uptime, CPU load, RAM allocation, disk capacity, open ports, and VIP status in a unified telemetry view.