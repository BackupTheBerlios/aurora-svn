#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <modules/perl/mod_perl.h>

#define ENGINE_DISABLED             1<<0
#define ENGINE_ENABLED              1<<1
#define ENGINE_INHERIT              1<<2

module MODULE_VAR_EXPORT XS_Aurora;

typedef struct {
  int          state;  
  HV           *config;
} aurora_server;


typedef struct {
  int           state;
  char          *path;
} aurora_server_dir;
