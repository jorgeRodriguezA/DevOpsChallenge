# Use a base image with Ubuntu
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install the necessary packages to run git, vscode, maven, postgreSQL, Java JRE
RUN apt update && \
    apt install -y curl apt-transport-https && \
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version 7.0.100 && \
    apt install -y git wget software-properties-common gnupg2 && \
    add-apt-repository ppa:openjdk-r/ppa && \
    apt install -y openjdk-11-jre-headless maven && \
    apt install -y postgresql postgresql-contrib && \
    apt install -y python3-pip && \
    pip3 install --upgrade awscli && \
    curl -LJO https://github.com/coder/code-server/releases/download/v4.16.1/code-server_4.16.1_amd64.deb && \
    apt install ./code-server_4.16.1_amd64.deb && \
    apt install -y apache2 && \
    apt install -y supervisor && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV DOTNET_ROOT=/root/.dotnet
ENV PATH="$DOTNET_ROOT:$PATH"
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:${PATH}"
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_RUN_DIR=/var/www/html

ARG RDS_USER
ARG RDS_PASSWORD
ARG DB_HOST

# PostgreSQL port
EXPOSE 5432
# Apache2 port
EXPOSE 80
# VSCode port
EXPOSE 8080

# Add AWS credentials requerided to connect to the DB
RUN mkdir /root/.aws

RUN echo $'[default] \n\
aws_access_key_id=YOUR_ACCESS_KEY_ID \n\
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY' > /root/.aws/credentials

# Setup up Apache
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf && \
    service apache2 start

RUN echo 'Hola mundo' > /var/www/html/index.html

# Setup supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Start supervisord (wich is running in foreground the rest of services)
CMD ["/usr/bin/supervisord"]
