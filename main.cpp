#include <stdio.h>
#include <getopt.h>
#include <vector>
#include <map>
#include <string>
#include <components/nif/niffile.hpp>
#include <components/vfs/manager.hpp>
#include <components/vfs/filesystemarchive.hpp>
#include <osg/Vec3f>
#include <osg/Vec4f>
#include <osg/Quat>
/* Flag set by --verbose. */
static int verbose_flag;
int main (int argc, char **argv){
  verbose_flag = 0;
  std::vector<std::string> files;
  while(1){
    static struct option long_options[] =
        {
          /* These options set a flag. */
          {"verbose", no_argument,       &verbose_flag, 1},
          {"brief",   no_argument,       &verbose_flag, 0},
          /* These options dont set a flag.
             We distinguish them by their indices. */
          {"file",    required_argument, 0, 'f'},
          {0, 0, 0, 0}
        };
      /* getopt_long stores the option index here. */
      int option_index = 0;

      int c = getopt_long (argc, argv, "abc:d:f:",
                       long_options, &option_index);

      /* Detect the end of the options. */
      if (c == -1)
        break;

      switch (c)
        {
        case 0:
          /* If this option set a flag, do nothing else now. */
          if (long_options[option_index].flag != 0)
            break;
          printf ("option %s", long_options[option_index].name);
          if (optarg)
            printf (" with arg %s", optarg);
          printf ("\n");
          break;

        case 'f':
          printf ("option -f with value `%s'\n", optarg);
          files.push_back(optarg);
          break;

        case '?':
          /* getopt_long already printed an error message. */
          break;

        default:
          return 1;
        }
    }
  VFS::Manager mVFS(true);
  mVFS.addArchive(new VFS::FileSystemArchive("/mnt/c/Users/Chris/Documents/OpenMW/bsa_data"));
  printf("Building file index.\n");
  mVFS.buildIndex();
  const std::map<std::string, VFS::File*>& fileMap = mVFS.getIndex();
  std::map<std::string, VFS::File*>::const_iterator it = fileMap.begin();
  /*while(it != fileMap.end()){
    printf("file: %s\n",it->first.c_str());
    it++;
  }*/
  printf("sizeof Vec3f: %d\n",(int) sizeof(osg::Vec3f));
  printf("sizeof Vec2f: %d\n",(int) sizeof(osg::Vec2f));
  printf("sizeof Quat: %d\n",(int) sizeof(osg::Quat));
  printf("Reading files\n");
  for(int i = 0; i < files.size(); i++){
    printf("Reading file: %s\n",files[i].c_str());
    for(int j = 0; j < 1000; j++){
      Nif::NIFFilePtr file (new Nif::NIFFile(mVFS.get(files[i]), files[i]));
    }
  }

  return 0;
}
