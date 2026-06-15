#!/usr/bin/env python3
"""
Seed the AI Knowledge Base with sample security equipment documentation.
Usage: python seed_knowledge.py
"""
import json
import urllib.request

AI_SERVICE_URL = "http://localhost:8003"

DOCUMENTS = [
    {
        "title": "Hikvision DS-2CD2043G2-I Camera Installation Guide",
        "content": """The Hikvision DS-2CD2043G2-I is a 4MP IR Fixed Bullet Network Camera.

Installation Steps:
1. Mount the camera using the included bracket at 2.5-3m height
2. Connect Ethernet cable (PoE supported, 802.3af)
3. Use SADP tool to find the camera on the network
4. Default IP: 192.168.1.64, admin/password: 12345
5. Configure resolution: 2688x1520@25fps
6. Set up motion detection zones
7. Configure NVR recording schedule

Common Issues:
- No image: Check PoE power budget on switch
- Dark image: Enable IR LEDs, check IR-cut filter
- Network timeout: Verify VLAN settings, check cable length (max 100m)
- Firmware update: Download from Hikvision portal, upload via web interface""",
        "doc_type": "manual",
        "tags": "hikvision,camera,installation,CCTV",
    },
    {
        "title": "MikroTik CCR2004-1G-12S+2XS Router Configuration",
        "content": """MikroTik CCR2004-1G-12S+2XS is a cloud core router with 12 SFP+ and 2 QSFP28 ports.

Initial Setup:
1. Connect via WinBox or web interface (192.168.88.1)
2. Default credentials: admin/no password
3. Set admin password: /password
4. Configure WAN interface: /ip dhcp-client
5. Set up NAT: /ip firewall nat add chain=srcnat action=masquerade
6. Configure DNS: /ip dns set servers=8.8.8.8

VLAN Configuration for Security Network:
1. Create VLAN interface: /interface vlan add name=vlan100 vlan-id=100 interface=sfp-sfpplus1
2. Assign IP: /ip address add address=10.100.0.1/24 interface=vlan100
3. Set up DHCP for cameras: /ip pool add name=cam-pool ranges=10.100.0.10-10.100.0.200
4. Configure firewall rules for camera isolation""",
        "doc_type": "manual",
        "tags": "mikrotik,router,network,configuration",
    },
    {
        "title": "Ajax Hub 2 Plus Alarm System Setup",
        "content": """Ajax Hub 2 Plus is a professional security system hub with Jeweller radio protocol.

Setup Process:
1. Power on Hub, connect to WiFi/Ethernet
2. Open Ajax app, scan QR code on Hub
3. Add devices: press button on sensor, Hub detects automatically
4. Configure zones: Entry/Exit, Perimeter, Interior
5. Set entry/exit delays: 30s entry, 60s exit recommended
6. Configure notifications: push, SMS, call
7. Set up monitoring station connection (Contact ID)

Device Pairing:
- MotionProtect: press pairing button, LED blinks
- DoorProtect: magnet alignment critical (5mm gap max)
- StreetSiren: mount at 2.5m height, test siren volume
- FireProtect: mount on ceiling, test with smoke

Troubleshooting:
- Device offline: check battery, move closer to Hub
- False alarms: adjust sensitivity, check pet immunity
- Communication loss: check Jeweller signal strength (should be >-80 dBm)""",
        "doc_type": "manual",
        "tags": "ajax,alarm,hub,security,setup",
    },
    {
        "title": "Network Topology Best Practices for Security Systems",
        "content": """Security network architecture guidelines for CCTV and access control.

Network Segmentation:
1. Create separate VLAN for security devices (VLAN 100 recommended)
2. Isolate cameras from corporate network
3. Use ACLs to restrict access between VLANs
4. Dedicated management VLAN for switches and NVRs

IP Addressing Scheme:
- 10.100.0.0/24 - Camera network
- 10.100.1.0/24 - NVR and recording
- 10.100.2.0/24 - Access control
- 10.100.3.0/24 - Management

Bandwidth Calculation:
- 4MP camera @ 25fps H.265: ~4-6 Mbps
- 16 cameras per switch: ~80 Mbps aggregate
- NVR uplink: 1Gbps minimum for 16 cameras
- Storage: 1TB per camera per month (24/7 recording)

Switch Requirements:
- PoE budget: 30W per camera port
- Uplink: SFP+ 10Gbps for core switches
- QoS: prioritize video traffic (DSCP EF)
- IGMP snooping for multicast streams""",
        "doc_type": "guide",
        "tags": "network,topology,architecture,CCTV,infrastructure",
    },
    {
        "title": "Common Camera Issues and Solutions",
        "content": """Troubleshooting guide for common CCTV camera problems.

Issue: Camera shows black screen
- Check power supply (PoE budget exceeded?)
- Verify network cable (test with cable tester)
- Check IR LEDs (visible red glow in dark?)
- Reset camera to factory defaults
- Check NVR channel configuration

Issue: Image is blurry/out of focus
- Clean lens with microfiber cloth
- Adjust focus ring (if varifocal)
- Check camera mounting angle
- Verify resolution settings match NVR capability

Issue: Night vision not working
- Check IR LED status in camera settings
- Verify IR-cut filter operation
- Check ambient light sensor
- Update camera firmware

Issue: Camera disconnects intermittently
- Check PoE switch power budget
- Verify cable length (max 100m for Cat6)
- Check for network loops
- Monitor switch port errors
- Consider PoE extender for long runs

Issue: Recording gaps
- Check HDD health in NVR
- Verify recording schedule
- Check motion detection sensitivity
- Monitor NVR CPU/memory usage""",
        "doc_type": "faq",
        "tags": "camera,troubleshooting,CCTV,maintenance",
    },
    {
        "title": "SLA Response Time Requirements",
        "content": """Service Level Agreement response time requirements by priority.

Priority P1 - Critical (System Down):
- Response time: 30 minutes
- Arrival time: 2 hours
- Resolution time: 4 hours
- Examples: Complete system failure, security breach, fire alarm activation

Priority P2 - High (Major Issue):
- Response time: 1 hour
- Arrival time: 4 hours
- Resolution time: 8 hours
- Examples: Multiple cameras offline, access control failure, NVR not recording

Priority P3 - Medium (Minor Issue):
- Response time: 4 hours
- Arrival time: 24 hours
- Resolution time: 48 hours
- Examples: Single camera offline, motion detection false alarms, minor configuration issue

Priority P4 - Low (Request):
- Response time: 24 hours
- Arrival time: scheduled
- Resolution time: 5 business days
- Examples: Configuration changes, firmware updates, documentation requests

Escalation Procedure:
1. P1: Immediate phone call to service manager
2. P2: Email notification to service team
3. P3-P4: Standard ticket workflow
4. All priorities tracked in Service Ticket system""",
        "doc_type": "guide",
        "tags": "SLA,response time,service,priority,contract",
    },
]


def seed():
    print(f"Seeding {len(DOCUMENTS)} documents to {AI_SERVICE_URL}...")

    for i, doc in enumerate(DOCUMENTS):
        data = json.dumps(doc).encode()
        req = urllib.request.Request(
            f"{AI_SERVICE_URL}/api/v1/ai/documents",
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                result = json.loads(resp.read())
                doc_id = result.get("data", {}).get("id", "?")
                chunks = result.get("data", {}).get("chunks", 0)
                print(f"  [{i+1}/{len(DOCUMENTS)}] OK: {doc['title'][:50]}... (id={doc_id}, chunks={chunks})")
        except Exception as e:
            print(f"  [{i+1}/{len(DOCUMENTS)}] FAIL: {doc['title'][:50]}... ({e})")

    print("\nDone! Check stats at: GET /api/v1/ai/stats")


if __name__ == "__main__":
    seed()
