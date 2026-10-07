#!/bin/bash
# ==============================================================================
# Bhasha AI - GPU Backend Runner & Live Log Streamer (with Wi-Fi Port Forwarding)
# Bridges phone connection (192.168.0.141:8000) directly to remote GPU server
# ==============================================================================

LOCAL_IP=$(hostname -I | awk '{print $1}')

echo "================================================================="
echo "  Bhasha AI - GPU Backend Server & Live Logs"
echo "================================================================="
echo "Local PC IP for Mobile App : $LOCAL_IP"
echo "Port                       : 8000"
echo "GPU Remote Server          : 172.16.136.120:8026"
echo "-----------------------------------------------------------------"
echo "Forwarding 0.0.0.0:8000 -> GPU 127.0.0.1:8000..."
echo "Starting backend and streaming live logs below:"
echo "================================================================="
echo ""

exec ssh -t -L 0.0.0.0:8000:127.0.0.1:8000 -p 8026 gpuuser4@172.16.136.120 "bash '/home/gpuuser4/Final Bhasha AI/run_backend.sh'"
