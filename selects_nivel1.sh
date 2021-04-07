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
	${place:0:1}
	if [ ${3:0:1} == "$" ]; then
		echo -e "$tab\$this->emit('$(nombreEvento $1 $2)', $3);"
	else
		echo -e "$tab\$this->emit('$(nombreEvento $1 $2)', '$3');"
	fi		
	
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

function metodoRenderSelect () {
	comentario "Render select"
	echo -e "public function render()\n{" >> $salida 
	echo -e "\t\$this->poblarSelect();" >> $salida
	echo -e "\treturn view('livewire.socios.forms.select-XXX');" >> $salida
	echo -e "}" >> $salida
}

function metodoRenderModal () {
	comentario "Render select"
	echo -e "public function render()\n{" >> $salida 
	echo -e "\treturn view('livewire.socios.forms.modal-XXX');" >> $salida
	echo -e "}" >> $salida
}

function metodoPoblarSelect () {
	comentario "Obtener registros para poblar select"
	echo -e "public function poblarSelect()\n{" >> $salida 
	echo -e "\t\$this->$(varNew $1) = $2::orderBy('nombre', 'ASC')->get();" >> $salida
	echo -e "}" >> $salida
}

function metodoNuevoModal () {
	comentario "Emite evento para guardar registro"
	echo -e "public function new$(nombreCamelCase $(quitarId $1))()\n{" >> $salida 
	echo -e "\t\$this->emit('$(nombreEvento "New" $1)', \$this->new_$(quitarId $1));" >> $salida
	echo -e "}" >> $salida
}

