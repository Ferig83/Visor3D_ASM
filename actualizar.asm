
Actualizar_Todo:

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE

;_______Reinicio el array de rasterización	

	xor rax, rax
	mov [array_rasterizacion+ARRAY_DINAMICO__cantidad_elementos], rax 

;_______Ahora actualizo todos los elementos


	; Actualizamos la cámara primero

	call Actualizar_Camara

	; Luego los objetos 3D

	mov rcx, almohadas
	call Actualizar_Objeto

	mov rcx, colchon
	call Actualizar_Objeto

	mov rcx, marcos
	call Actualizar_Objeto

	mov rcx, mesa
	call Actualizar_Objeto

	mov rcx, muebles
	call Actualizar_Objeto

	mov rcx, paredes
	call Actualizar_Objeto

	mov rcx, piso
	call Actualizar_Objeto

	mov rcx, techo
	call Actualizar_Objeto



	xor rax,rax

	mov rsp, rbp
	pop rbp

	ret

;------------------------------------------------------------------------------	


Actualizar_Camara:


	; Actualizo la rotación hacia los lados

	mov rcx, matriz_multiplicacion
	mov edx, [giro_camara]
	call Inicializar_Matriz_Rotacion_Y

	mov rcx, vector_camara_delante	
	mov rdx, matriz_multiplicacion
	mov r8, vector_camara_delante
	call Multiplicar_Vector_Matriz

	; Reseteo el giro para que no siga girando en cada actualización

	mov eax, 0
	mov [giro_camara], eax
	

;_______Preparo la matriz "Apuntar Cámara" que es una matriz auxiliar que lleva los objetos frente a la cámara.
; 	Sin embargo, no vamos a usar esta matriz sino su inversa porque lo que queremos es que todo lo que esté
;	frente a la cámara se ubique en una zona centrada en el origen de coordenadas. Nosotros siempre vamos a ver
;	esa zona.

					
	mov rcx, matriz_apuntar_camara
	mov rdx, vector_camara_delante
	mov r8, vector_camara_arriba
	mov r9, vector_camara_posicion
	call Inicializar_Matriz_Apuntar_Camara

;_______Con esta matriz armo la inversa y obtenemos la matriz "Capturar Cámara" que es la que nos va a ubicar
;	los triángulos en donde queremos (cuboide centrado en el origen). 

	mov rcx, matriz_capturar_camara
	mov rdx, matriz_apuntar_camara   
	call Inicializar_Matriz_Capturar_Camara  

	ret

;------------------------------------------------------------------------------

	
Actualizar_Objeto:

