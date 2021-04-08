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

# 1 - nombre variable, 2 - valor variable, 3 - tab
function varSimpleThisSinSalida () {
	tab=""
	if [ "$3" == "tab" ]; then
		tab="\t"
	fi
	echo -e "$tab\$this->$1 = $2;" 
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

function metodoRenderSelectN1 () {
	comentario "Render select"
	echo -e "public function render()\n{" >> $salida 
	echo -e "\t\$this->poblarSelect();" >> $salida
	echo -e "\t\$this->obtener$(nombreCamelCase $(quitarId $1))Selected();" >> $salida
	echo -e "\treturn view('livewire.socios.forms.select-XXX');" >> $salida
	echo -e "}" >> $salida
}

function metodoRenderSelectN2 () {
	comentario "Render select"
	echo -e "public function render()\n{" >> $salida 
	echo -e "\t\$this->obtener$(nombreCamelCase $(quitarId $1))Selected();" >> $salida
	echo -e "\treturn view('livewire.socios.forms.select-XXX');" >> $salida
	echo -e "}" >> $salida
}

function metodoRenderModal () {
	comentario "Render select"
	echo -e "public function render()\n{" >> $salida 
	echo -e "\treturn view('livewire.socios.forms.modal-XXX');" >> $salida
	echo -e "}" >> $salida
}

# 1 - campo, 2 - modelo, 3 - relaciones, 4 - nivel
function metodoPoblarSelect () {
	comentario "Obtener registros para poblar select"
	relaciones="::"
	parametro=""
	donde=""
	order="orderBy('nombre', 'ASC')->get();"
	if [ "$3" != "NULL" ]; then
		relaciones="::with($3)->"
	fi	
	if [ "$4" == "2" ]; then
		parametro="$(nombreCamelCase $(quitarId $5)) \$$(quitarId $5)"
		donde="where('$5', \$$(quitarId $5)->id)->"
	fi		
	echo -e "public function poblarSelect($parametro)\n{" >> $salida 
	echo -e "\t\$this->$(quitarId $1)s = $2$relaciones$donde$order" >> $salida
	echo -e "}" >> $salida
}

function metodoNuevoModal () {
	comentario "Emite evento para guardar registro"
	echo -e "public function new$(nombreCamelCase $(quitarId $1))()\n{" >> $salida 
	echo -e "\t\$this->emit('$(nombreEvento "New" $1)', \$this->new_$(quitarId $1));" >> $salida
	echo -e "}" >> $salida
}

# 1 - campo, 2 - modelo, 3 - nivel, 4 - siguiente
function metodoNuevoRegistro () {
	comentario "Nuevo registro"
	aux=$(quitarId $1)
	parametro="$(varNew $1)"
	echo -e "public function new$(nombreCamelCase $aux)(\$$parametro)\n{" >> $salida

	# variables
	if [ "$3" == "1" ]; then
		varSimpleThis $1 "\"\"" "tab"
		varSimpleThis $parametro \$$parametro "tab"
	else
		varSimpleThis $parametro \$$parametro "tab"
		varSimpleThis $1 \$"this->$(quitarId $1)_actual" "tab"	
	fi	

	# try-catch
    echo -e "\ttry {" >> $salida
    echo -e "\t\t\$this->validate([" >> $salida
    echo -e "\t\t\t'$(varNew $1)' => ['required', new Nombre, 'unique:$(quitarId $1)s,nombre']," >> $salida
	if [ "$3" == "2" ]; then
		echo -e "\t\t\t'$1' => 'required'," >> $salida
	fi	   
    echo -e "\t\t]);" >> $salida
    echo -e "\t} catch (\\Illuminate\\Validation\\ValidationException \$e) {" >> $salida
    echo -e "\t\t\$error = \$e->validator->errors()->get('$(varNew $1)');" >> $salida
    echo -e "\t\t\$this->emit('eErrorValidacion', \$error);" >> $salida
    echo -e "\t\treturn false;" >> $salida
    echo -e "\t}" >> $salida
    # crear
    echo -e "\t\$new = $2::create([" >> $salida
    echo -e "\t\t'nombre' => \$this->$(varNew $1)," >> $salida
    if [ "$3" == "2" ]; then
		echo -e "\t\t'$1' => \$this->$1," >> $salida
	fi	   
    echo -e "\t]);" >> $salida
    # eventos post nuevo registro
    # identifica registro creado
    echo -e "\t\$this->$1 = \$new->id;" >> $salida   
    eventoThis "Actual" $CAMPO "\$new" "tab" >> $salida
    # procesos a ejecutar al guardar exitosamente registro
    if [ "$3" == "1" ]; then
		eventoThisVacio "Activar" $4 "tab" >> $salida
		eventoThisVacio "Desactivar" $4 "tab" >> $salida
	fi	
	eventoThis "Cargar" $CAMPO "\$new" "tab" >> $salida
    eventoThis "Ok" $CAMPO "Nuevo registro agregado." "tab" >> $salida
	echo -e "}" >> $salida
}
# 1 - campo, 2 - nivel, 3 - dependencia
function metodoResetForm () {
	comentario "Reset form de ventana modal"
	echo -e "public function $(nombreMetodo "resetModal" $1)()\n{" >> $salida 	
	if [ "$2" == "2" ]; then
		eventoThis "NombreModal" $3 "\$this->$(quitarId $3)_actual" "tab" >> $salida
	fi
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

function varCustom () {
	echo -e "public \$$1 = $2;" >> $salida
}

# 1 - campo, 2 - nivel, 3 - siguiente
function metodoObtenerRegistroSeleccionado () {
	comentario "Obtener registro nuevo o seleccionado"
	echo -e "public function obtener$(nombreCamelCase $(quitarId $1))Selected()\n{" >> $salida 
    if [ "$2" == "1" ]; then
    	echo -e "if(\$this->$1 != \"\"){" >> $salida
			eventoThisVacio "Reset" $3 "tab" >> $salida
			eventoThis "Actual" $1 "\$this->obtener$(nombreCamelCase $(quitarId $1))()" "tab" >> $salida
			eventoThisVacio "Activar" $3 "tab" >> $salida
			eventoThis "Selected" $1 "\$this->obtener$(nombreCamelCase $(quitarId $1))()" "tab" >> $salida
		echo -e "else" >> $salida
	    	eventoThisVacio "Reset" $3 "tab" >> $salida
	    	eventoThisVacio "Desactivar" $3 "tab" >> $salida
		echo -e "}" >> $salida
    else
    	echo -e "if(\$this->$1 != \"\"){" >> $salida
			eventoThis "Actual" $1 "\$this->obtener$(nombreCamelCase $(quitarId $1))()" "tab" >> $salida
			eventoThis "Selected" $1 "\$this->obtener$(nombreCamelCase $(quitarId $1))()" "tab" >> $salida
		echo -e "}" >> $salida
	fi		
	echo -e "}" >> $salida
}

# 1 - campo, 2 - dependencia
function metodoRegistroActual () {
	comentario "Registro padre actual"
	echo -e "public function actual$(nombreCamelCase $(quitarId $2))(\$$(quitarId $2))\n{" >> $salida 
	echo -e "\t\$this->$(quitarId $2)_actual == \$$(quitarId $2)['id']" >> $salida
	echo -e "}" >> $salida
}

# 1 - campo, 2 - modelo
function metodoObtenerRegistro () {
	comentario "Obtener registro"
	echo -e "public function obtener$(nombreCamelCase $(quitarId $1))()\n{" >> $salida 
	echo -e "\treturn $2::findOrFail(intval(\$this->$1));" >> $salida
	echo -e "}" >> $salida	
}

# 1 - campo
function metodoReset () {
	comentario "Reset select"
	echo -e "public function resetSelect()\n{" >> $salida
	echo -e "$(varSimpleThisSinSalida $1 "\"\"" "tab" )" >> $salida 
	echo -e "$(varSimpleThisSinSalida $(quitarId $1)s "[]" "tab" )" >> $salida
	echo -e "}" >> $salida	
}
function metodoActivaeEnlace () {
	comentario "Activar enlace nuevo registro"
	echo -e "public function activarEnlace()\n{" >> $salida
	echo -e "\t\$this->enlace_nuevo = true;" >> $salida 
	echo -e "}" >> $salida	
}

function metodoDesactivarEnlace () {
	comentario "Desactivar enlace nuevo registro"
	echo -e "public function desactivarEnlace()\n{" >> $salida
	echo -e "\t\$this->enlace_nuevo = false;" >> $salida 
	echo -e "}" >> $salida	
}

# Variables
archivo="listado_elementos.txt"
nombre="sn2.php"
fecha=$(date +"%d%m%Y%H%M%S")
salida="../${fecha}_${nombre}"

echo "<?php" >> $salida

# Loop principal
while read CAMPO ELEMENTO TIPO MODELO NIVELES SIGUIENTE1 SIGUIENTE2 DEPENDENCIA MODAL RELACIONES ETIQUETA NIVEL
do
	# select nivel 1
	if [ "$NIVELES" == 2 ] && [ "$NIVEL" == 1 ]; then
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

		metodoRenderSelectN1 $CAMPO	

		metodoPoblarSelect $CAMPO $MODELO $RELACIONES $NIVEL 

		metodoNuevoRegistro $CAMPO $MODELO $NIVEL $SIGUIENTE1

		metodoObtenerRegistroSeleccionado $CAMPO $NIVEL $SIGUIENTE1

		metodoObtenerRegistro $CAMPO $MODELO

		metodoResetForm $CAMPO $NIVEL $DEPENDENCIA
	fi

	# select nivel 2
	if [ "$NIVELES" == 2 ] && [ "$NIVEL" == 2 ]; then
		comentario "BLOQUE $CAMPO"

		# Clase Select
		comentario "Clase select $CAMPO"

		# Variables
		varSimple $CAMPO
		varArreglo $CAMPO
		varNewVacia $CAMPO
		varCustom "$(quitarId $DEPENDENCIA)_actual" "NULL"
		varCustom $DEPENDENCIA "NULL"
		varCustom "new_link" "false"

		# Eventos: cada elemento separado por espacio
		evento1=$(nombreEvento "Reset" $CAMPO)
		evento2=$(nombreEvento "Activar" $CAMPO)
		evento3=$(nombreEvento "Desactivar" $CAMPO)
		evento4=$(nombreEvento "Selected" $CAMPO)
		evento5=$(nombreEvento "New" $CAMPO)
		evento6=$(nombreEvento "Actual" $CAMPO)
		arreglo_eventos=($evento1 $evento2 $evento3 $evento4 $evento5 $evento6) 
		eventos $arreglo_eventos

		metodoRenderSelectN2 $CAMPO	

		metodoPoblarSelect $CAMPO $MODELO $RELACIONES $NIVEL $DEPENDENCIA

		metodoNuevoRegistro $CAMPO $MODELO $NIVEL $SIGUIENTE1

		metodoObtenerRegistroSeleccionado $CAMPO $NIVEL $SIGUIENTE1

		metodoRegistroActual $CAMPO $DEPENDENCIA

		metodoObtenerRegistro $CAMPO $MODELO

		metodoReset $CAMPO

		metodoActivaeEnlace 

		metodoDesactivarEnlace

		metodoResetForm $CAMPO $NIVEL $DEPENDENCIA
	fi	
done < $archivo		