.PHONY: build clean disassemble symboldump copy-init

VFLAG =
V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
VFLAG = -v
else
Q := @
vecho := @echo
endif

ifndef USER_MAIN
override USER_MAIN = "call_user_start"
endif

ifndef INCLUDES
override INCLUDES = ''
endif

BUILD_BASE			= project/build
ESPTOOL					= esptool.py
FW_BASE					= project/firmware
TARGET					= esp8266

# which modules (subdirectories) of the project to include in compiling
MODULES         = project/src
EXTRA_INCDIR    = project/include $(INCLUDES)

# libraries used in this project, mainly provided by the SDK
ifndef LIBS
override LIBS = c gcc hal phy pp net80211 lwip wpa crypto main driver
endif

# compiler flags using during compilation of source files
CFLAGS		= $(VFLAG) -Os -s -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals -D__ets__ -DICACHE_FLASH
CXXFLAGS	= $(VFLAG) $(CFLAGS) -fno-rtti -fno-exceptions -std=c++11 -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals

# linker flags used to generate the main object file
# LDFLAGS		?= -nostdlib -Wl,-static -Wl,--no-check-sections -u $(USER_MAIN) -save-temps

# linker script used for the above linkier step
LD_SCRIPT	= eagle.app.v6.ld

# various paths from the SDK used in this project
SDK_BASE 			= /home/xtensa-gcc/sdk
SDK_LIBDIR		= lib
SDK_LDDIR			= ld
SDK_INCDIR		= include include/json include/sdk driver_lib/include/driver
TOOLS_BASE		= /home/xtensa-gcc

# we create two different files for uploading into the flash
# these are the names and options to generate them
FW_FILE_1_ADDR	= 0x00000
FW_FILE_2_ADDR	= 0x10000

# select which tools to use as compiler, librarian and linker
CC		:= xtensa-lx106-elf-gcc
CXX		:= xtensa-lx106-elf-g++
AR		:= xtensa-lx106-elf-ar
LD		:= xtensa-lx106-elf-gcc

#### no user configurable options below here
SRC_DIR			:= $(MODULES)
BUILD_DIR		:= $(addprefix $(BUILD_BASE)/,$(MODULES))

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))

C_SRC				:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
CXX_SRC			:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.cpp))

C_OBJ				:= $(patsubst %.c,$(BUILD_BASE)/%.o,$(C_SRC))
CXX_OBJ			:= $(patsubst %.cpp,$(BUILD_BASE)/%.o,$(CXX_SRC))

OBJ					:= $(C_OBJ) $(CXX_OBJ)
LIBS				:= $(addprefix -l,$(LIBS))
APP_AR			:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)

LD_SCRIPT		:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT))

INCDIR			:= $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))

FW_FILE_1	:= $(addprefix $(FW_BASE)/,$(FW_FILE_1_ADDR).bin)
FW_FILE_2	:= $(addprefix $(FW_BASE)/,$(FW_FILE_2_ADDR).bin)

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS) -c $$< -o $$@
$1/%.o: %.cpp
	$(vecho) "CXX $$<"
	$(Q) $(CXX) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CXXFLAGS) -c $$< -o $$@
endef

build: clean checkdirs copy-init $(TARGET_OUT) $(FW_FILE_1) $(FW_FILE_2)

copy-init:
	$(Q) cp $(TOOLS_BASE)/esp_init_data_default.bin $(FW_BASE)/0x7c000.bin

$(FW_BASE)/%.bin: $(TARGET_OUT) | $(FW_BASE)
	$(vecho) "FW $(FW_BASE)/"
	$(Q) $(ESPTOOL) elf2image -o $(FW_BASE)/ $(TARGET_OUT)

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD $@"
# $(Q) $(LD) $(VFLAG) $(LD_SCRIPT) -o $@ -L$(SDK_LIBDIR) -Wl,--no-check-sections -Wl,--gc-sections -u $(USER_MAIN) -Wl,-static -Wl,--start-group -lc -lgcc -lhal -lphy -lpp -lnet80211 -llwip -lwpa -lcrypto -lmain -ldriver $(APP_AR) -Wl,--end-group
	$(Q) $(LD) $(VFLAG) $(LD_SCRIPT) -o $@ -L$(SDK_LIBDIR) -nostdlib -Wl,--start-group -lmain -lnet80211 -lwpa -llwip -lpp -lphy -Wl,--end-group -lc -lgcc -lcrypto $(APP_AR)

$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $(VFLAG) $@ $^

checkdirs: $(BUILD_DIR) $(FW_BASE)

$(BUILD_DIR):
	$(Q) mkdir -p $@

$(FW_BASE):
	$(Q) mkdir -p $@

clean:
	$(Q) rm -rf $(FW_BASE)/** $(BUILD_BASE)/**

disassemble:
	xtensa-lx106-elf-objdump -D -S $(TARGET_OUT) > $(addprefix $(BUILD_BASE)/,$(TARGET).asm)

symboldump:
	xtensa-lx106-elf-nm -g $(TARGET_OUT) > $(addprefix $(BUILD_BASE)/,$(TARGET).sym)

$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))