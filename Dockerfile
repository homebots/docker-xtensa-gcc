FROM ghcr.io/homebots/debian-dev:latest

RUN apt update && \
  apt remove -y python python-dev pip && \
  apt autoremove -y && \
  apt install -y python3 \
  python3-pip \
  python-is-python3 && \
  pip3 install pyserial

RUN python --version && python -c 'import serial'

RUN git clone --depth 1 https://github.com/homebots/esptool.git /home/esptool
RUN mkdir -p /home/esptool/bin && \
  echo 'python3 /home/esptool/esptool.py $@' >> /home/esptool/bin/esptool.sh && \
  chmod +x /home/esptool/bin/esptool.sh
RUN python3 --version
RUN /home/esptool/bin/esptool.sh version

RUN git clone --depth 1 https://github.com/homebots/ESP8266_NONOS_SDK.git /home/sdk
RUN git clone -b xtensa-gcc --depth 1 https://github.com/homebots/homebots-sdk.git /home/homebots-sdk
RUN apt-get install -y gcc-xtensa-lx106
WORKDIR /home
# COPY ./xtensa-lx106-elf.tgz .
# RUN tar -zxvf xtensa-lx106-elf.tgz && rm xtensa-lx106-elf.tgz

ADD Makefile /home

RUN apt install -y libncurses5
ADD gdbinit /home/.gdbinit

# ENV PATH=/home/xtensa-lx106-elf/bin:/home/esptool/bin:$PATH
ENV PATH=/home/esptool/bin:$PATH
