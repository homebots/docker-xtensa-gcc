FROM homebotz/crosstool-ng:latest

RUN apt update && \
  apt remove -y python python-dev pip && \
  apt autoremove -y && \
  apt install -y python3 \
  python3-pip \
  python-is-python3 && \
  pip3 install pyserial

RUN git clone --depth 1 https://github.com/homebots/esptool.git /home/xtensa-gcc/esptool
RUN git clone -b release/v3.0.5 --depth 1 https://github.com/espressif/ESP8266_NONOS_SDK.git /home/xtensa-gcc/sdk
RUN git clone -b xtensa-gcc --depth 1 https://github.com/homebots/homebots-sdk.git /home/xtensa-gcc/homebots-sdk

ADD esp_init_data_default.bin /home/xtensa-gcc/
ADD Makefile /home/xtensa-gcc/

ENV PATH=/home/crosstool/xtensa-lx106-elf/bin:/home/xtensa-gcc/esptool:$PATH
WORKDIR /home
