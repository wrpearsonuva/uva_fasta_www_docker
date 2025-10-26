25-Oct-2025

This git repository contains Docker files that can be used to build a
FASTA web server, similar to the server available at
fasta.bioch.virginia.edu.

To build a web server that runs in a linux64 system, type:
`docker compose build`.

To build a web server that runs on a Raspberry Pi, type:
`docker compose build --build-arg FA_ARCH=linux64_simde_arm --build-arg BL_ARCH=aarch64-linux`

If things work properly, the docker compose build script will:

1. build an environment with a 'C' compilers and perl.

2. download the FASTA source code from `github.com/wrpearson/fasta36.git`, compile the programs, and leave the binaries in /app/bin (the scripts in `fa_src/scripts` and `fa_src/psisearch2` are also copied to `/app/bin`.

3. download the BLAST executables from `ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.17.0/ncbi-blast-2.17.0+-${BL_ARCH}.tar.gz`, extract the binaries, and copy them to `/app/bin`

4. download the FASTA_WWW3 perl code from `github.com/wrpearson/fasta_www3/` and install it in `/var/www/fasta_www3`

5. run `cpanm` to install the perl CPAN modules listed in `/var/www/fasta_www3/cpan_list` and `cpan_list_fail`.

6. build a new image based on `nginx:bookworm` and copy the binaries and perl modules to this image

7. start the `nginx` web server

