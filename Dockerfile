FROM homebotz/debian-dev:latest

RUN apt update && \
  apt remove -y python python-dev pip && \
  apt autoremove -y && \
  apt install -y python3 \
  python3-pip \
  python-is-python3 && \
  pip3 install pyserial

RUN git clone --depth 1 https://github.com/homebots/esptool.git /home/esptool
RUN git clone --depth 1 https://github.com/espressif/ESP8266_NONOS_SDK.git /home/sdk
RUN git clone -b xtensa-gcc --depth 1 https://github.com/homebots/homebots-sdk.git /home/homebots-sdk

WORKDIR /home
RUN wget https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
  tar -zxvf xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
  rm xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz

# RUN cp /home/sdk/lib/* /home/xtensa-lx106-elf/xtensa-lx106-elf/sysroot/usr/lib/
ADD Makefile /home

ENV PATH=/home/xtensa-lx106-elf/bin:/home/esptool:$PATH

USER debian
