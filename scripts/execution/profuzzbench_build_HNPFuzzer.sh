#!/bin/bash

#export NO_CACHE="--no-cache"
#export MAKE_OPT="-j4"

cd $PFBENCH
cd subjects/FTP/LightFTP
docker build . -t lightftp-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/FTP/BFTPD
docker build . -t bftpd-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE
cp fuzzing.patch fuzzing_new.patch
cp fuzzing_old.patch fuzzing.patch
docker build . -t bftpd-hnpfuzzer-nofork --build-arg $MAKE_OPT $NO_CACHE
mv fuzzing_new.patch fuzzing.patch

cd $PFBENCH
cd subjects/FTP/ProFTPD
docker build . -t proftpd-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/FTP/PureFTPD
docker build . -t pureftpd-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE
cp fuzzing.patch fuzzing_new.patch
cp fuzzing_old.patch fuzzing.patch
docker build . -t pureftpd-hnpfuzzer-nofork --build-arg $MAKE_OPT $NO_CACHE
mv fuzzing_new.patch fuzzing.patch

cd $PFBENCH
cd subjects/SMTP/Exim
docker build . -t exim-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/DNS/Dnsmasq
docker build . -t dnsmasq-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/RTSP/Live555
docker build . -t live555-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/SIP/Kamailio
docker build . -t kamailio-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/SSH/OpenSSH
docker build . -t openssh-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/TLS/OpenSSL
docker build . -t openssl-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/DTLS/TinyDTLS
docker build . -t tinydtls-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/DICOM/Dcmtk
docker build . -t dcmtk-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE

cd $PFBENCH
cd subjects/DAAP/forked-daapd
docker build . -t forked-daapd-hnpfuzzer --build-arg $MAKE_OPT $NO_CACHE
