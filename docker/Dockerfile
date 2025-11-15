FROM debian:bookworm AS fasta-build
WORKDIR /app

## specify FASTA architecture for linux64
ARG FA_ARCH=linux64_sse2
## specify BLAST architecture for linux64
ARG BL_ARCH=x64-linux
## specify PERL architecture for linux64
ARG PERL_ARCH=x86_64-linux

## to compile (and download blast) for ARM, use
## docker compose build --build-arg FA_ARCH=linux64_simde_arm --build-arg BL_ARCH=aarch64-linux

RUN apt update && \
    apt install -y build-essential perl git curl nano cpanminus libexpat1-dev liblwp-protocol-https-perl default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /app/bin /app/data

## build fasta36  binaries
RUN git clone --depth 1 https://github.com/wrpearson/fasta36.git /app/fa36_src

RUN cd /app/fa36_src/src && \
    make -f ../make/Makefile.${FA_ARCH} all && \
    cp ../bin/* /app/bin && \
    cp ../scripts/* /app/bin && \
    cp ../psisearch2/* /app/bin && \
    cp ../psisearch2/NCBI_all.asn /app/data

## install fasta20 chofas garnier grease psgrease

RUN git clone --depth 1 https://github.com/wrpearson/fasta2.git /app/fa20_src

RUN cd /app/fa20_src && \
    make -f Makefile grease psgrease chofas garnier && \
    cp  grease psgrease chofas garnier /app/bin

## install NCBI blast binaries

RUN mkdir /app/src && \
    cd /app/src && \
    curl -O ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.17.0/ncbi-blast-2.17.0+-${BL_ARCH}.tar.gz && \
    tar zxf ncbi-blast-2.17.0+-${BL_ARCH}.tar.gz && \
    cp ncbi-blast-2.17.0+/bin/* /app/bin

## get blastpgp and fastacmd from old version:

RUN cd /app/src && \
    curl -O ftp://ftp.ncbi.nlm.nih.gov/blast/executables/legacy.NOTSUPPORTED/2.2.26/blast-2.2.26-x64-linux.tar.gz && \
    tar zxf blast-2.2.26-x64-linux.tar.gz && \
    cp blast-2.2.26/bin/blastpgp blast-2.2.26/bin/fastacmd /app/bin && \
    cp blast-2.2.26/data/* /app/data

## install NCBI datatool binary (this does not work for RPI ARM)
RUN cd /app/src && \
    curl -O ftp://ftp.ncbi.nlm.nih.gov/toolbox/ncbi_tools++/BIN/CURRENT/datatool/datatool.Ubuntu64.tar.gz && \
    tar zxf datatool.Ubuntu64.tar.gz  && \
    cp datatool.Ubuntu64/bin/datatool /app/bin
    
## install clustalw2.1
RUN cd /app/src && \
    curl -O http://www.clustal.org/download/2.1/clustalw-2.1-linux-x86_64-libcppstatic.tar.gz && \
    tar zxf clustalw-2.1-linux-x86_64-libcppstatic.tar.gz && \
    cp clustalw-2.1-linux-x86_64-libcppstatic/clustalw2 /app/bin/clustalw

## install hmmer3
RUN cd /app/src && \
    curl -O http://eddylab.org/software/hmmer/hmmer-3.4.tar.gz && \
    tar zxf hmmer-3.4.tar.gz  && \
    cd hmmer-3.4 && \
    ./configure && make && make DESTDIR=/app install && \
    cp /app/usr/local/bin/* /app/bin

## build fasta_www3 and cpan files

## get fasta_www3
RUN mkdir /var/www && cd /var/www && \
    git clone --depth 1 https://github.com/wrpearson/fasta_www3.git /var/www/fasta_www3

## build/install perl modules
RUN mkdir /app/cpan && \
    cp /var/www/fasta_www3/cpan_list /var/www/fasta_www3/cpan_list_fail /app/cpan && \
    cd /app/cpan && \
    for n in `cat cpan_list`; do cpanm $n; done && \
    for n in `cat cpan_list_fail`; do cpanm --force $n; done

RUN echo `perldoc -l DBI`

## define these environment variables to run stand-along fasta
## ENV SLIB2=/slib2 
## ENV RDLIB2=/slib2
## ENV FASTLIBS=/slib2/info/fast_libs_e.www

## now install the web stuff, mostly using volume mapping

FROM nginx:bookworm

## specify FASTA architecture for linux64
ARG FA_ARCH=linux64_sse2
## specify BLAST architecture for linux64
ARG BL_ARCH=x64-linux
ARG PERL_ARCH=x86_64-linux


WORKDIR /app
COPY --from=fasta-build /app/bin /app/bin
COPY --from=fasta-build /app/data /app/data
COPY --from=fasta-build /var/www /var/www
COPY --from=fasta-build /usr/local/share/perl/5.36.0 /usr/local/share/perl/5.36.0
COPY --from=fasta-build /usr/local/lib/${PERL_ARCH}-gnu/perl/5.36.0 /usr/local/lib/${PERL_ARCH}-gnu/perl/5.36.0
COPY ../index.html /var/www/index.html

RUN apt clean && apt update && apt install -y nano spawn-fcgi fcgiwrap wget curl perl cpanminus libexpat1-dev python3-full liblwp-protocol-https-perl default-libmysqlclient-dev ghostscript libgomp1
RUN sed -i 's/www-data/nginx/g' /etc/init.d/fcgiwrap
RUN chown nginx:nginx /etc/init.d/fcgiwrap
RUN mkdir /var/tmp/www /var/tmp/www/logs /var/tmp/www/files && \
    chown -R nginx:nginx /var/tmp/www
COPY ../vhost.conf /etc/nginx/conf.d/default.conf

RUN ln -s /app /seqprg

## start fasta_www3 website

CMD /etc/init.d/fcgiwrap start \
    && nginx -g 'daemon off;'

