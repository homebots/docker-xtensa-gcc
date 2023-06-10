FROM ghcr.io/homebots/debian-dev:latest

RUN apt update && \
  apt remove -y python python-dev pip && \
  apt install -y python3 python3-pip python-is-python3 gcc-xtensa-lx106 libncurses5 && \
  apt autoremove -y && \
  pip3 install pyserial

# install esptool.py for binary conversion
RUN git clone --depth 1 https://github.com/homebots/esptool.git /home/esptool
RUN mkdir -p /home/esptool/bin && \
  echo 'python3 /home/esptool/esptool.py $@' >> /home/esptool/bin/esptool.sh && \
  chmod +x /home/esptool/bin/esptool.sh

RUN python3 --version && python --version && python -c 'import serial'
RUN sh /home/esptool/bin/esptool.sh version

# Add GCC headers for Xtensa stuff
COPY includes.tgz /home/
RUN mkdir /home/xtensa-gcc-headers && cd /home/xtensa-gcc-headers && tar xzf ../includes.tgz && rm ../includes.tgz

# install latest ESP NON-OS SDK
RUN git clone --depth 1 https://github.com/homebots/ESP8266_NONOS_SDK.git /home/sdk && cd /home/sdk/lib && mkdir -p tmp
# RUN cd /home/sdk/lib/tmp && xtensa-lx106-elf-ar x ../libcrypto.a && cd .. && xtensa-lx106-elf-ar rs libwpa.a tmp/*.o

# install Homebots SDK extensions
RUN git clone --depth 1 https://github.com/homebots/homebots-sdk.git -b 3c46de77c837179624c406d41c5e06e928896dba /home/homebots-sdk

WORKDIR /home
ADD Makefile /home
ADD gdbinit /home/.gdbinit
ENV PATH=/home/esptool/bin:$PATH