%define lista_clipping			rbp - 5360 ; 5120  (TRIANGULO_size*80) - DEBE ESTAR ALINEADO A 16
%define padding				rbp - 240  ; 12 bytes de padding para que lo de arriba esté alineado a 16 bytes
%define queue_circular_clipping		rbp - 228  ; 56 bytes 
%define puntero_estructura		rbp - 172  ; 8 bytes
%define factor_visibilidad_triangulo   	rbp - 164  ; 4 bytes
%define vector_triangulo_a_camara  	rbp - 160  ; 16 bytes 
%define normal_triangulo 		rbp - 144  ; 16 bytes
%define triangulo_transformado		rbp - 128  ; 64 bytes (TRIANGULO_size) - DEBE ESTAR ALINEADO A 16
%define triangulo_a_analizar		rbp - 64   ; 64 bytes (TRIANGULO_size) - DEBE ESTAR ALINEADO A 16

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE+5424 ; revisar esta cantidad. Ojo los parametros. No hay, pero ojito (?

	push r12
	push r13
	push r14
	push r15



;_______Guardo el puntero de la estructura de la figura a actualizar, la cual contiene todos los datos


	mov [puntero_estructura], rcx
	

;_______Actualizo las coordenadas de los triángulos según tiempo pasado. 


	; Rotación en X 

	
	fld dword [rcx+OBJETO_3D__angulo_x]
	fld dword [temporizador+TIMER__tiempo_transcurrido]
	fld dword [rcx+OBJETO_3D__velocidad_angular_x]
	fmulp
	faddp
	fstp dword [rcx+OBJETO_3D__angulo_x]


	; Rotación en Y 

	
	fld dword [rcx+OBJETO_3D__angulo_y]
	fld dword [temporizador+TIMER__tiempo_transcurrido]
	fld dword [rcx+OBJETO_3D__velocidad_angular_y]
	fmulp
	faddp
	fstp dword [rcx+OBJETO_3D__angulo_y]


	; Rotación en Z 

	fld dword [rcx+OBJETO_3D__angulo_z]
	fld dword [temporizador+TIMER__tiempo_transcurrido]
	fld dword [rcx+OBJETO_3D__velocidad_angular_z]
	fmulp
	faddp
	fstp dword [rcx+OBJETO_3D__angulo_z]


;_______Ahora vamos a preparar una serie de transformaciones. Hacemos primero las transformaciones
;	del ESPACIO OBJETO (rotación, escalamiento y trasquilación) y luego hacemos la del ESPACIO
;	MUNDO que es la de traslación. Lo juntamos todo para más tarde multiplicar las coordenadas
;	de la figura por una sola matriz (de momento no veo necesario separar las transformaciones) 	

;	Nota: "matriz_multiplicacion" es tan solo una matriz auxiliar

	
	xor rax,rax

	; Agrego la rotación en Z

	mov rcx, matriz_multiplicacion
	mov r8, [puntero_estructura]
	mov edx, [r8+OBJETO_3D__angulo_z]
	call Inicializar_Matriz_Rotacion_Z
	mov rcx, matriz_mundo
	mov rdx, matriz_multiplicacion
	call Multiplicar_Matriz_Matriz


	; Agrego la rotación en Y

	mov rcx, matriz_multiplicacion
	mov r8, [puntero_estructura]
	mov edx, [r8+OBJETO_3D__angulo_y]
	call Inicializar_Matriz_Rotacion_Y
	mov rcx, matriz_mundo
	mov rdx, matriz_multiplicacion
	call Multiplicar_Matriz_Matriz


	; Agrego rotación en X
	
	mov rcx, matriz_multiplicacion
	mov r8, [puntero_estructura]
	mov edx, [r8+OBJETO_3D__angulo_x] 
	call Inicializar_Matriz_Rotacion_X
	mov rcx, matriz_mundo
	mov rdx, matriz_multiplicacion
	call Multiplicar_Matriz_Matriz

	; Agrego escalamiento general

	mov rcx, matriz_multiplicacion
	mov rax, [puntero_estructura]
	mov edx, [rax+OBJETO_3D__escala_general]
	mov r8d, [rax+OBJETO_3D__escala_general]
	mov r9d, [rax+OBJETO_3D__escala_general]
	call Inicializar_Matriz_Escalamiento
	mov rcx, matriz_mundo
	mov rdx, matriz_multiplicacion
	call Multiplicar_Matriz_Matriz
	

	; Agrego traslación


	mov rcx, matriz_multiplicacion
	mov rax, [puntero_estructura]
	mov edx, [rax+OBJETO_3D__posicion_x]
	mov r8d, [rax+OBJETO_3D__posicion_y]
	mov r9d, [rax+OBJETO_3D__posicion_z] 
	call Inicializar_Matriz_Traslacion	
	mov rcx, matriz_mundo
	mov rdx, matriz_multiplicacion
	call Multiplicar_Matriz_Matriz


	; Ahora en "matriz_mundo" tengo la transformación (puedo descartar matriz_multiplicacion)


;_______Tenemos todo para tomar la imagen con la cámara, pero necesito saber cuales triángulos rasterizar
; 	y cuales no, así que no puedo unificar las matrices como quisiera en una sola transformación. Debería
;	sacar la normal de cada triángulo, chequear si está enfrentado a la cámara y si es así, continuar
;	con el resto de las transformaciones. 
;
;	Como primer paso itero los triángulos multiplicándolos con matriz_mundo y verificando cuales entran
;	en la rasterización.	


	mov r14, [puntero_estructura]
	mov r15, [r14+OBJETO_3D__puntero_triangulos]
	xor r12, r12   ; Contador de triángulos totales del objeto


.loop_analizar_si_se_ve:

	lea r13, [triangulo_transformado]


	; Transformo al ESPACIO MUNDO los tres vectores del triángulo

	lea rcx, [r15+TRIANGULO__vertice1]	
	mov rdx, matriz_mundo
	lea r8, [triangulo_a_analizar+TRIANGULO__vertice1]
	call Multiplicar_Vector_Matriz
	
	lea rcx, [r15+TRIANGULO__vertice2]	
	mov rdx, matriz_mundo
	lea r8, [triangulo_a_analizar+TRIANGULO__vertice2]
	call Multiplicar_Vector_Matriz
	
	
	lea rcx, [r15+TRIANGULO__vertice3]	
	mov rdx, matriz_mundo
	lea r8, [triangulo_a_analizar+TRIANGULO__vertice3]
	call Multiplicar_Vector_Matriz


	; Copio el código de color de paso

	
	lea rdx, [r15+TRIANGULO__color]
	mov eax, [rdx]
	lea r8, [triangulo_a_analizar+TRIANGULO__color]
	mov [r8], eax


	; Obtengo la normal del triangulo


	lea rcx, [triangulo_a_analizar]
	lea rdx, [normal_triangulo]
	call Obtener_Normal_Triangulo
	
	
	; Ahora saco el vector que va desde el triángulo a la cámara. Elijo usar
	; uno de los vertices (el primero) porque total todos viven en un solo
	; plano así que da igual cuál use.

;TODO 	; Probablemente necesite reemplazar ese vector de posición de cámara
	

	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__x]
	fld dword [vector_camara_posicion+VECTOR4__1]
	fsubp
	fstp dword [vector_triangulo_a_camara+VECTOR4__1]
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__y]
	fld dword [vector_camara_posicion+VECTOR4__2]
	fsubp
	fstp dword [vector_triangulo_a_camara+VECTOR4__2]
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__z]
	fld dword [vector_camara_posicion+VECTOR4__3]
	fsubp
	fstp dword [vector_triangulo_a_camara+VECTOR4__3]

