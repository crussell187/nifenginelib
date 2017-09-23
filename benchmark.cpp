#include <stdio.h>
#include <getopt.h>
#include <vector>
#include <map>
#include <string>
#include <components/nif/niffile.hpp>
#include <components/vfs/manager.hpp>
#include <components/vfs/filesystemarchive.hpp>

#include <benchmark/benchmark.h>

VFS::Manager mVFS(true);
//std::string fileString("meshes/base_anim.nif");
std::string fileString("meshes/bloodsplat.nif");

bool init(){
  mVFS.addArchive(new VFS::FileSystemArchive("/mnt/c/Users/Chris/Documents/OpenMW/bsa_data"));
  printf("Building file index.\n");
  mVFS.buildIndex();
  return true;
}

static void BM_NifRead(benchmark::State& state) {
  static bool initialized = init();
  while (state.KeepRunning()){
    Nif::NIFFilePtr file (new Nif::NIFFile(mVFS.get(fileString), fileString));
  }
}
// Register the function as a benchmark
BENCHMARK(BM_NifRead);

BENCHMARK_MAIN();
