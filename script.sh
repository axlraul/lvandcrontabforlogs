#!/bin/bash

echo -e "\n\n ********Inicio script********"
echo -e "\n*NGINX*"
echo "-Parando nginx"
systemctl stop nginx

echo "-Tareas posteriores Nginx"
mv /logs/apps/nginx/ /logs/apps/nginx2 &>/dev/null
mkdir /logs/apps/nginx &>/dev/null

echo "--Creación LV"
lvcreate -Wy --yes -L 1GB -n /dev/mapper/datavg-lv_logs_apps_nginx datavg &>/dev/null

echo "--Dar formato a lv"
mkfs.ext4 /dev/mapper/datavg-lv_logs_apps_nginx  &>/dev/null

echo "--Añadir FS /logs/apps/nginx en /etc/fstab"
echo "/dev/mapper/datavg-lv_logs_apps_nginx    /logs/apps/nginx    ext4    defaults    1    2" | sudo tee -a /etc/fstab &>/dev/null
mount -a
mounted=$(df -Th | grep nginx | awk '{print $1}')
mountedok="/dev/mapper/datavg-lv_logs_apps_nginx"

if ! [ "$mounted" == "$mountedok" ]; then

 read -n 1 -s -r -p "Cambio realizado. Avisa a la técnica de sistemas ssmm-mf para que valide la correcta ejecucion antes de continuar. Aprieta cualquier tecla para continuar"

else
 echo "--FS montado con exito"
 mv /logs/apps/nginx2/* /logs/apps/nginx/
 rm -df /logs/apps/nginx2
 echo -e "\n\n*LOGROTATE*"
 echo "-Instalacion logrotate nginx"

 cp -pa /tools/scripts/nginx /etc/logrotate.d/nginx
 logrotate -f /etc/logrotate.d/nginx &>/dev/null
 InstallationLogrotate="ls /logs/apps/nginx/| grep gz | awk '{print $1}'"
 InstallationLogrotateOK="ls /logs/apps/nginx/| grep aaaaaaaaaa | awk '{print $1}'"

 if [ "$InstallationLogrotate" == "$InstallationLogrotateOK" ]; then

  read -n 1 -s -r -p "Cambio realizado. Avisa a la técnica de sistemas ssmm-mf para que valide la correcta ejecucion. Aprieta cualquier tecla para continuar"
  read -n 1 -s -r -p "Press any key to continue"

 else

  echo "--Logrotate instalado con exito"
  echo "--Arranque nginx"

  systemctl start nginx &>/dev/null

  echo -e "--nginx arrancado\n\n\n"
  echo "-Cambio finalizado con exito"

  fi
fi