;_______Ahora hago el producto escalar de la normal y el vector que saqué arriba

	fld dword [normal_triangulo+VECTOR4__1]
	fld dword [vector_triangulo_a_camara+VECTOR4__1]
	fmulp
	fld dword [normal_triangulo+VECTOR4__2]
	fld dword [vector_triangulo_a_camara+VECTOR4__2]
	fmulp
	fld dword [normal_triangulo+VECTOR4__3]
	fld dword [vector_triangulo_a_camara+VECTOR4__3]
	fmulp
	faddp
	faddp
	fldz  

	; Si el producto vectorial es menor a 0, el triangulo se va a ver
	; y sino, lo salteamos saltando a ".continuar"

	fcomip st0,st1
	fstp st0
	jbe .continuar


;_______A partir de acá van las instrucciones si el producto escalar es menor a 0, es 
; 	decir, si el triángulo está enfrentado a la cámara. Lo que se hace es aplicarles
; 	el resto de las transformaciones y luego subirlos a la lista de triangulos a rasterizar.


;_______Primero genero las matrices como para tomar todos los triángulos del ESPACIO MUNDO
;	y llevarlos al ESPACIO CÁMARA. 


	; Aplico las transformaciones al triángulo

	lea rcx, [triangulo_a_analizar+TRIANGULO__vertice1]
	mov rdx, matriz_capturar_camara
	lea r8, [r13+TRIANGULO__vertice1]
	call Multiplicar_Vector_Matriz

	lea rcx, [triangulo_a_analizar+TRIANGULO__vertice2]
	mov rdx, matriz_capturar_camara
	lea r8, [r13+TRIANGULO__vertice2]
	call Multiplicar_Vector_Matriz


	lea rcx, [triangulo_a_analizar+TRIANGULO__vertice3]
	mov rdx, matriz_capturar_camara	
	lea r8, [r13+TRIANGULO__vertice3]
	call Multiplicar_Vector_Matriz


;_______Ahora vamos a recortar los triángulos que están muy próximos a la pantalla o muy lejos

	
	; Inicializo el queue circular donde voy a meter los nuevos triángulos
	
	lea rcx, [queue_circular_clipping]
	mov rdx, 80  ; cantidad de elementos que va a tener la lista como mucho
	mov r8, TRIANGULO_size
	lea r9, [lista_clipping]
	call Inicializar_Queue_Circular	


	; Efectúo el Z Clipping

	mov rcx, r13
	lea rdx, [queue_circular_clipping]	
	call Z_Clipping

	lea rcx, [queue_circular_clipping]
	call Cantidad_Elementos_Queue_Circular

	
	; Se devuelve en RAX la cantidad de triángulos (como mucho son 4), por lo que la usaré para hacer
	; un loop y proyectar cada uno de ellos del queue_circular

	mov r14b, al

;_______Acá voy a proyectar cada elemento del queue circular y voy a volcar lo proyectado
;	en el otro queue circular usado para el clipping de proyección.

	lea r13, [triangulo_transformado]	


.loop_z_clipping_a_proyeccion:


	cmp r14b, 0
	je .fin_z_clipping


	lea rcx, [queue_circular_clipping]
	lea rdx, [triangulo_transformado]
	call Pop_Primer_Elemento_de_Queue_Circular
	


;_______Llevo los triángulos desde el ESPACIO CÁMARA al ESPACIO PROYECCIÓN


	lea rcx, [r13+TRIANGULO__vertice1]
	mov rdx, matriz_proyeccion
	lea r8, [r13+TRIANGULO__vertice1]
	call Multiplicar_Vector_Matriz

	lea rcx, [r13+TRIANGULO__vertice2]
	mov rdx, matriz_proyeccion
	lea r8, [r13+TRIANGULO__vertice2]
	call Multiplicar_Vector_Matriz


	lea rcx, [r13+TRIANGULO__vertice3]
	mov rdx, matriz_proyeccion	
	lea r8, [r13+TRIANGULO__vertice3]
	call Multiplicar_Vector_Matriz

	

