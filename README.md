
# Upgrade/Migration Verification Scripts & Documentation
These are a set of scripts to verify changes in the data before upgrades and/or migrations.


**Related ticket** can be found [here](https://invicro.atlassian.net/browse/IPCL-308).

# Usage:
- Git clone the repo in the target server.
- Update information for ipacs mysql/mariadb and camunda mysql/mariadb in the scripts.
- THey will take a lot of time, running within screen is adviced.
- Todo: implement a common config file and gzip output files to avoid IO and minimize disk usage.