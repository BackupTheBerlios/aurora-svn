#ifdef __cplusplus
extern "C" {
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "config.h"
#ifdef __cplusplus
}
#endif


static void remove_module_cleanup(void *data)
{
  if (ap_find_linked_module(ap_find_module_name(&XS_Aurora))) {
    ap_remove_module(&XS_Aurora);
  }
  /* make sure BOOT section is re-run on restarts */
  (void)hv_delete(GvHV(incgv), "Aurora.pm", 9, G_DISCARD);
  (void)hv_delete(GvHV(incgv), "Aurora/Server/Apache.pm", 23, G_DISCARD);
}


MODULE = Aurora	             PACKAGE = Aurora

PROTOTYPES: DISABLE

BOOT:
  if (!ap_find_linked_module(ap_find_module_name(&XS_Aurora))) {
    ap_add_module(&XS_Aurora);
  }
  ap_register_cleanup(perl_get_startup_pool(), NULL,
		      remove_module_cleanup, null_cleanup);

void
END()
    CODE:
    if (ap_find_linked_module(ap_find_module_name(&XS_Aurora))) {
      ap_remove_module(&XS_Aurora);
    }





