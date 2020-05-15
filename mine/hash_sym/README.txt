find $PATH -type f | xargs sh launch.sh

NB : it will test all the file recursively from source path $PATH on digest (md5, sha256) and sym cipher (all des and des3 with -a option)

RUN sh clear.sh before test! 
endeed if my_ssl.enc, openssl.enc and my_ssl.dec has been loaded in launch.sh files for testing
it will failed on them cause diff will modify them at the same time it will test cipher on them
