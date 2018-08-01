FROM centos

RUN echo "multilib_policy=best" >> /etc/yum.conf
RUN yum  -y update && \
    yum install -y \
                   gcc-c++ \
                   git \
                   xinetd \
                   perl \
                   curl \
                   python \
                   openssh-server \
                   openssh-clients \
                   expect \
                   man \
                   python-argparse \
                   sshpass \
                   wget \
                   make \
                   cmake \
                   dos2unix \
                   which \
                   unzip \
                   lsof \
                   net-tools \
                   java-devel \
                   || true && \
    yum install -y http://libslack.org/daemon/download/daemon-0.6.4-1.i686.rpm > /dev/null && \
    package-cleanup --cleandupes && \
    yum  -y clean all && \
    rm -rf /var/cache/yum

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa && \
    ssh-keygen -t ecdsa -N "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo 'root:docker' | chpasswd

WORKDIR /opt/vista
# Add each folder individually to improve rebuild times
ADD ./Cache /opt/vista/Cache
ADD ./cache-files /opt/vista/cache-files
ADD ./Common /opt/vista/Common
ADD ./Dashboard /opt/vista/Dashboard
ADD ./EWD /opt/vista/EWD
ADD ./GTM /opt/vista/GTM
ADD ./tests /opt/vista/tests
ADD ./test.cmake /opt/vista/
ADD ./ViViaN /opt/vista/ViViaN
ADD ./*.sh /opt/vista/

ARG instance=osehra
ENV instance_name=$instance
ARG postInstallScript="-p ./Common/ovydbPostInstall.sh"
ARG flags="-y -b -e -m"
ARG entry="/home"
ENV entry_path="${entry}/${instance_name}"
ENV install_flags="$flags -i ${instance_name} ${postInstallScript}"

RUN dos2unix /opt/vista/* && \
    dos2unix /opt/vista/Cache/* && \
    dos2unix /opt/vista/Cache/etc/init.d/* && \
    dos2unix /opt/vista/Common/* && \
    dos2unix /opt/vista/Dashboard/* && \
    dos2unix /opt/vista/EWD/* && \
    dos2unix /opt/vista/EWD/etc/init.d/* && \
    dos2unix /opt/vista/GTM/* && \
    dos2unix /opt/vista/GTM/bin/* && \
    dos2unix /opt/vista/GTM/etc/init.d/* && \
    dos2unix /opt/vista/ViViaN/*

# OSEHRA VistA (YottaDB, no bootstrap, with QEWD and Panorama)
#RUN ./autoInstaller.sh -y -b -e -m && \
#	rm -rf /home/osehra/Dashboard
#ENTRYPOINT /home/osehra/bin/start.sh
#EXPOSE 22 8001 9430 8080

# WorldVistA (GTM, no boostrap, skip testing)
#RUN ./autoInstaller.sh -g -b -s -i worldvista -a https://github.com/glilly/wvehr2-dewdrop/archive/master.zip -p ./Common/removeVistaSource.sh && \
#ENTRYPOINT /home/worldvista/bin/start.sh
#EXPOSE 22 8001 9430

# vxVistA (YottaDB, no boostrap, skip testing, and do post-install as well)
#RUN ./autoInstaller.sh -y -b -s -i vxvista -a https://github.com/OSEHRA/vxVistA-M/archive/master.zip -p ./Common/vxvistaPostInstall.sh && \
#ENTRYPOINT /home/vxvista/bin/start.sh
#EXPOSE 22 8001 9430

# VEHU (GTM, no bootstrap, skip testing, Panorama)
#RUN ./autoInstaller.sh -g -b -s -i -m vehu -a https://github.com/OSEHRA-Sandbox/VistA-VEHU-M/archive/master.zip -p ./Common/removeVistaSource.sh && \
#ENTRYPOINT /home/vehu/bin/start.sh
#EXPOSE 22 8001 9430 8080

# RPMS (RPMS, YottaDB, no boostrap, skip testing, and do post-install as well)
# RPMS does not have a GTM VL Entry Point. Removing 8001 for now.
# RUN ./autoInstaller.sh -w -y -b -s -i rpms -a https://github.com/shabiel/FOIA-RPMS/archive/master.zip -p ./Common/rpmsPostInstall.sh && \
# ENTRYPOINT /home/rpms/bin/start.sh
# EXPOSE 22 9100 9101 9430

# Caché Install with local DAT file
# RUN ./autoInstaller.sh -c -b -s -i pla -p ./Common/pvPostInstall.sh
# ENTRYPOINT /opt/cachesys/pla/bin/start.sh
# EXPOSE 22 8001 9430 8080 57772

RUN ./autoInstaller.sh ${install_flags}
ENTRYPOINT ${entry_path}/bin/start.sh
EXPOSE 22 8001 9100 9101 9430 8080 57772
