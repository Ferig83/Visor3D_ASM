

Actualizar:


%define triangulo_transformado		rbp - 240 ; 64 bytes (TRIANGULO_size) - ATENCION! SI O SI DEBE ESTAR ALINEADO A 16
%define triangulo_a_analizar		rbp - 176 ; 64 bytes (TRIANGULO_size) - ATENCION! SI O SI DEBE ESTAR ALINEADO A 16
%define padding1			rbp - 112 ; 12 bytes. Es un padding para que "triangulo_a_analizar" este alineado a 16
%define puntero_estructura		rbp - 100 ; 8 bytes
%define factor_conversion		rbp - 92  ; 4 bytes
%define factor_sombra			rbp - 88  ; 4 bytes
%define normal_normalizada		rbp - 84  ; 16 bytes  ; quitar al optimizar ese proceso infame
%define factor_visibilidad_triangulo   	rbp - 68  ; 4 bytes
%define vector_triangulo_a_camara  	rbp - 64  ; 16 bytes 
%define vector_1_a_2			rbp - 48  ; 16 bytes
%define vector_1_a_3 			rbp - 32  ; 16 bytes
%define normal_triangulo 		rbp - 16  ; 16 bytes


	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE+256 ; revisar esta cantidad (ojo los parametros)

;_______Guardo el puntero de la estructura a actualizar


	mov [puntero_estructura], rcx

;_______Actualizo los datos según tiempo pasado



	; Rotación en X 

	
	fld dword [rcx+OBJETO_3D__angulo_x]
	fld dword [temporizador+TIMER__tiempo_transcurrido]
	fld dword [rcx+OBJETO_3D__velocidad_angular_x]
	fmulp
	faddp
	fstp dword [rcx+OBJETO_3D__angulo_x]


	; Rotación en Z 

	fld dword [rcx+OBJETO_3D__angulo_z]
	fld dword [temporizador+TIMER__tiempo_transcurrido]
	fld dword [rcx+OBJETO_3D__velocidad_angular_z]
	fmulp
	faddp
	fstp dword [rcx+OBJETO_3D__angulo_z]

;_______Ahora ajusto la cámara

					
	mov rcx, matriz_camara
	mov rdx, vector_camara_delante
	mov r8, vector_camara_arriba
	mov r9, vector_camara_posicion
	call Inicializar_Matriz_Camara

	mov rcx, matriz_vista
	mov rdx, matriz_camara   
	call Inicializar_Matriz_Vista  



	; Cuidado de contemplar todo esto más adelante.




;_______Ahora vamos con las matrices y el trabajo duro...
	
	
	mov eax, 100
	mov [factor_conversion], eax
	xor rax,rax

;_______Preparamos la matriz_mundo. Como primero se rota y luego se traslada, vamos a tener
;	que hacer MATRIZ_ROTACION_X*MATRIZ_ROTACION_Y*MATRIZ_TRASLACION
;
;	Ojo al orden! la multiplicación es A = A * MATRIZ_B
;	pero si multiplicás varias matrices para luego multiplicarla por el vector, el orden
; 	V*M1*M2*M3   siendo M1 la primera matriz que se quiere aplicar. 
;
;	Muchas veces se ve al reves:   M3*M2*M1*V por lo que para aplicar M1 primero tenías
;	que arrancar multiplicando desde M3.


	; Agrego la rotación en Z

	mov rcx, matriz_B
	mov r8, [puntero_estructura]
	mov edx, [r8+OBJETO_3D__angulo_z]
	call Inicializar_Matriz_Rotacion_Z
	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz


	; Agrego rotación en X
	
	mov rcx, matriz_B
	mov r8, [puntero_estructura]
	mov edx, [r8+OBJETO_3D__angulo_x] 
	call Inicializar_Matriz_Rotacion_X
	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz


	; Agrego traslación en Z = 3



	mov rcx, matriz_B
	mov rax, [puntero_estructura]
	mov edx, [rax+OBJETO_3D__posicion_x]
	mov r8d, [rax+OBJETO_3D__posicion_y]
	mov r9d, [rax+OBJETO_3D__posicion_z] 
	call Inicializar_Matriz_Traslacion	
	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz


	; Ahora en "matriz_mundo" tengo la transformación (puedo descartar matriz_B)



