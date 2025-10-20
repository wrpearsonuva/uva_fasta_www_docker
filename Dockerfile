# ====================================================
# Perl + Apache + FASTA36
# ====================================================
FROM perl:5.38

LABEL maintainer="you@example.com"
LABEL description="FASTA36 web server with Apache2 and mod_perl"

# ====================================================
# Install dependencies
# ====================================================
RUN apt-get update && apt-get install -y \
        apache2 \
        libapache2-mod-perl2 \
        libcgi-pm-perl \
        build-essential \
        wget \
        gzip \
        tar \
        vim \
        curl \
    && a2enmod cgi \
    && a2enmod perl \
    && rm -rf /var/lib/apt/lists/*

# ====================================================
# Download and install FASTA36
# ====================================================
WORKDIR /opt

RUN set -eux; \
    if wget -O fasta36.tar.gz https://fasta.bioch.virginia.edu/wrpearson/fasta/fasta36/executables/fasta36-linux64.tar.gz; then \
        echo "✅ Using precompiled FASTA36 binary"; \
        tar xzf fasta36.tar.gz; \
        cp fasta36/* /usr/local/bin/; \
        rm -rf fasta36 fasta36.tar.gz; \
    else \
        echo "⚙️ Building FASTA36 from source"; \
        wget https://fasta.bioch.virginia.edu/wrpearson/fasta/fasta36/fasta-36.3.8i.tar.gz; \
        tar xzf fasta-36.3.8i.tar.gz; \
        cd fasta-36.3.8i/src; \
        make -f ../make/Makefile.linux64_sse2 all; \
        cp ../bin/* /usr/local/bin/; \
        cd /opt; \
        rm -rf fasta-36.3.8i*; \
    fi

# ====================================================
# Apache configuration for CGI
# ====================================================
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    mkdir -p /usr/lib/cgi-bin && \
    mkdir -p /var/www/html && \
    chown -R www-data:www-data /usr/lib/cgi-bin /var/www/html && \
    chmod -R 755 /usr/lib/cgi-bin

# Create a simple default index page (for testing)
RUN echo "<h2>FASTA36 Web Server Running</h2>" > /var/www/html/index.html

# ====================================================
# Copy your CGI script(s)
# ====================================================
COPY app.pl /usr/lib/cgi-bin/app.pl
RUN chmod +x /usr/lib/cgi-bin/app.pl

# ====================================================
# Apache site configuration
# ====================================================
RUN echo "\
<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    ServerName localhost\n\
    DocumentRoot /var/www/html\n\
    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/\n\
    <Directory /usr/lib/cgi-bin>\n\
        AllowOverride None\n\
        Options +ExecCGI\n\
        AddHandler cgi-script .pl\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog /var/log/apache2/error.log\n\
    CustomLog /var/log/apache2/access.log combined\n\
</VirtualHost>\n" > /etc/apache2/sites-available/000-default.conf

# ====================================================
# Expose and run Apache
# ====================================================
EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]
