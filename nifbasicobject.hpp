#ifndef __NIF_BASIC_OBJECT_HPP__
#define __NIF_BASIC_OBJECT_HPP__

#include <stdint.h>
#include <string>
typedef unsigned char byte;
typedef uint32_t Ref;
typedef uint16_t hfloat;
typedef std::string IndexString;
typedef std::string HeaderString;
typedef std::string LineString;
class NiObject {
  public:
    NiObject() {}
    ~NiObject() {}
};
class Record {
  public:
    Record() {}
    ~Record() {}
};

#endif
