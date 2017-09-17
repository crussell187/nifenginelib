
GAME := Morrowind
OPENMW_PATH := /mnt/c/Users/Chris/Documents/OpenMW/openmw

export SRCDIR := $(shell pwd)
export TARGET := $(SRCDIR)/target
GPP_FLAGS := -std=c++11 -o3 -I$(TARGET) -I$(SRCDIR) -I/mnt/c/Users/Chris/Documents/OpenMW/openmw/MSVC2017_64/deps/OSG/include -I$(OPENMW_PATH) -I/mnt/c/Users/Chris/Documents/OpenMW/openmw/MSVC2017_64/deps/Boost/boost

TARGET_SRC := $(TARGET)/nifobject.cpp
TARGET_OBJ := $(patsubst %.cpp,%.o, $(TARGET_SRC))

SRC := $(wildcard $(SRCDIR)/*.cpp)
SRC_OBJ := $(patsubst $(SRCDIR)/%.cpp,$(TARGET)/%.o, $(SRC))

NIF_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/nif/*.cpp)
NIF_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/nif/%.cpp,$(TARGET)/%.o, $(NIF_COMPONENT_SRC))
FILE_COMPONENT_SRC := $(wildcard $(OPENMW_PATH)/components/file/*.cpp)
FILE_COMPONENT_SRC_OBJ := $(patsubst $(OPENMW_PATH)/components/file/%.cpp,$(TARGET)/%.o, $(FILE_COMPONENT_SRC))

$(TARGET)/nifread: $(NIF_COMPONENT_SRC_OBJ) $(FILE_COMPONENT_SRC_OBJ) $(SRC_OBJ) $(TARGET_OBJ)
	g++ -lstdc++ -o $@ $^

$(TARGET):
	mkdir -p $@

$(TARGET)/nifrecord.cpp: nif.xml nif_attach.xml parse_nif_format.pl | $(TARGET)
	./parse_nif_format.pl -highestuserversion 1 -namespace NifNew -nifxml $< -nifattachxml nif_attach.xml -game $(GAME) -outdir $(TARGET)

$(TARGET)/nifobject.cpp $(TARGET)/nifrecord.hpp $(TARGET)/nifobject.hpp: $(TARGET)/nifrecord.cpp
	touch $@

$(TARGET_OBJ): $(TARGET)/%.o: $(TARGET)/%.cpp
	g++ $(GPP_FLAGS) -c $< -o $@

$(SRC_OBJ): $(TARGET)/%.o: $(SRCDIR)/%.cpp
	g++ $(GPP_FLAGS) -c $< -o $@

$(NIF_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/nif/%.cpp
	g++ $(GPP_FLAGS) -c $< -o $@

$(FILE_COMPONENT_SRC_OBJ): $(TARGET)/%.o: $(OPENMW_PATH)/components/file/%.cpp
	g++ $(GPP_FLAGS) -c $< -o $@