;_______Muevo el color, y lo hago así medio manual porque son 3 bytes	

	mov eax, [triangulo_a_analizar+TRIANGULO__color]
	mov r8, r13
	add r8, TRIANGULO__color 
	mov [r8], eax


;_______Una vez que tengo cargado el color hago varío el mismo según sombra

	; Recupero la normal pero desde la proyección para iluminar siempre de frente

	; *** QUITAR ESTAS TRES LINEAS SI SE QUIERE QUE LA LUZ ESTE FIJA APUNTANDO EN (0;0;1) SIEMPRE

;	mov rcx, r13  
;	lea rdx, [normal_triangulo]   
;	call Obtener_Normal_Triangulo  



	mov rcx, r13
	lea rdx, [normal_triangulo]
	mov r8, vector_luz
	call Iluminar_Triangulo


	; Divido cada componente x,y,z por w  (sería como dividir por el z previo a la transformación)
	; En el proceso también invierto x e y, ya que la proyección me los da vuelta.
	
	fld dword [r13+TRIANGULO__vertice1+VERTICE__x]
	fchs
	fld dword [r13+TRIANGULO__vertice1+VERTICE__y]
	fchs
	fld dword [r13+TRIANGULO__vertice1+VERTICE__z]
	fld dword [r13+TRIANGULO__vertice1+VERTICE__w]
	fdiv st1, st0
	fdiv st2, st0
	fdiv st3, st0
	fstp st0
	fstp dword [r13+TRIANGULO__vertice1+VERTICE__z]
	fstp dword [r13+TRIANGULO__vertice1+VERTICE__y]
	fstp dword [r13+TRIANGULO__vertice1+VERTICE__x]

	fld dword [r13+TRIANGULO__vertice2+VERTICE__x]
	fchs
	fld dword [r13+TRIANGULO__vertice2+VERTICE__y]
	fchs
	fld dword [r13+TRIANGULO__vertice2+VERTICE__z]
	fld dword [r13+TRIANGULO__vertice2+VERTICE__w]
	fdiv st1, st0
	fdiv st2, st0
	fdiv st3, st0
	fstp st0
	fstp dword [r13+TRIANGULO__vertice2+VERTICE__z]
	fstp dword [r13+TRIANGULO__vertice2+VERTICE__y]
	fstp dword [r13+TRIANGULO__vertice2+VERTICE__x]

	fld dword [r13+TRIANGULO__vertice3+VERTICE__x]
	fchs
	fld dword [r13+TRIANGULO__vertice3+VERTICE__y]
	fchs
	fld dword [r13+TRIANGULO__vertice3+VERTICE__z]
	fld dword [r13+TRIANGULO__vertice3+VERTICE__w]
	fdiv st1, st0
	fdiv st2, st0
	fdiv st3, st0
	fstp st0
	fstp dword [r13+TRIANGULO__vertice3+VERTICE__z]
	fstp dword [r13+TRIANGULO__vertice3+VERTICE__y]
	fstp dword [r13+TRIANGULO__vertice3+VERTICE__x]


	lea rcx, [queue_circular_clipping]
	mov rdx, r13
	call Agregar_Elemento_en_Queue_Circular	

	; Paso al elemento siguiente

	dec r14b
	
	jmp .loop_z_clipping_a_proyeccion
		

.fin_z_clipping:


;_______Procedo a recortar los triángulos en los planos de la ventana

	lea rcx, [queue_circular_clipping]
	call Clipping_Proyeccion

	lea rcx,  [queue_circular_clipping]
	call Cantidad_Elementos_Queue_Circular
	mov r14b, al
	lea r13, [triangulo_transformado]
	

.loop_clipping_proyeccion:


	cmp r14b, 0
	je .fin_loop_clipping_proyeccion

	lea rcx,  [queue_circular_clipping]
	mov rdx, r13
	call Pop_Primer_Elemento_de_Queue_Circular

	push r12
	xor r12,r12 

