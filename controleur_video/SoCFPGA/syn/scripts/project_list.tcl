set PROJECT_DIR  $env(PROJECT_DIR)

# Placer ici la liste des modules complémentaires nécessaires à la synthèse
# Tout ce qui concerne le "hw_support" est décrit dans un fichier a part
set_global_assignment -name QIP_FILE           $PROJECT_DIR/ips/sys_pll/sys_pll.qip
set_global_assignment -name SYSTEMVERILOG_FILE $PROJECT_DIR/SoCFPGA/src/Top.sv




