FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

RUN echo "Europe/Kiev" > /etc/timezone && \
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime

RUN apt-get update -qy \
 && apt-get upgrade -qy \
 && apt-get install -qy \
      apt-transport-https \
      apt-utils \
      ca-certificates \
      software-properties-common \
      openssl \
      dnsutils \
      vim \
      curl \
      net-tools \
      tcpdump

# Install Nginx
RUN add-apt-repository -y ppa:nginx/stable && \
    apt-get update -q && \
    apt-get install --no-install-recommends -qy nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    rm -f /etc/nginx/sites-available/default

RUN mkdir -p /etc/nginx/ssl/
RUN openssl req -new -x509 -days 2000 -subj "/C=UA/ST=/L=/O=/CN=my.example.com" -nodes -out /etc/nginx/ssl/cert.crt -keyout /etc/nginx/ssl/cert.key

# Install confd
#ADD https://github.com/kelseyhightower/confd/releases/download/v0.12.0-alpha3/confd-0.12.0-alpha3-linux-amd64 /usr/local/bin/confd
ADD https://github.com/hashcv/confd/releases/download/v0.12.1h/confd /usr/local/bin/confd
RUN chmod u+x /usr/local/bin/confd && \
    mkdir -p /etc/confd/conf.d && \
    mkdir -p /etc/confd/templates

# Add confd configuration files
ADD ./src/conf.d/kubernetes-nginx.toml /etc/confd/conf.d/kubernetes-nginx.toml
ADD ./src/templates/kubernetes.conf.tmpl /etc/confd/templates/kubernetes.conf.tmpl
ADD ./src/nginx.conf /etc/nginx/nginx.conf
# Add confd watcher
ADD ./src/confd-watch /opt/confd-watch
RUN chmod +x /opt/confd-watch

# Add ssl certs
ADD ssl/* /etc/nginx/ssl/

ADD .htpasswd* /etc/nginx/

# Expose http and https ports
EXPOSE 80 443

# Run the confd watcher by default
CMD /opt/confd-watch