.loop_viewport:

	; Hago la división que me quedaba por hacer del ESPACIO PROYECCIÓN y le sumo:
	;
	;	1) Sumarle 1 a (x,y) ya que están en el intervalo [-1,1]. Así pasan a [0,2]
	;	2) Multiplicarlas por el ancho/alto de la ventana correspondiente dividido dos
	;	   para estirar la imagen normalizada a la ventana
	;	3) No forma parte de la transformación, pero poner los triángulos en el array de rasterización

	
	fld dword [r13+VECTOR4__1]
	fld1       
	faddp
	fld dword [MitadAnchoPantalla]
	fmulp
	fistp dword [r13+VECTOR4__1]


	; Vamos con Y

	fld dword [r13+VECTOR4__2]
	fld1
	faddp
	fld dword [MitadAltoPantalla]
	fmulp
	fistp dword [r13+VECTOR4__2]


	inc r12
	add r13, VECTOR4_size  
	cmp r12, 3
	jne .loop_viewport
	pop r12


	; Vuelvo al offset 0 del triángulo

	sub r13, VECTOR4_size*3


	mov rcx, array_rasterizacion    
	mov rdx, r13
	call Pushback_Array_Dinamico
	

	dec r14b

	jmp .loop_clipping_proyeccion


.fin_loop_clipping_proyeccion:
	

.continuar:
	
	
	add r15, TRIANGULO_size
	inc r12 


	mov rax, [puntero_estructura]
	cmp r12d, [rax+OBJETO_3D__cantidad_triangulos]
	jb .loop_analizar_si_se_ve



;_______Todo listo para rasterizar!



	pop r15
	pop r14
	pop r13
	pop r12

	;Reinicio la matriz_mundo, así no me acumula transformaciones
	
	mov rcx, matriz_mundo	
	call Inicializar_Matriz_Identidad

	xor rax, rax	
	mov rsp, rbp
	pop rbp
	ret


%undef lista_clipping		
%undef padding				
%undef queue_circular_clipping	 
%undef puntero_estructura		
%undef factor_conversion		
%undef factor_sombra			
%undef factor_visibilidad_triangulo   	
%undef vector_triangulo_a_camara  	 
%undef normal_triangulo 		
%undef triangulo_transformado		
%undef triangulo_a_analizar		



;--------------------------------------------------------------------

Z_Clipping:

	; rcx: Dirección del triángulo
	; rdx: Dirección del la estructura del queue circular donde van los triángulos

%define triangulo_transitorio		rbp - 208 ; 64 bytes (TRIANGULO_size) - DEBEN ESTAR ALINEADOS A 16 BYTES 
%define direccion_triangulo  		rbp - 144 ; 8 bytes	
%define direccion_queue 		rbp - 136 ; 8 bytes	
%define triangulo2 			rbp - 128 ; 64 bytes (TRIANGULO_size) - DEBEN ESTAR ALINEADOS A 16 BYTES
%define triangulo1 			rbp - 64  ; 64 bytes (TRIANGULO_size) - DEBEN ESTAR ALINEADOS A 16 BYTES	

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 256

	push r13  
	push r13 ; lo hago doble por tema de alinemiento a 16 (requerido para SSE)


	mov [direccion_triangulo], rcx
	mov [direccion_queue], rdx

	; Ya tengo la dirección del triángulo en rcx

	mov rdx, plano_near 
	lea r8, [triangulo1]
	lea r9, [triangulo2] 
	call Recortar_Triangulo



	cmp rax, 1 
  	jb .fin			; No se crearon triángulos? salimos sin testear el plano far
	je .un_triangulo_near   ; Se creo un triángulo ? 
	ja .dos_triangulos_near	; Se crearon dos triángulos?

 
.un_triangulo_near:


	mov rcx, [direccion_queue]
	lea rdx, [triangulo1]	
	call Agregar_Elemento_en_Queue_Circular	

	jmp .fin_plano_near

.dos_triangulos_near:
		

	mov rcx, [direccion_queue]
	lea rdx, [triangulo1]	
	call Agregar_Elemento_en_Queue_Circular

	mov rcx, [direccion_queue]		
	lea rdx, [triangulo2]	
	call Agregar_Elemento_en_Queue_Circular

	jmp .fin_plano_near

.fin_plano_near:	
	
	mov rcx, [direccion_queue]
	call Cantidad_Elementos_Queue_Circular
	mov r13, rax


.loop_plano_far:

	cmp r13, 0
	je .fin
	

	mov rcx, [direccion_queue]
	lea rdx, [triangulo_transitorio];[direccion_triangulo] (cambiar y probar)
	call Pop_Primer_Elemento_de_Queue_Circular

	lea rcx, [triangulo_transitorio];[direccion_triangulo] (cambiar y probar)	
	mov rdx, plano_far
	lea r8, [triangulo1]
	lea r9, [triangulo2] 
	call Recortar_Triangulo

	cmp rax, 1

	jb .seguir_loop_far
	je .un_triangulo_far
	ja .dos_triangulos_far


.un_triangulo_far:

	mov rcx, [direccion_queue]
	lea rdx, [triangulo1]	
	call Agregar_Elemento_en_Queue_Circular
	
	jmp .seguir_loop_far

