
GLOBAL_CONFIG_PATH:=/mnt/c/Users/Chris/Documents/OpenMW/nifxml/etc
GLOBAL_DATA_PATH:=/mnt/c/Users/Chris/Documents/OpenMW/nifxml/games
GAME := Morrowind
ifndef OPENMW_PATH
  OPENMW_PATH := /mnt/c/Users/Chris/Documents/OpenMW/openmw
endif

export SRCDIR := $(shell pwd)
ifndef TARGET_NAME
TARGET_NAME := target
endif
export TARGET := $(SRCDIR)/$(TARGET_NAME)
GPP_FLAGS := -c -fverbose-asm -Wa,-adhln -std=c++11 -g -O3 -D GLOBAL_DATA_PATH="\"$(GLOBAL_DATA_PATH)\"" -D GLOBAL_CONFIG_PATH="\"$(GLOBAL_CONFIG_PATH)\"" -I$(TARGET) -I$(SRCDIR) -I$(OPENMW_PATH) -I/mnt/c/Users/Chris/Documents/OpenMW/boost_1_61_0 -I/usr/include

TARGET_SRC := $(TARGET)/nifobject.cpp
TARGET_OBJ := $(patsubst %.cpp,%.o, $(TARGET_SRC))

#SRC := 
#SRC_OBJ := $(patsubst $(SRCDIR)/%.cpp,$(TARGET)/%.o, $(SRC))

NIF_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/nif/*.cpp)
NIF_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/nif/%.cpp,$(TARGET)/%.o, $(NIF_COMPONENT_SRC))
FILE_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/file/*.cpp)
FILE_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/file/%.cpp,$(TARGET)/%.o, $(FILE_COMPONENT_SRC))
FILES_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/files/*.cpp)
FILES_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/files/%.cpp,$(TARGET)/%.o, $(FILES_COMPONENT_SRC))
VFS_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/vfs/*.cpp)
VFS_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/vfs/%.cpp,$(TARGET)/%.o, $(VFS_COMPONENT_SRC))
BSA_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/bsa/*.cpp)
BSA_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/bsa/%.cpp,$(TARGET)/%.o, $(BSA_COMPONENT_SRC))

all: $(TARGET)/benchmark $(TARGET)/nifread

$(TARGET)/benchmark: $(TARGET)/benchmark.o $(NIF_COMPONENT_SRC_OBJ) $(BSA_COMPONENT_SRC_OBJ) $(FILES_COMPONENT_SRC_OBJ) $(FILE_COMPONENT_SRC_OBJ) $(VFS_COMPONENT_SRC_OBJ) $(SRC_OBJ) $(TARGET_OBJ)
	g++ -v -L/mnt/c/Users/Chris/Documents/OpenMW/boost_1_61_0/stage/lib -lstdc++ -o $@ $^ -lboost_filesystem -lboost_system  -lboost_program_options -lbenchmark -lpthread

$(TARGET)/nifread: $(TARGET)/main.o $(NIF_COMPONENT_SRC_OBJ) $(BSA_COMPONENT_SRC_OBJ) $(FILES_COMPONENT_SRC_OBJ) $(FILE_COMPONENT_SRC_OBJ) $(VFS_COMPONENT_SRC_OBJ) $(SRC_OBJ) $(TARGET_OBJ)
	g++ -v -L/mnt/c/Users/Chris/Documents/OpenMW/boost_1_61_0/stage/lib -lstdc++ -o $@ $^ -lboost_filesystem -lboost_system  -lboost_program_options

$(TARGET):
	mkdir -p $@

$(TARGET)/nifobject.cpp: nif.xml nif_attach.xml parse_nif_format.pl | $(TARGET)
	./parse_nif_format.pl -highestuserversion 1 -namespace NifNew -nifxml $< -nifattachxml nif_attach.xml -game $(GAME) -outdir $(TARGET)

$(TARGET)/nifrecord.hpp $(TARGET)/nifobject.hpp: $(TARGET)/nifobject.cpp | $(TARGET)
	touch $@

$(TARGET_OBJ): $(TARGET)/%.o: $(TARGET)/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)

$(SRC_OBJ) $(TARGET)/main.o $(TARGET)/benchmark.o: $(TARGET)/%.o: $(SRCDIR)/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)

$(NIF_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/nif/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)

$(FILE_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/file/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)

$(FILES_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/files/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)

$(VFS_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/vfs/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)

$(BSA_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/bsa/%.cpp | $(TARGET)
	g++ $(GPP_FLAGS) -c $< -o $@ > $(patsubst %.o,%.s,$@)
