#include  "config.h"

static void aurora_init(server_rec *s, pool *p) {
  STRLEN len = 0;
  SV *version;
  char *serverstring;
  version = perl_get_sv("Aurora::VERSION", TRUE | GV_ADDMULTI);
  serverstring = ap_psprintf(p, "Aurora/%s", SvPV(version, len));
  ap_add_version_component(serverstring);
}

static void *aurora_directory_init(pool *p, char *path) {
  aurora_server_dir *daurora;
  daurora = (aurora_server_dir *) ap_pcalloc(p, sizeof(aurora_server_dir));
  daurora->state = ENGINE_INHERIT;  
  daurora->path = path;  
  return (void *) daurora;
}


static void *aurora_directory_merge(pool *p, void *base, void *new) {
  aurora_server_dir *merged;
  aurora_server_dir *parent = (aurora_server_dir*) base;
  aurora_server_dir *child = (aurora_server_dir*) new;

  merged = (aurora_server_dir *) ap_pcalloc(p, sizeof(aurora_server_dir));
  merged->path = child->path;
  merged->state = ((child->state == ENGINE_INHERIT)? 
		   ((parent != NULL && parent->state == ENGINE_INHERIT)?
		    ENGINE_DISABLED : parent->state) :
		   child->state);   
  return (void *) merged;
}

static void *aurora_server_init(pool *p, server_rec *s) {
  aurora_server *saurora;
  HV *server_config;
  AV *server;

  saurora = (aurora_server *) ap_pcalloc(p, sizeof(aurora_server));

  server = perl_get_av("Aurora::CONFIG",TRUE); 
  server_config = newHV();

  hv_store(server_config, "Conf", 4, newRV_inc((SV*) newAV()), 0);
  hv_store(server_config, "Base", 4, 
	   newSVpv(ap_server_root_relative(p, ""),0), 0);
  av_push(server, newRV_noinc((SV*)server_config));

  saurora->state    = ENGINE_DISABLED;
  saurora->config   = server_config;

  return (void *) saurora;
}

static const char *aurora_server_config_onoff(cmd_parms *cmd, 
					      aurora_server_dir *daurora, 
					      int *flag) {
  aurora_server *saurora;
  saurora = (aurora_server *) ap_get_module_config(cmd->server->module_config, 
						   &XS_Aurora);
  if (cmd->path == NULL) {
    saurora->state = (flag)? ENGINE_ENABLED : ENGINE_DISABLED;
  }
  if (daurora != NULL) {
    daurora->state = (flag)? ENGINE_ENABLED : ENGINE_DISABLED;
  }
  return NULL;
}

static const char *aurora_server_config_uri(cmd_parms *cmd, 
					    aurora_server_dir *daurora,
					    char *uri) {
  SV **list;
  aurora_server *saurora;
  saurora = (aurora_server *) ap_get_module_config(cmd->server->module_config, 
						    &XS_Aurora);
  if (cmd->path == NULL) {
    list = hv_fetch(saurora->config, "Conf", 4, 0);
    if(list != NULL) {
      av_push((AV*) SvRV(*list), newSVpv(uri,0));
    }
  }
  return NULL;
}

static const char *aurora_server_config_debug(cmd_parms *cmd, 
					      aurora_server_dir *daurora,
					      char *debug) {
  aurora_server *saurora;
  saurora = (aurora_server *) ap_get_module_config(cmd->server->module_config, 
						   &XS_Aurora);
  if (cmd->path == NULL) {
    hv_store(saurora->config, "Debug", 5, newSVpv(debug,0), 0);
  }
  return NULL;
}


static command_rec aurora_server_config_cmds[] = {
  { "Aurora", aurora_server_config_onoff, NULL, OR_FILEINFO, FLAG,
    "On or Off to enable or disable (default) the whole aurora engine" },
  { "AuroraConfig", aurora_server_config_uri, NULL, RSRC_CONF, TAKE1,
    "URI - Location of server configuration file" },
  { "AuroraDebug", aurora_server_config_debug, NULL, RSRC_CONF, TAKE1,
    "[1-10] - Set the debug level of the server loggging" },
  {NULL}
};


static int aurora_server_run(request_rec *r) {
  int retval;
  aurora_server *saurora;
  aurora_server_dir *daurora;
  SV* handler_sv;
  saurora = (aurora_server *) ap_get_module_config(r->server->module_config,
						   &XS_Aurora);
  daurora = (aurora_server_dir *) ap_get_module_config(r->per_dir_config,
						       &XS_Aurora);
    if((daurora != NULL &&  daurora->state == ENGINE_DISABLED) ||
     saurora == NULL || saurora->state == ENGINE_DISABLED) {
    return DECLINED;
  }
  handler_sv = newSVpv("Aurora::run", 0);
  ENTER;
  retval = perl_call_handler(handler_sv, (request_rec *)r, Nullav);
  LEAVE;
  SvREFCNT_dec(handler_sv);
  return retval;
}


module MODULE_VAR_EXPORT XS_Aurora = {
  STANDARD_MODULE_STUFF,
  aurora_init,         /* module initializer */
  aurora_directory_init,  /* per-directory config creator */
  aurora_directory_merge, /* dir config merger */
  aurora_server_init,  /* server config creator */
  NULL,                /* server config merger */
  aurora_server_config_cmds,  /* command table */
  NULL,                /* [7] list of handlers */
  aurora_server_run,   /* [2] filename-to-URI translation */
  NULL,                /* [5] check/validate user_id */
  NULL,                /* [6] check user_id is valid *here* */
  NULL,                /* [4] check access by host address */
  NULL,                /* [7] MIME type checker/setter */
  NULL,                /* [8] fixups */
  NULL,                /* [10] logger */
  NULL,                /* [3] header parser */
  NULL,                /* process initializer */
  NULL,                /* process exit/cleanup */
  NULL,                /* [1] post read_request handling */
};


