from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import os, socket

app = FastAPI()

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Content-Security-Policy"] = "default-src 'none'"
    return response

@app.get("/")
def root():
    return {
        "service": "devsecops-k8s-demo",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "hostname": socket.gethostname()
    }

@app.get("/health")
def health():
    return {"status": "ok"}