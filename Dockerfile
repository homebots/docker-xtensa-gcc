FROM homebotz/debian-dev:latest

RUN apt update && \
  apt remove -y python python-dev pip && \
  apt autoremove -y && \
  apt install -y python3 \
  python3-pip \
  python-is-python3 && \
  pip3 install pyserial && \
  python --version && \
  python -c 'import serial'

RUN git clone --depth 1 https://github.com/homebots/esptool.git /home/esptool
RUN git clone --depth 1 https://github.com/espressif/ESP8266_NONOS_SDK.git /home/sdk
RUN git clone -b xtensa-gcc --depth 1 https://github.com/homebots/homebots-sdk.git /home/homebots-sdk

WORKDIR /home
RUN wget -q https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
  tar -zxvf xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
  rm xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz

ADD Makefile /home
RUN mkdir -p /home/esptool/bin && \
  echo 'python3 /home/esptool/esptool.py $@' >> /home/esptool/bin/esptool && \
  chmod +x /home/esptool/bin/esptool && \
  /home/esptool/bin/esptool version

ENV PATH=/home/xtensa-lx106-elf/bin:/home/esptool/bin:$PATH
