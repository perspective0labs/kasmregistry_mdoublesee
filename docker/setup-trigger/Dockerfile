FROM python:3.12-alpine
RUN apk add --no-cache docker-cli
WORKDIR /app
COPY server.py .
EXPOSE 19500
CMD ["python3", "-u", "server.py"]