;_______Tenemos todo, pero necesito saber cuales triángulos rasterizar y cuales no, así que no puedo unificar
;	las matrices como quisiera en una sola transformación. Debería sacar la normal de cada 
;	triángulo, chequear si está enfrentado a la cámara y ahí recien transformarlo si lo anterior es correcto. 
;
;	Como primer paso itero los triángulos multiplicándolos con matriz_mundo y verificando cuales entran
;	en la rasterización	


	push r12
	push r13
	push r14
	push r15


	mov r14, [puntero_estructura]
	mov r15, [r14+OBJETO_3D__puntero_triangulos]
	;lea r13, [triangulo_transformado]
	xor r12, r12   ; Contador de triángulos totales del objeto


.loop_analizar_si_se_ve:

	lea r13, [triangulo_transformado]


	; Transformo al espacio mundo los tres vectores del triángulo

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


	lea rdx, [r15+TRIANGULO__color+COLOR__alfa]
	mov al, [rdx]
	lea r8, [triangulo_a_analizar+TRIANGULO__color+COLOR__alfa]
	mov [r8], al

	lea rdx, [r15+TRIANGULO__color+COLOR__rojo]
	mov al, [rdx]
	lea r8, [triangulo_a_analizar+TRIANGULO__color+COLOR__rojo]
	mov [r8], al

	lea rdx, [r15+TRIANGULO__color+COLOR__verde]
	mov al, [rdx]
	lea r8, [triangulo_a_analizar+TRIANGULO__color+COLOR__verde]
	mov [r8], al

	lea rdx, [r15+TRIANGULO__color+COLOR__azul]
	mov al, [rdx]
	lea r8, [triangulo_a_analizar+TRIANGULO__color+COLOR__azul]
	mov [r8], al

	
	; Ahora calculo los vectores para sacar la normal. Para ello resto
	; los puntos "1" y "2", y "1" y "3",  componente a componente. 

	fld dword [triangulo_a_analizar+TRIANGULO__vertice2+VERTICE__x]   
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__x]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO__vertice2+VERTICE__y]   
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO__vertice2+VERTICE__z]   
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__z]
	fsubp
	fstp dword [vector_1_a_2+VECTOR4__3]
	fstp dword [vector_1_a_2+VECTOR4__2]
	fstp dword [vector_1_a_2+VECTOR4__1]

	fld dword [triangulo_a_analizar+TRIANGULO__vertice3+VERTICE__x]   
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__x]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO__vertice3+VERTICE__y]   
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO__vertice3+VERTICE__z]   
	fld dword [triangulo_a_analizar+TRIANGULO__vertice1+VERTICE__z]
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
	fstp dword [normal_normalizada+VECTOR4__1]


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
	fstp dword [normal_normalizada+VECTOR4__2]


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
	fstp dword [normal_normalizada+VECTOR4__3]

	
	; Ahora saco el vector que va desde el triangulo a la cámara. Uso
	; uno de los vertices (el primero), porque total todos viven en un solo
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

	fld dword [normal_normalizada+VECTOR4__1]
	fld dword [vector_triangulo_a_camara+VECTOR4__1]
	fmulp
	fld dword [normal_normalizada+VECTOR4__2]
	fld dword [vector_triangulo_a_camara+VECTOR4__2]
	fmulp
	fld dword [normal_normalizada+VECTOR4__3]
	fld dword [vector_triangulo_a_camara+VECTOR4__3]
	fmulp
	faddp
	faddp
	fldz  

	; Acá medio raro, debería ser al reves: funciona si es positivo!
	; Debería revisar bien la teoría de proyección porque me parece
	; que con la cámara estoy metiendo la pata.

	fcomip st0,st1
	fstp st0
	jb .continuar

	; Acá van las instrucciones si el producto escalar es menor a 0
	; y debería subir el triángulo a la lista de triangulos a rasterizar, por lo 
	; que deberíamos hacerle las transformaciones pertinentes e iterar por ese lado 
	; como hago abajo.





