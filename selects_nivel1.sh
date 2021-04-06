#!/bin/bash

# FORMATO ENTRADA
# CAMPO ELEMENTO TIPO MODELO NIVELES SIGUIENTE1 SIGUIENTE2 DEPENDENCIA MODAL RELACIONES ETIQUETA

# Funciones
function contarGuionesBajos () {
    local resultado="${1//[^_]}"
    echo "${#resultado}"
}

function formatearConGuion () {
    local aux=$1
    local array=($(echo $aux | tr "_" "\n"))
    local formateado=""
    for i in "${array[@]}"
    do
        formateado+=${i^}
    done
    echo $formateado
}

function formatearSinGuion () {
    local aux=$1
    echo ${aux^}
}

function nombreCamelCase () {
    local campo=$1
    local cont_guiones="$(contarGuionesBajos $campo)"
    local nombre=""
    if [ $cont_guiones -eq 0 ]; then
        nombre="$(formatearSinGuion $campo)"
    else
        nombre="$(formatearConGuion $campo)"
    fi
    echo $nombre
}

function comentario () {
    echo -e "/*\n * $1\n */" >> $salida
}

# 1 - nombre variable
function quitarId () {
    echo -e "${1::-3}"
}

# 1 - nombre variable
function varSimple () {
	echo -e "public \$$1 = \"\";" >> $salida
}

# 1 - nombre variable, 2 - valor variable, 3 - tab
function varSimpleThis () {
	tab=""
	if [ "$3" == "tab" ]; then
		tab="\t"
	fi
	echo -e "$tab\$this->$1 = $2;" >> $salida
}

function varNew () {
	echo -e "new_$(quitarId $1)"
}

# 1 - nombre variable
function varArreglo () {
	echo -e "public \$$(quitarId $1)s = [];" >> $salida
}

# 1 - nombre variable
function varNewVacia () {
	echo -e "public \$$(varNew $1) = \"\";" >> $salida
}

function quitarPrimer () {
	echo -e "${1:1}"
}

function minusculaPrimer () {
	echo -e "${1,}"
}

# 1 - nombre genérico, 2 - nombre campo
function nombreEvento () {
	sin_guion="$(quitarId $2)" 
	echo -e "e$1$(nombreCamelCase $sin_guion)"
}

# 1 - nombre genérico, 2 - nombre campo
function nombreMetodo () {
	sin_guion="$(quitarId $2)" 
	echo -e "$1$(nombreCamelCase $sin_guion)"
}

# 1 - nombre genérico, 2 - nombre campo, 3 - valor
function eventoThis () {
	tab=""
	if [ "$4" == "tab" ]; then
		tab="\t"
	fi	
	echo -e "$tab\$this->emit('$(nombreEvento $1 $2)', '$3');"
}

# 1 - nombre genérico, 2 - nombre campo, 3 - valor
function eventoThisVacio () {
	tab=""
	if [ "$3" == "tab" ]; then
		tab="\t"
	fi	
	echo -e "$tab\$this->emit('$(nombreEvento $1 $2)');"
}

# se debe utilizar mismo nombre pasado por parámetro
function eventos () {
	comentario "Escucha de eventos"
	echo -e "protected \$listeners = [" >> $salida
	for evento in ${arreglo_eventos[@]}; do
		aux=$(quitarPrimer $evento)
	  echo -e "\t'$evento' => '$(minusculaPrimer $aux)'," >> $salida
	done
	echo -e "}" >> $salida
}

function metodoRender () {
	comentario "Render select"
	echo -e "public function render()\n{" >> $salida 
	echo -e "\t\$this->poblarSelect();" >> $salida
	echo -e "\treturn view('livewire.socios.forms.select-XXX');" >> $salida
	echo -e "}" >> $salida
}

function metodoPoblarSelect () {
	comentario "Obtener registros para poblar select"
	echo -e "public function poblarSelect()\n{" >> $salida 
	echo -e "\t\$this->$(varNew $1) = $2::orderBy('nombre', 'ASC')->get();" >> $salida
	echo -e "}" >> $salida
}

# 1 - campo, 2 - modelo
function mwetodoNuevoRegistro () {
	comentario "Nuevo registro"
	aux=$(quitarId $1)
	parametro="$(varNew $1)"
	echo -e "public function new$(nombreCamelCase $aux)(\$$parametro)\n{" >> $salida
	varSimpleThis $1 "\"\"" "tab"
	varSimpleThis $parametro \$$parametro "tab"
	# try-catch
    echo -e "\ttry {" >> $salida
    echo -e "\t\t\$this->validate([" >> $salida
    echo -e "\t\t\t'$(varNew $1) => ['required', new Nombre, 'unique:$(quitarId $1)s,nombre']'" >> $salida
    echo -e "\t\t]);" >> $salida
    echo -e "\t} catch (\\Illuminate\\Validation\\ValidationException \$e) {" >> $salida
    echo -e "\t\t\$error = \$e->validator->errors()->get('$(varNew $1)');" >> $salida
    echo -e "\t\t\$this->emit('eErrorValidacion', \$error);" >> $salida
    echo -e "\t\treturn false;" >> $salida
    echo -e "\t}" >> $salida
    # crear
    echo -e "\t\$new = $2::create([" >> $salida
    echo -e "\t\t'nombre' => \$this->$(varNew $1)," >> $salida
    echo -e "\t]);" >> $salida
    # eventos post nuevo registro
    echo -e "\t\$this->$1 = \$new->id;" >> $salida
    eventoThis "Actual" $CAMPO "\$new" "tab" >> $salida
    eventoThis "Cargar" $CAMPO "\$new" "tab" >> $salida
    eventoThis "Ok" $CAMPO "Nuevo registro agregado." "tab" >> $salida
	echo -e "}" >> $salida
}

function metodoResetForm () {
	comentario "Reset form de ventana modal"
	echo -e "public function $(nombreMetodo "resetModal" $1)()\n{" >> $salida 	
	eventoThisVacio "ResetModal" $1 "tab" >> $salida
	echo -e "}" >> $salida
}

# Variables
archivo="listado_elementos.txt"
nombre="salida.php"
fecha=$(date +"%d-%m-%Y-%H-%M-%S")
salida="../${fecha}_${nombre}"

echo "<?php" >> $salida

# Loop principal
while read CAMPO ELEMENTO TIPO MODELO NIVELES SIGUIENTE1 SIGUIENTE2 DEPENDENCIA MODAL RELACIONES ETIQUETA
do
	
	if [ "$NIVELES" == 1 ]; then
		comentario "BLOQUE $CAMPO"

		# Clase Select
		comentario "Clase select $CAMPO"

		varSimple $CAMPO
		varArreglo $CAMPO
		varNewVacia $CAMPO

		# Eventos: cada elemento separado por espacio
		evento=$(nombreEvento "New" $CAMPO)
		arreglo_eventos=($evento) 
		eventos $arreglo_eventos

		metodoRender

		metodoPoblarSelect $CAMPO $MODELO

		mwetodoNuevoRegistro $CAMPO $MODELO

		metodoResetForm $CAMPO

		# Select
		comentario "Select $CAMPO"	
		if [ "$MODAL" == "SI" ]; then
			# Clase Modal
			comentario "Clase modal $CAMPO"
			# Modal
			comentario "Modal $CAMPO"		
		fi	
	fi
done < $archivo		