# 1 - campo, 2 - modelo
function metodoNuevoRegistro () {
	comentario "Nuevo registro"
	aux=$(quitarId $1)
	parametro="$(varNew $1)"
	echo -e "public function new$(nombreCamelCase $aux)(\$$parametro)\n{" >> $salida
	varSimpleThis $1 "\"\"" "tab"
	varSimpleThis $parametro \$$parametro "tab"
	# try-catch
    echo -e "\ttry {" >> $salida
    echo -e "\t\t\$this->validate([" >> $salida
    echo -e "\t\t\t'$(varNew $1)' => ['required', new Nombre, 'unique:$(quitarId $1)s,nombre']," >> $salida
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

function metodoResetFormModal () {
	comentario "Reset form de ventana modal"
	echo -e "public function resetForm()\n{" >> $salida 	
	varSimpleThis "new_$(quitarId $1)" "\"\"" "tab"
	echo -e "}" >> $salida
}

# 1 - campo, 2 - modal 
function elementoSelect () {
	echo -e "<div>" >> $salida
	echo -e "\t<div class=\"position-relative form-group\">" >> $salida
	echo -e "\t\t<label for=\"$1\" class=\"\">" >> $salida
	echo -e "\t\t\t<b>$2</b>" >> $salida
		if [ "$MODAL" == "SI" ]; then
		echo -e "\t\t\t<a wire:click=\"$(nombreMetodo "resetModal" $1)\" href=\"javascript:void(0)\" style=\"float: right;\" data-toggle=\"modal\" data-target=\"#$(nombreCamelCase $(quitarId $1))Modal\">" >> $salida
			echo -e "\t\t\t\t<i class=\"mt-1 fas fa-plus-circle text-success\"></i>" >> $salida
		echo -e "\t\t\t</a>" >> $salida
		fi	
	echo -e "\t\t\t<select wire:model=\"$1\" name=\"$1\" id=\"$1\" class=\"form-control form-control-sm\">" >> $salida
	echo -e "\t\t\t\t<option value=\"\">...</option>" >> $salida
	echo -e "\t\t\t\t@foreach(\$$(quitarId $1)s as \$$(quitarId $1))" >> $salida
	echo -e "\t\t\t\t\t<option value=\"{{\$nacion_socio->id}}\">{{\$nacion_socio->nombre}}</option>" >> $salida
	echo -e "\t\t\t\t@endforeach" >> $salida
	echo -e "\t\t\t</select>" >> $salida		
	echo -e "\t\t</label>" >> $salida
	echo -e "\t</div>" >> $salida
	echo -e "</div>" >> $salida
}

# 1 - campo, 2 etiqueta
function elementoModal () {
	echo -e "<div>" >> $salida
	echo -e "\t<div wire:ignore.self class=\"modal fade\" id=\"modal$(nombreCamelCase $(quitarId $1))\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"modal$(nombreCamelCase $(quitarId $1))Label\" aria-hidden=\"true\">" >> $salida
	echo -e "\t\t<div class=\"modal-dialog\" role=\"document\">" >> $salida
	echo -e "\t\t\t<div class=\"modal-content\">" >> $salida
	echo -e "\t\t\t\t<div class=\"modal-header\">" >> $salida
	echo -e "\t\t\t\t\t<h5 class=\"modal-title\" id=\"modal$(nombreCamelCase $(quitarId $1))Label\">Nuev@ $2</h5>" >> $salida
	echo -e "\t\t\t\t\t<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\">" >> $salida
	echo -e "\t\t\t\t\t\t<span aria-hidden=\"true\">&times;</span>" >> $salida
	echo -e "\t\t\t\t\t</button>" >> $salida
	echo -e "\t\t\t\t</div>" >> $salida
	echo -e "\t\t\t\t<div class=\"modal-body\">" >> $salida
	echo -e "\t\t\t\t\t<div class=\"position-relative form-group\">" >> $salida
	echo -e "\t\t\t\t\t\t<label for=\"new_$(quitarId $1)\" class=\"\"><b>Nombre</b></label>" >> $salida
	echo -e "\t\t\t\t\t\t<input wire:model=\"new_$(quitarId $1)\" name=\"new_$(quitarId $1)\" id=\"new_$(quitarId $1)\" placeholder=\"\" type=\"text\" class=\"form-control form-control-sm @if(Session::has('new_$(quitarId $1)')) is-invalid @enderror mb-1\">" >> $salida
	echo -e "\t\t\t\t\t\t@if(Session::has('new_$(quitarId $1)'))" >> $salida
	echo -e "\t\t\t\t\t\t\t<small class=\"text-danger\">{{ Session::get('new_$(quitarId $1)') }}</small>" >> $salida
	echo -e "\t\t\t\t\t\t@enderror" >> $salida
	echo -e "\t\t\t\t\t</div>	" >> $salida
	echo -e "\t\t\t\t</div>" >> $salida
	echo -e "\t\t\t\t<div class=\"modal-footer\">" >> $salida
	echo -e "\t\t\t\t\t<button type=\"button\" id=\"cerrarModal$(nombreCamelCase $(quitarId $1))\" class=\"btn btn-secondary\" data-dismiss=\"modal\">Salir</button>" >> $salida
	echo -e "\t\t\t\t\t<button wire:click=\"new$(nombreCamelCase $(quitarId $1))\" type=\"button\" class=\"btn btn-primary\">Guardar</button>" >> $salida
	echo -e "\t\t\t\t</div>" >> $salida
	echo -e "\t\t\t</div>" >> $salida
	echo -e "\t\t</div>" >> $salida
	echo -e "\t</div>" >> $salida
	echo -e "</div>" >> $salida
}

# 1 - campo
function cerrarModal () {
	echo -e "<script type=\"text/javascript\">" >> $salida >> $salida
	echo -e "\twindow.livewire.on('eCargar$(nombreCamelCase $(quitarId $1))', $(quitarId $1) => {" >> $salida
	echo -e "\t\t\$('#$1 option[value=\"'+$(quitarId $1).id+'\"]').remove();" >> $salida
	echo -e "\t\t\t\$(\"#$1\").append('<option value=\"'+$(quitarId $1).id+'\" selected="selected">'+$(quitarId $1).nombre+'</option>');" >> $salida
	echo -e "\t\t\$(\"#cerrarModal$(nombreCamelCase $(quitarId $1))\").click();" >> $salida
	echo -e "\t});" >> $salida
	echo -e "</script>" >> $salida
}

# 1 - campo
function metodoErrorValidacion () {
	comentario "Dispone mensaje (flash) de error en validación de form modal en ventana modal"
	echo -e "public function $(nombreEvento "ErrorValidacion") ""()\n{" >> $salida 
	echo -e "\tSession::flash('new_$(quitarId $1)',\$error[0]);" >> $salida
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

		# Variables
		varSimple $CAMPO
		varArreglo $CAMPO
		varNewVacia $CAMPO

		# Eventos: cada elemento separado por espacio
		evento=$(nombreEvento "New" $CAMPO)
		arreglo_eventos=($evento) 
		eventos $arreglo_eventos

		metodoRenderSelect

		metodoPoblarSelect $CAMPO $MODELO

		metodoNuevoRegistro $CAMPO $MODELO

		metodoResetForm $CAMPO

		# Select
		comentario "Select $CAMPO"	

		elementoSelect $CAMPO $ETIQUETA

		if [ "$MODAL" == "SI" ]; then

			# Clase Modal
			comentario "Clase modal $CAMPO"

			# Variables
			varNewVacia $CAMPO

			# Eventos: cada elemento separado por espacio
			evento1=$(nombreEvento "ResetModal" $CAMPO)
			evento2=$(nombreEvento "ErrorValidacion" "")
			arreglo_eventos=($evento1 $evento2) 
			eventos $arreglo_evento

			comentario "Modal $CAMPO"

			metodoRenderModal

			metodoNuevoModal $CAMPO

			metodoErrorValidacion $CAMPO		

			metodoResetFormModal $CAMPO

			# Modal
			elementoModal $CAMPO $ETIQUETA

			cerrarModal $CAMPO

		fi	
	fi
done < $archivo		