# APRSBeaconISS 
# by Claudio - CX8FS

Este proyecto apunta a informar mediante un Boletín de APRS las próximas pasadas de la ISS sobre determinado punto del planeta.
Se puede adaptar fácilmente para otros satélites.
Es fruto de la curiosidad para generar un sistema totalmente automatizado que reporte información útil via APRS a la comunidad de Radioaficionados en Uruguay.

Pasos del Proceso:
1) Se debe obtener el TLE actualizado mediante un cron que se ejecute una vez al día.
Ej. 59 0 * * * /home/pi/satupdt.sh >/dev/null 2>&1
Para esto se emplea el script satupdt.sh

2) Se obtiene la próxima pasada
Se emplea la compilación de Predict instalada en Debian.
Ej. 0 * * * * /usr/bin/predict -p ISS -o /home/pi/iss.pr >/dev/null 2>&1
Se corre cada una hora por el simple hecho de que la orbita de la ISS demora unos 90 minutos, asi aseguramos que siempre exista una próxima predicción actualizada.
El resultado se almacena en /home/pi/iss.pr.

3) Se genera el Boletín para ser enviado por APRX
Ej. 5 * * * * perl /home/pi/iss.pl >/dev/null 2>&1

El resultado es algo así: 
  :BLN1     :ISS over GF15VC:Orbt2764,AOS:09Nov-20:41U,LOS:09Nov-20:48U
Y se almacena en /var/log/aprx/beacon03.txt

4) APRX se configura para que envíe el beacon cada 60 minutos.
<beacon>
    beaconmode both
    cycle-size 60m
    beacon srccall $mycall via WIDE2-2 file /var/log/aprx/beacon03.txt
</beacon>

Y listo!, solo resta verlo funcionar tomando una cerveza bien fría..

El boletín es enviado mediante APRX de Matti Aarnio, OH2MQK y Kenneth Finnegan - http://thelifeofkenneth.com/aprx/ https://github.com/PhirePhly/aprx.
Se emplea Predict para Linux de John A. Magliacane, KD2BD - http://www.qsl.net/kd2bd/index.html

Claudio - CX8FS
