# xtensa-gcc compiler for esp8266

Contains:

- ESP_NONOS_SDK v3.0.5
- esptool.py
- xtensa-gcc with gcc 4.8.5

## Usage

### Build a project

```bash
docker run --rm -v $PWD:/home/project homebotz/xtensa-gcc make
```