.dos_triangulos_far:

	mov rcx, [direccion_queue]
	lea rdx, [triangulo1]	
	call Agregar_Elemento_en_Queue_Circular

	mov rcx, [direccion_queue]
	lea rdx, [triangulo2]	
	call Agregar_Elemento_en_Queue_Circular
	
	jmp .seguir_loop_far


.seguir_loop_far:	


	
	dec r13
	jmp .loop_plano_far

.fin:


	pop r13  
	pop r13 ; doble por alineamiento

	mov rsp, rbp
	pop rbp	
	ret	

%undef triangulo2 
%undef triangulo1


;--------------------------------------------------------------------

Clipping_Proyeccion:

	; rcx : direccion clipping proyeccion


%define PLANO_DERECHO 1
%define PLANO_IZQUIERDO 2
%define PLANO_SUPERIOR 3
%define PLANO_INFERIOR 4
%define NO_MAS_PLANOS 5
%define SIGUIENTE_PLANO 1
 
%define direccion_queue_clipping_proyeccion 	rbp - 208   ; 8 bytes
%define plano_clipping 				rbp - 200   ; 8 bytes
%define triangulos_recortados 			rbp - 192   ; 128 bytes (TRIANGULO_size*2) (ALINEADOS A 16) 
%define triangulo_transitorio 			rbp - 64    ; 64 bytes (ALINEADOS A 16)


	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 256

	push r12
	push r13
	push r14
	push r15

	mov [direccion_queue_clipping_proyeccion], rcx
	



	mov r12, PLANO_DERECHO  ; Este registro se encarga de contener los planos a usar
	
	; R15 se encarga de guardar cuántos triángulos necesito cortar por cada plano

	mov rcx, [direccion_queue_clipping_proyeccion]
	call Cantidad_Elementos_Queue_Circular
	mov r15, rax 


.loop_planos:

	; Compruebo y cambio el plano a utilizar

	cmp r12, PLANO_DERECHO
	mov rax, plano_derecho
	cmove r13, rax

	cmp r12, PLANO_IZQUIERDO
	mov rax, plano_izquierdo
	cmove r13, rax

	cmp r12, PLANO_SUPERIOR
	mov rax, plano_superior
	cmove r13, rax

	cmp r12, PLANO_INFERIOR
	mov rax, plano_inferior
	cmove r13, rax

	; Si terminamos con los planos, salir del loop

	mov [plano_clipping], r13
	cmp r12, NO_MAS_PLANOS
	je .fin_loop_planos

		
	
.loop_iterar_triangulos:

	cmp r15, 0
	je .fin_loop_iterar_triangulos


	
	mov rcx, [direccion_queue_clipping_proyeccion]
	lea rdx, [triangulo_transitorio]
	call Pop_Primer_Elemento_de_Queue_Circular

	dec r15


	lea rcx, [triangulo_transitorio]	
	mov rdx, [plano_clipping]
	lea r8, [triangulos_recortados+TRIANGULO_size*0]
	lea r9, [triangulos_recortados+TRIANGULO_size*1] 
	call Recortar_Triangulo


;_______Ahora guardo todos los triángulos que se crearon en el queue de proyeccion

	mov r14, rax
	lea r13, [triangulos_recortados]

.loop_validar_triangulos:

	cmp r14, 0
	je .fin_loop_validar_triangulos

	mov rcx, [direccion_queue_clipping_proyeccion]
	mov rdx, r13	
	call Agregar_Elemento_en_Queue_Circular

	add r13, TRIANGULO_size
	dec r14

	jmp .loop_validar_triangulos

.fin_loop_validar_triangulos:

;_______Actualizo la cantidad de triángulos que tiene el queue 


	jmp .loop_iterar_triangulos

.fin_loop_iterar_triangulos:


	mov rcx, [direccion_queue_clipping_proyeccion]
	call Cantidad_Elementos_Queue_Circular
	mov r15, rax

	add r12, SIGUIENTE_PLANO
	jmp .loop_planos

.fin_loop_planos:

	pop r15
	pop r14
	pop r13
	pop r12
	
	mov rsp, rbp
	pop rbp		
	ret


%undef PLANO_DERECHO 
%undef PLANO_IZQUIERDO 
%undef PLANO_SUPERIOR 
%undef PLANO_INFERIOR 
%undef NO_MAS_PLANOS 
%undef SIGUIENTE_PLANO 

%undef direccion_queue_clipping_proyeccion 	
%undef plano_clipping 				
%undef triangulos_recortados 			
%undef triangulo_transitorio 			

;--------------------------------------------------------------------

Obtener_Normal_Triangulo:

	; rcx: la dirección del triángulo el cual se va a sacar la normal
	; rdx: la dirección donde va a ir volcada la normal

