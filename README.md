# xtensa-gcc compiler for esp8266

Contains:

- [ESP_NONOS_SDK v3.0.5](https://github.com/espressif/ESP8266_NONOS_SDK)
- [Xtensa gcc compiler v5.2.0](https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz)
- [esptool.py](github.com/homebots/esptool)

## Usage

### Build your project

```bash
docker run --rm -v $PWD:/home/project ghcr.io/homebots/xtensa-gcc make
```

The final firmware binaries are in `firmware/` folder.

### Flash with esptool.py

There are two files to flash. For esp8266, the following command writes the firmware to flash:

```bash
# replace /dev/usb.serialport123 with the serial port of your esp8266 flasher.
# baud rate might need to change... 115200 works well

esptool.py --after no_reset --baud 230400 --port /dev/usb.serialport123 write_flash --compress --flash_freq 80m -fm qio -fs 1MB 0x00000 firmware/0x00000.bin 0x10000 firmware/0x10000.bin
```

## Notice: xtensa ELF binaries

The .tgz file at the root folder was downloaded from https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz
