#!/bin/bash
gunicorn --bind 0.0.0.0:8000 -k uvicorn.workers.UvicornWorker app.main:app