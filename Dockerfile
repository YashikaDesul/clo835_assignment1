FROM ubuntu:20.04
RUN apt-get update -y
COPY . /app
WORKDIR /app
RUN set -xe \
    && apt-get update -y \
    && apt-get install -y python3-pip \
    && apt-get install -y mysql-client 
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
EXPOSE 8080
# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl --fail http://localhost:8080/health || exit 1
ENTRYPOINT [ "python3" ]
CMD [ "app.py" ]
