####################################################################################################
# This script has to go after the install_packages script
#
# See:
#       https://docs.docker.com/engine/install/ubuntu/#installation-methods
#       https://www.postgresql.org/download/linux/ubuntu/
####################################################################################################

# TODO: Review this entire script

# Create the file repository configuration:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
# Update the package lists:
sudo apt-get update
# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
sudo apt-get -y install postgresql


####################################################################################################


Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following additional packages will be installed:
  libcommon-sense-perl libjson-perl libjson-xs-perl libpq5
  libtypes-serialiser-perl pgdg-keyring postgresql-client-13
  postgresql-client-common postgresql-common sysstat
Suggested packages:
  postgresql-doc-13 isag
The following NEW packages will be installed:
  libcommon-sense-perl libjson-perl libjson-xs-perl libpq5
  libtypes-serialiser-perl pgdg-keyring postgresql-13 postgresql-client-13
  postgresql-client-common postgresql-common sysstat
0 upgraded, 11 newly installed, 0 to remove and 8 not upgraded.
Need to get 17,7 MB of archives.
After this operation, 59,3 MB of additional disk space will be used.
Get:1 http://de.archive.ubuntu.com/ubuntu focal/main amd64 libcommon-sense-perl amd64 3.74-2build6 [20,1 kB]
Get:2 http://de.archive.ubuntu.com/ubuntu focal/main amd64 libjson-perl all 4.02000-2 [80,9 kB]
Get:3 http://de.archive.ubuntu.com/ubuntu focal/main amd64 libtypes-serialiser-perl all 1.0-1 [12,1 kB]
Get:4 http://de.archive.ubuntu.com/ubuntu focal/main amd64 libjson-xs-perl amd64 4.020-1build1 [83,7 kB]
Get:5 http://de.archive.ubuntu.com/ubuntu focal/main amd64 sysstat amd64 12.2.0-2 [453 kB]
Get:6 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 libpq5 amd64 13.3-1.pgdg20.04+1 [177 kB]
Get:7 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 pgdg-keyring all 2018.2 [10,7 kB]
Get:8 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-client-common all 226.pgdg20.04+1 [90,6 kB]
Get:9 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-client-13 amd64 13.3-1.pgdg20.04+1 [1.501 kB]
Get:10 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-common all 226.pgdg20.04+1 [246 kB]
Get:11 http://apt.postgresql.org/pub/repos/apt focal-pgdg/main amd64 postgresql-13 amd64 13.3-1.pgdg20.04+1 [15,1 MB]
Fetched 17,7 MB in 5s (3.621 kB/s)         
Preconfiguring packages ...
Selecting previously unselected package libcommon-sense-perl.
(Reading database ... 235369 files and directories currently installed.)
Preparing to unpack .../00-libcommon-sense-perl_3.74-2build6_amd64.deb ...
Unpacking libcommon-sense-perl (3.74-2build6) ...
Selecting previously unselected package libjson-perl.
Preparing to unpack .../01-libjson-perl_4.02000-2_all.deb ...
Unpacking libjson-perl (4.02000-2) ...
Selecting previously unselected package libtypes-serialiser-perl.
Preparing to unpack .../02-libtypes-serialiser-perl_1.0-1_all.deb ...
Unpacking libtypes-serialiser-perl (1.0-1) ...
Selecting previously unselected package libjson-xs-perl.
Preparing to unpack .../03-libjson-xs-perl_4.020-1build1_amd64.deb ...
Unpacking libjson-xs-perl (4.020-1build1) ...
Selecting previously unselected package libpq5:amd64.
Preparing to unpack .../04-libpq5_13.3-1.pgdg20.04+1_amd64.deb ...
Unpacking libpq5:amd64 (13.3-1.pgdg20.04+1) ...
Selecting previously unselected package pgdg-keyring.
Preparing to unpack .../05-pgdg-keyring_2018.2_all.deb ...
Unpacking pgdg-keyring (2018.2) ...
Selecting previously unselected package postgresql-client-common.
Preparing to unpack .../06-postgresql-client-common_226.pgdg20.04+1_all.deb ...
Unpacking postgresql-client-common (226.pgdg20.04+1) ...
Selecting previously unselected package postgresql-client-13.
Preparing to unpack .../07-postgresql-client-13_13.3-1.pgdg20.04+1_amd64.deb ...
Unpacking postgresql-client-13 (13.3-1.pgdg20.04+1) ...
Selecting previously unselected package postgresql-common.
Preparing to unpack .../08-postgresql-common_226.pgdg20.04+1_all.deb ...
Adding 'diversion of /usr/bin/pg_config to /usr/bin/pg_config.libpq-dev by postgresql-common'
Unpacking postgresql-common (226.pgdg20.04+1) ...
Selecting previously unselected package postgresql-13.
Preparing to unpack .../09-postgresql-13_13.3-1.pgdg20.04+1_amd64.deb ...
Unpacking postgresql-13 (13.3-1.pgdg20.04+1) ...
Selecting previously unselected package sysstat.
Preparing to unpack .../10-sysstat_12.2.0-2_amd64.deb ...
Unpacking sysstat (12.2.0-2) ...
Setting up pgdg-keyring (2018.2) ...
Removing apt.postgresql.org key from trusted.gpg: OK
Setting up libpq5:amd64 (13.3-1.pgdg20.04+1) ...
Setting up libcommon-sense-perl (3.74-2build6) ...
Setting up libtypes-serialiser-perl (1.0-1) ...
Setting up libjson-perl (4.02000-2) ...
Setting up sysstat (12.2.0-2) ...