%define normal_triangulo		rbp - 48  ; 16 bytes
%define vector_1_a_3			rbp - 32  ; 16 bytes
%define vector_1_a_2			rbp - 16  ; 16 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 48


	; Calculo los vectores para sacar la normal. Para ello resto
	; los puntos "1" y "2", y "1" y "3",  componente a componente. 

	fld dword [rcx+TRIANGULO__vertice2+VERTICE__x]   
	fld dword [rcx+TRIANGULO__vertice1+VERTICE__x]
	fsubp
	fld dword [rcx+TRIANGULO__vertice2+VERTICE__y]   
	fld dword [rcx+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [rcx+TRIANGULO__vertice2+VERTICE__z]   
	fld dword [rcx+TRIANGULO__vertice1+VERTICE__z]
	fsubp
	fstp dword [vector_1_a_2+VECTOR4__3]
	fstp dword [vector_1_a_2+VECTOR4__2]
	fstp dword [vector_1_a_2+VECTOR4__1]

	fld dword [rcx+TRIANGULO__vertice3+VERTICE__x]   
	fld dword [rcx+TRIANGULO__vertice1+VERTICE__x]
	fsubp
	fld dword [rcx+TRIANGULO__vertice3+VERTICE__y]   
	fld dword [rcx+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [rcx+TRIANGULO__vertice3+VERTICE__z]   
	fld dword [rcx+TRIANGULO__vertice1+VERTICE__z]
	fsubp
	fstp dword [vector_1_a_3+VECTOR4__3]
	fstp dword [vector_1_a_3+VECTOR4__2]
	fstp dword [vector_1_a_3+VECTOR4__1]

	; Ahora saco la normal haciendo el producto vectorial con los vectores
	; calculados arriba.	


	fld dword [vector_1_a_2+VECTOR4__2]
	fld dword [vector_1_a_3+VECTOR4__3]
	fmulp
	fld dword [vector_1_a_2+VECTOR4__3]
	fld dword [vector_1_a_3+VECTOR4__2]
 	fmulp
	fsubp
	fstp dword [normal_triangulo+VECTOR4__1]

	fld dword [vector_1_a_2+VECTOR4__3]
	fld dword [vector_1_a_3+VECTOR4__1]
	fmulp
 	fld dword [vector_1_a_2+VECTOR4__1]
	fld dword [vector_1_a_3+VECTOR4__3]
	fmulp
	fsubp
	fstp dword [normal_triangulo+VECTOR4__2]

	fld dword [vector_1_a_2+VECTOR4__1]
	fld dword [vector_1_a_3+VECTOR4__2]
	fmulp
 	fld dword [vector_1_a_2+VECTOR4__2]
	fld dword [vector_1_a_3+VECTOR4__1]
	fmulp
	fsubp
	fstp dword [normal_triangulo+VECTOR4__3]


	; Ahora normalizo la normal (esto es super optimizable, aprovechando
	; el valor guardado de la normal, pero por algun motivo lo hice 
	; mal. Ahora esta medio hardcodeado, pero probar volver a optimizarlo)



	fld dword [normal_triangulo+VECTOR4__1]
	fld dword [normal_triangulo+VECTOR4__1]
	fmulp
	fld dword [normal_triangulo+VECTOR4__2]
	fld dword [normal_triangulo+VECTOR4__2]
	fmulp
	fld dword [normal_triangulo+VECTOR4__3]
	fld dword [normal_triangulo+VECTOR4__3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [normal_triangulo+VECTOR4__1]
	fdivrp
	fstp dword [rdx+VECTOR4__1]

	

	fld dword [normal_triangulo+VECTOR4__1]
	fld dword [normal_triangulo+VECTOR4__1]
	fmulp
	fld dword [normal_triangulo+VECTOR4__2]
	fld dword [normal_triangulo+VECTOR4__2]
	fmulp
	fld dword [normal_triangulo+VECTOR4__3]
	fld dword [normal_triangulo+VECTOR4__3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [normal_triangulo+VECTOR4__2]
	fdivrp
	fstp dword [rdx+VECTOR4__2]


	fld dword [normal_triangulo+VECTOR4__1]
	fld dword [normal_triangulo+VECTOR4__1]
	fmulp
	fld dword [normal_triangulo+VECTOR4__2]
	fld dword [normal_triangulo+VECTOR4__2]
	fmulp
	fld dword [normal_triangulo+VECTOR4__3]
	fld dword [normal_triangulo+VECTOR4__3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [normal_triangulo+VECTOR4__3]
	fdivrp
	fstp dword [rdx+VECTOR4__3]

	mov rsp, rbp
	pop rbp

	ret


%undef normal_triangulo		
%undef vector_1_a_3			
%undef vector_1_a_2			

;------------------------------------------------------------------------------

Iluminar_Triangulo:


	; rcx: direccion al triangulo a iluminar 
	; rdx: dirección a normal (normalizada) del triangulo a iluminar
	; r8: vector de la luz


%define luz_normalizada		rbp - 24  ; 16 bytes (VECTOR4_size)
%define factor_sombra		rbp - 8   ; 4 bytes
%define factor_conversion 	rbp - 4   ; 4 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 16
	push rbx


;_______Primero y antes que nada, normalizo la luz

	fld dword [r8+VECTOR4__1]
	fld dword [r8+VECTOR4__1]
	fmulp
	fld dword [r8+VECTOR4__2]
	fld dword [r8+VECTOR4__2]
	fmulp
	fld dword [r8+VECTOR4__3]
	fld dword [r8+VECTOR4__3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [r8+VECTOR4__1]
	fdivrp
	fstp dword [luz_normalizada+VECTOR4__1]

	
	fld dword [r8+VECTOR4__1]
	fld dword [r8+VECTOR4__1]
	fmulp
	fld dword [r8+VECTOR4__2]
	fld dword [r8+VECTOR4__2]
	fmulp
	fld dword [r8+VECTOR4__3]
	fld dword [r8+VECTOR4__3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [r8+VECTOR4__2]
	fdivrp
	fstp dword [luz_normalizada+VECTOR4__2]


	fld dword [r8+VECTOR4__1]
	fld dword [r8+VECTOR4__1]
	fmulp
	fld dword [r8+VECTOR4__2]
	fld dword [r8+VECTOR4__2]
	fmulp
	fld dword [r8+VECTOR4__3]
	fld dword [r8+VECTOR4__3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [r8+VECTOR4__3]
	fdivrp
	fstp dword [luz_normalizada+VECTOR4__3]


;_______Una vez normalizada la luz, hago el producto escalar con la luz
;	y la normal del plano.


	mov eax, 100
	mov [factor_conversion], eax


	fld dword [rdx+VECTOR4__1]
	fld dword [luz_normalizada+VECTOR4__1]
	fmulp
	fld dword [rdx+VECTOR4__2]
	fld dword [luz_normalizada+VECTOR4__2]
	fmulp
	fld dword [rdx+VECTOR4__3]
	fld dword [luz_normalizada+VECTOR4__3]

	fmulp
	faddp
	faddp
	fild dword [factor_conversion]
	fmulp

;_______Si el factor sombra es menor a 0, entonces dejarlo en 0

	fldz
	fcom
	fcmovnb st0, st1
	fistp dword [factor_sombra]
	
;_______Si el factor sombra es mayor a 100, entonces dejarlo en 100

	fild dword [factor_conversion]
	fcom
	fcmovnbe st0, st1
	fistp dword [factor_sombra]

	fstp st0


	; Esto es para darle luz de ambiente y que no sea 0 si debe estar oscuro

	mov eax, [factor_sombra]
	mov edx, 20  ; como en %40
	cmp eax, 20
	cmovl eax, edx     ;;; BUG! hay algo que me está dando factor_sombra NEGATIVO. Lo arreglé con cmovl. Pero debería
				;;; funcionar con cmovb. Ver por qué no funciona

	mov [factor_sombra], eax


;_______Utilizo el factor sombra para ver cuánto reduzco de cada canal de color
;	segun el producto escalar entre la luz y la normal del triángulo (va de 0 a 1)


	; Rojo

	xor rax, rax
	mov al, [rcx+TRIANGULO__color+COLOR__rojo]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx


	; Chequeo si el resultado es mayor a 255, y si lo es, lo limito a 255

	xor rdx, rdx
	cmp rax, 255
	cmova rax,rdx
	mov [rcx+TRIANGULO__color+COLOR__rojo], al 



	; Verde
	
	xor rax, rax
	mov al, [rcx+TRIANGULO__color+COLOR__verde]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx

	; Chequeo si el resultado es mayor a 255, y si lo es, lo limito a 255

	xor rdx, rdx
	cmp rax, 255
	cmova rax,rdx
	mov [rcx+TRIANGULO__color+COLOR__verde], al
	

	; Azul

	xor rax, rax
	mov al, [rcx+TRIANGULO__color+COLOR__azul]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx

	; Chequeo si el resultado es mayor a 255, y si lo es, lo limito a 255

	xor rdx, rdx
	cmp rax, 255
	cmova rax,rdx
	mov [rcx+TRIANGULO__color+COLOR__azul], al


	pop rbx
	mov rsp, rbp
	pop rbp

	ret


%undef factor_conversion
%undef factor_sombra




