FROM homebotz/debian-dev:latest

WORKDIR /home/xtensa-gcc
RUN wget https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
  tar -zxf xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
  rm xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz

ENV PATH=/home/xtensa-gcc/xtensa-lx106-elf/bin/:$PATH
WORKDIR /home/xtensa-gcc/project