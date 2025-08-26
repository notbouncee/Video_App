from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/streams")
def list_streams():
    # Adjust host if you deploy elsewhere
    host = "localhost"
    return {
        "streams": {
            "cam1": {
                "rtsp": f"rtsp://{host}:8554/cam1",
                "hls":  f"http://{host}:8888/cam1",
                "webrtc": f"http://{host}:8889/cam1",
            },
            "cam2": {
                "rtsp": f"rtsp://{host}:8554/cam2",
                "hls":  f"http://{host}:8888/cam2",
                "webrtc": f"http://{host}:8889/cam2",
            }
        }
    }