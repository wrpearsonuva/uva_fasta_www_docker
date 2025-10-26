FROM debian:bookworm AS fasta-build
WORKDIR /app

## specify FASTA architecture for linux64
ARG FA_ARCH=linux64_sse2
## specify BLAST architecture for linux64
ARG BL_ARCH=x64-linux

## to compile (and download blast) for ARM, use
## docker compose build --build-arg FA_ARCH=linux64_simde_arm --build-arg BL_ARCH=aarch64-linux


RUN apt update && \
    apt install -y build-essential perl git curl nano cpanminus libexpat1-dev liblwp-protocol-https-perl default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /app/bin

## build fasta binaries
RUN git clone https://github.com/wrpearson/fasta36.git /app/fa_src

RUN cd /app/fa_src/src && \
    make -f ../make/Makefile.${FA_ARCH} all && \
    cp ../bin/* /app/bin && \
    cp ../scripts/* /app/bin && \
    cp ../psisearch2/* /app/bin

## install NCBI blast binaries

RUN mkdir /app/src && \
    cd /app/src && \
    curl -O ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.17.0/ncbi-blast-2.17.0+-${BL_ARCH}.tar.gz && \
    tar zxf ncbi-blast-2.17.0+-aarch64-linux.tar.gz && \
    cp ncbi-blast-2.17.0+/bin/* /app/bin

## build fasta_www3 and cpan files

## get fasta_www3
RUN mkdir /var/www && cd /var/www && \
    git clone https://github.com/wrpearson/fasta_www3.git /var/www/fasta_www3

## build/install perl modules
RUN mkdir /app/cpan && \
    cp /var/www/fasta_www3/cpan_list /var/www/fasta_www3/cpan_list_fail /app/cpan && \
    cd /app/cpan && \
    for n in `cat cpan_list`; do cpanm $n; done && \
    for n in `cat cpan_list_fail`; do cpanm --force $n; done

## define these environment variables to run stand-along fasta
## ENV SLIB2=/slib2 
## ENV RDLIB2=/slib2
## ENV FASTLIBS=/slib2/info/fast_libs_e.www

## now install the web stuff, mostly using volume mapping

FROM nginx:bookworm
WORKDIR /app
COPY --from=fasta-build /app/bin /app/bin
COPY --from=fasta-build /var/www /var/www
COPY --from=fasta-build /usr/local/share/perl/5.36.0 /usr/local/share/perl/5.36.0
COPY --from=fasta-build /usr/local/lib/aarch64-linux-gnu/perl/5.36.0 /usr/local/lib/aarch64-linux-gnu/perl/5.36.0

RUN apt clean && apt update && apt install -y nano spawn-fcgi fcgiwrap wget curl perl cpanminus libexpat1-dev python3-full liblwp-protocol-https-perl default-libmysqlclient-dev ghostscript
RUN sed -i 's/www-data/nginx/g' /etc/init.d/fcgiwrap
RUN chown nginx:nginx /etc/init.d/fcgiwrap
RUN mkdir /var/tmp/www /var/tmp/www/logs /var/tmp/www/files && \
    chown nginx:nginx /var/tmp/www/logs /var/tmp/www/files
COPY ./vhost.conf /etc/nginx/conf.d/default.conf

## install fasta_www3 website code 

CMD /etc/init.d/fcgiwrap start \
    && nginx -g 'daemon off;'