Creating config file /etc/default/sysstat with new version
update-alternatives: using /usr/bin/sar.sysstat to provide /usr/bin/sar (sar) in auto mode
Created symlink /etc/systemd/system/multi-user.target.wants/sysstat.service → /lib/systemd/system/sysstat.service.
Setting up postgresql-client-common (226.pgdg20.04+1) ...
Setting up libjson-xs-perl (4.020-1build1) ...
Setting up postgresql-client-13 (13.3-1.pgdg20.04+1) ...
update-alternatives: using /usr/share/postgresql/13/man/man1/psql.1.gz to provide /usr/share/man/man1/psql.1.gz (psql.1.gz) in auto mode
Setting up postgresql-common (226.pgdg20.04+1) ...
Adding user postgres to group ssl-cert

Creating config file /etc/postgresql-common/createcluster.conf with new version
Building PostgreSQL dictionaries from installed myspell/hunspell packages...
  en_us
  es_es
Removing obsolete dictionary files:
Created symlink /etc/systemd/system/multi-user.target.wants/postgresql.service → /lib/systemd/system/postgresql.service.
Setting up postgresql-13 (13.3-1.pgdg20.04+1) ...
Creating new PostgreSQL cluster 13/main ...
/usr/lib/postgresql/13/bin/initdb -D /var/lib/postgresql/13/main --auth-local peer --auth-host md5
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locales
  COLLATE:  en_US.UTF-8
  CTYPE:    en_US.UTF-8
  MESSAGES: en_US.UTF-8
  MONETARY: de_DE.UTF-8
  NUMERIC:  de_DE.UTF-8
  TIME:     de_DE.UTF-8
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/13/main ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Europe/Berlin
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Success. You can now start the database server using:

    pg_ctlcluster 13 main start

Ver Cluster Port Status Owner    Data directory              Log file
13  main    5432 down   postgres /var/lib/postgresql/13/main /var/log/postgresql/postgresql-13-main.log
update-alternatives: using /usr/share/postgresql/13/man/man1/postmaster.1.gz to provide /usr/share/man/man1/postmaster.1.gz (postmaster.1.gz) in auto mode
Processing triggers for systemd (245.4-4ubuntu3.6) ...
Processing triggers for man-db (2.9.1-1) ...
Processing triggers for libc-bin (2.31-0ubuntu9.2) ...
francisco@francisco-ThinkPad-X1-Carbon-7th:~$ postgres

Command 'postgres' not found, did you mean:

  command 'postgrey' from deb postgrey (1.36-5.1)

Try: sudo apt install <deb name>


