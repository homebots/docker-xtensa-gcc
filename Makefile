.PHONY: build clean disassemble symboldump prepare

VFLAG =
V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @echo
VFLAG = -v
else
Q := @
vecho := @echo
endif

BUILD_BASE			= project/build
FW_BASE					= project/firmware
TARGET					= esp8266
WIFI_SSID				?= ''
WIFI_PASSWORD		?= ''

# which sources of the project to include in compiling
SOURCE					= project/src
EXTRA_INCDIR		= $(INCLUDES) /home/xtensa-gcc-headers/include

# libraries used in this project, mainly provided by the SDK
ifndef LIBS
override LIBS 	= c gcc hal pp phy net80211 lwip wpa crypto ssl main
endif

# compiler flags using during compilation of source files
CFLAGS		= $(VFLAG) -Os -s -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals -D__ets__ -DICACHE_FLASH -DWIFI_SSID='"$(WIFI_SSID)\0"' -DWIFI_PASSWORD='"$(WIFI_PASSWORD)\0"'
CXXFLAGS	= $(VFLAG) $(CFLAGS) -fno-rtti -fno-exceptions -std=c++11 -Wl,--no-check-sections -Wl,--gc-sections -Wl,-static

# linker script
LD_SCRIPT			?= eagle.app.v6.ld

# various paths from the SDK used in this project
TOOLS_BASE		= /home
SDK_BASE 			= $(TOOLS_BASE)/sdk
SDK_LIBDIR		= lib
SDK_LDDIR			= ld
SDK_INCDIR		= include include/json/
HB_INCDIR			= $(TOOLS_BASE)/homebots-sdk/sdk

CC					:= xtensa-lx106-elf-gcc
CXX					:= xtensa-lx106-elf-g++
AR					:= xtensa-lx106-elf-ar
LD					:= xtensa-lx106-elf-gcc
ESPTOOL			:= /home/esptool/bin/esptool.sh

SRC_DIR			:= $(SOURCE)
BUILD_DIR		:= $(addprefix $(BUILD_BASE)/,$(SOURCE))

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))
HB_INCDIR		:= $(addprefix -I,$(HB_INCDIR))

C_SRC				:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
CXX_SRC			:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.cpp))

C_OBJ				:= $(patsubst %.c,$(BUILD_BASE)/%.o,$(C_SRC))
CXX_OBJ			:= $(patsubst %.cpp,$(BUILD_BASE)/%.o,$(CXX_SRC))

OBJ					:= $(C_OBJ) $(CXX_OBJ)
SDK_LIBS		:= $(addprefix -l,$(LIBS))
APP_AR			:= $(addprefix $(BUILD_BASE)/,$(TARGET).a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)

LD_SCRIPT		:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT))

INCDIR			:= $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(HB_INCDIR) $(CFLAGS) -c $$< -o $$@
$1/%.o: %.cpp
	$(vecho) "CXX $$<"
	$(Q) $(CXX) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(HB_INCDIR) $(CXXFLAGS) -c $$< -o $$@
endef

build: clean checkdirs prepare $(TARGET_OUT) $(FW_BASE)/firmware.bin

prepare:
	$(vecho) "Preparing project"
	$(vecho) "Adding RF calibration reset at 0x7b000"
	$(Q) dd bs=1024 count=4 if=/dev/zero of=$(FW_BASE)/0x7b000.bin
	$(vecho) "Adding PHY flags at 0x7c000"
	$(Q) cp $(SDK_BASE)/bin/esp_init_data_default_v08.bin $(FW_BASE)/0x7c000.bin
	$(vecho) "Checking $(ESPTOOL)"
	python --version
	$(ESPTOOL) version

$(FW_BASE)/%.bin: $(TARGET_OUT) | $(FW_BASE)
	$(vecho) "FW $(FW_BASE)/"
	$(Q) $(ESPTOOL) elf2image -o $(FW_BASE)/ $(TARGET_OUT)

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) $(VFLAG) $(LD_SCRIPT) -o $@ -u call_user_start -L$(SDK_LIBDIR) -nostdlib -Wl,--start-group $(SDK_LIBS) $(APP_AR) -Wl,--end-group

$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $(VFLAG) $@ $^

checkdirs:
	$(Q) mkdir -p $(BUILD_DIR) $(FW_BASE)

clean:
	$(Q) rm -rf $(FW_BASE)/** $(BUILD_BASE)/**

disassemble:
	xtensa-lx106-elf-objdump -D -S $(TARGET_OUT) > $(addprefix $(BUILD_BASE)/,$(TARGET).asm)

symboldump:
	xtensa-lx106-elf-nm -g $(TARGET_OUT) > $(addprefix $(BUILD_BASE)/,$(TARGET).sym)

$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))