;_______Genero las matrices como para tomar todos los triángulos del espacio "mundo"
;	y llevarlos al espacio "pantalla".

	mov rcx, matriz_pantalla
	call Inicializar_Matriz_Identidad

	mov rcx, matriz_pantalla
	mov rdx, matriz_vista
	call Multiplicar_Matriz_Matriz

	mov rcx, matriz_pantalla
	mov rdx, matriz_proyeccion
	call Multiplicar_Matriz_Matriz


	; Aplico las transformaciones al triángulo

	lea rcx, [triangulo_a_analizar+TRIANGULO__vertice1]
	mov rdx, matriz_pantalla
	lea r8, [r13+TRIANGULO__vertice1]
	call Multiplicar_Vector_Matriz

	lea rcx, [triangulo_a_analizar+TRIANGULO__vertice2]
	mov rdx, matriz_pantalla
	lea r8, [r13+TRIANGULO__vertice2]
	call Multiplicar_Vector_Matriz


	lea rcx, [triangulo_a_analizar+TRIANGULO__vertice3]
	mov rdx, matriz_pantalla	
	lea r8, [r13+TRIANGULO__vertice3]
	call Multiplicar_Vector_Matriz

	
;_______Muevo el color, y lo hago así medio manual porque son 3 bytes	


	mov al, [triangulo_a_analizar+TRIANGULO__color+COLOR__alfa]
	mov r8, r13
	add r8, TRIANGULO__color+COLOR__alfa
	mov [r8], al


	mov al, [triangulo_a_analizar+TRIANGULO__color+COLOR__rojo]
	mov r8, r13
	add r8, TRIANGULO__color+COLOR__rojo
	mov [r8], al

	mov al, [triangulo_a_analizar+TRIANGULO__color+COLOR__verde]
	mov r8,r13
	add r8, TRIANGULO__color+COLOR__verde
	mov [r8], al

	mov al, [triangulo_a_analizar+TRIANGULO__color+COLOR__azul]
	mov r8,r13
	add r8, TRIANGULO__color+COLOR__azul
	mov [r8], al

;_______Una vez que tengo cargado el color hago varío el mismo según sombra


;;;;;;;; Debería normalizar el vector luz pero banquemos, ya lo tengo normalizado en el main.asm. Probemos primero que hay
		
	fld dword [normal_normalizada+VECTOR4__1]
	fld dword [vector_luz+VECTOR4__1]
	fmulp
	fld dword [normal_normalizada+VECTOR4__2]
	fld dword [vector_luz+VECTOR4__2]
	fmulp
	fld dword [normal_normalizada+VECTOR4__3]
	fld dword [vector_luz+VECTOR4__3]
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




	pushf
	push rbx



;;;; TODO:  Esto de chequear si el resultado es mayor a 255 no debería ser así, porque teóricamente no hay razón
;		para que el resultado sea mayor a 255. Eso implicaría que el factor sombra es mayor a 100, o que
;		hay negativos. Algo raro está pasando.

	

	; Rojo

	xor rax, rax
	mov al, [r13+TRIANGULO__color+COLOR__rojo]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx

;	Chequeo si el resultado es mayor a 255, y si lo es, lo limito a 255

	xor rdx, rdx
	cmp rax, 255
	cmova rax,rdx
	mov [r13+TRIANGULO__color+COLOR__rojo], al 



	; Verde
	
	xor rax, rax
	mov al, [r13+TRIANGULO__color+COLOR__verde]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx

