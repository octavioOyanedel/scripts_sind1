#!/bin/bash

# FORMATO ENTRADA
# CAMPO ELEMENTO TIPO MODELO NIVELES SIGUIENTE1 SIGUIENTE2 DEPENDENCIA MODAL RELACIONES ETIQUETA

# Funciones

# Variables
archivo="../listado_elementos.txt"
nombre="salida.php"
fecha=$(date +"%d-%m-%Y-%H-%M-%S")
salida="${fecha}_${nombre}"

# Loop principal
while read CAMPO ELEMENTO TIPO MODELO NIVELES SIGUIENTE1 SIGUIENTE2 DEPENDENCIA MODAL RELACIONES ETIQUETA NIVEL

do

echo $CAMPO
	
done < $archivo

chown ooyanedel:ooyanedel *
