set -e
echo "Testing /health endpoint..."
curl -sf http://linsoft-demo.local/health | grep "ok"
echo "Testing / endpoint..."
curl -sf http://linsoft-demo.local/ | grep "linsoft-demo"
echo "All tests passed ✓"