;	Chequeo si el resultado es mayor a 255, y si lo es, lo limito a 255

	xor rdx, rdx
	cmp rax, 255
	cmova rax,rdx
	mov [r13+TRIANGULO__color+COLOR__verde], al
	

	; Azul

	xor rax, rax
	mov al, [r13+TRIANGULO__color+COLOR__azul]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx

;	Chequeo si el resultado es mayor a 255, y si lo es, lo limito a 255

	xor rdx, rdx
	cmp rax, 255
	cmova rax,rdx
	mov [r13+TRIANGULO__color+COLOR__azul], al


	pop rbx
		
	

	
;_______Ahora se hacen las modificaciones del Viewport y se suelen hacer sin matriz, y consisten en:
	;
	; 1) Dividir cada componente por w (si w != 0) 
	; 2) Invertir Y (acá invierto solo la X...lo que significa que tengo la cámara al reves?!) 	
	; 2) Luego sumarle uno a cada X e Y (no Z)
	; 3) Escalar a pantalla 


;;;;ALTO BUG PARCHEADO ;;;; 

	xor r10, r10 ; mov rax, 0   ; este xor me alteró un flag. Algo de abajo está laburando con flags de arriba
					; LO CUAL ESTA MAL. tengo que ver qué. El parcheo es salvar los flags
 

	popf

; hipótesis: el xor me movió un flag, que se alteró arriba y afecta abajo. Si guardo los flags?
; CORRECTO! son los flags... madre mía... pero...


.loop_viewport:

	fldz
	fld dword [r13+VECTOR4__3]	
	fld dword [r13+VECTOR4__4]               	
	fcom st2					; Me fijo si st0 es igual a st2 (o sea, si es igual a cero)
	fcmove st0,st1					; Si lo es, entonces muevo el mismo valor de st1 a st0
	fdivp						; y lo divido (así divido por uno en vez de por cero)
	fistp dword [r13+VECTOR4__3]		; (esto va en float pero ni sé si conviene así o dejarlo en entero)
	
	fld dword [r13+VECTOR4__1]
	fld dword [r13+VECTOR4__4]
	fcom st2
	fcmove st0,st1
	fdivp
	fchs ;;;; esto si piden invertir X
	fld1       
	faddp
	fld dword [MitadAnchoPantalla]
	fmulp
	fistp dword [r13+VECTOR4__1]




	fld dword [r13+VECTOR4__2]
	fld dword [r13+VECTOR4__4]
	fcom st2
	fcmove st0,st1
	fdivp
	fchs   ;;;; y esto si piden invertir la Y
	fld1
	faddp
	fld dword [MitadAltoPantalla]
	fmulp
	fistp dword [r13+VECTOR4__2]
	fstp st0


	inc r10
	add r13, VECTOR4_size  
	cmp r10, 3
	jne .loop_viewport


; Puede que no funcione porque es la pila, no sé.

	lea r13, [triangulo_transformado]
	mov rcx, array_rasterizacion    
	mov rdx, r13
	call Pushback_Array_Dinamico

	

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

%undef triangulo_transformado
%undef triangulo_a_analizar
%undef puntero_estructura		
%undef factor_conversion		
%undef factor_sombra			
%undef normal_normalizada		
%undef factor_visibilidad_triangulo   	
%undef vector_triangulo_a_camara  	 
%undef vector_1_a_2			
%undef vector_1_a_3 			
%undef normal_triangulo 		



;--------------------------------------------------------------------


Actualizar_Todo:

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE
	

	xor rax, rax
	mov [array_rasterizacion+ARRAY_DINAMICO__cantidad_elementos], rax 



;_______Ahora actualizo todo, poner lo que necesite actualizar


	mov rcx, cubo
	call Actualizar

	mov rcx, cilindro
	call Actualizar

	mov rcx, esfera
	call Actualizar


	xor rax,rax

	mov rsp, rbp
	pop rbp

	ret

	
	
