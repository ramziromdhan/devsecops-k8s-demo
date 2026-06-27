from fastapi import FastAPI
import os, socket

app = FastAPI()

@app.get("/")
def root():
    return {
        "service": "linsoft-demo",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "hostname": socket.gethostname()   # utile pour voir quel pod répond
    }

@app.get("/health")
def health():
    return {"status": "ok"}