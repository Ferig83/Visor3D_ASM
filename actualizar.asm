; TO_DO:  chequear el tema de los colores, porque si el producto vectorial cambia de signo
; me salen colores que no van. Poner un cmov para que si es menor a cero, sea cero (y lo mismo
; si es mayor, ya que me parece que no está normalizado el vector y a la larga me va a traer
; problemas)


;	 IMPORTANTISIMOUUU!!!!
;
;	 Vamos a hacer una excepción para ver si funciona, que es poner toda la rasterización
; 	 en puntero_objeto3d_mundo. La idea es NO hacer esto y poner la rasterización en un
;	 heap aparte. Pero como la voluntad se nutre de resultados, voy a hacer esto en una
;	 sola pasada. Es decir, se hará  matriz_proyeccion*matriz_vista*matriz_mundo*vertice
;
;	 Update: para implementar lo de arriba voy a tener que hacer una optimización bastante
;	 gorda y una reformulación del código. Además implementar el ordenamiento yo solito
;	 y la función "vector" para el clipping.


Actualizar:

%define factor_conversion		rbp - 92 ; 4 bytes
%define factor_sombra			rbp - 88 ; 4 bytes
%define normal_normalizada		rbp - 84 ; 16 bytes  ; quitar al optimizar ese proceso infame
%define factor_visibilidad_triangulo   	rbp - 68 ; 4 bytes
%define vector_triangulo_a_camara  	rbp - 64 ; 16 bytes 
%define vector_1_a_2			rbp - 48 ; 16 bytes
%define vector_1_a_3 			rbp - 32 ; 16 bytes
%define normal_triangulo 		rbp - 16 ; 16 bytes


	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE+256 ; revisar esta cantidad (ojo los parametros)


;_______Primero actualizo los datos según tiempo pasado


	; Rotación en X 

	fld dword [tita_rotacion_x]
	fld dword [temporizador+tiempo_transcurrido]
	fld dword [factor_velocidad_rotacion_x]
	fmulp
	faddp
	fstp dword [tita_rotacion_x]


	; Rotación en Z 

	fld dword [tita_rotacion_z]
	fld dword [temporizador+tiempo_transcurrido]
	fld dword [factor_velocidad_rotacion_z]
	fmulp
	faddp
	fstp dword [tita_rotacion_z]

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
	mov edx, [tita_rotacion_z]
	call Inicializar_Matriz_Rotacion_Z
	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz


	; Agrego rotación en X
	
	mov rcx, matriz_B
	mov edx, [tita_rotacion_x] 
	call Inicializar_Matriz_Rotacion_X
	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz


	; Agrego traslación en Z = 3


	mov rcx, matriz_B	
	mov edx, 0x00000000 ; 0
	mov r8d, 0x00000000 ; 0
	mov r9d, 0x40400000 ; 3 
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



	mov r15, [puntero_objeto3d_original]
	mov r13, [puntero_objeto3d_mundo]
	xor r14, r14
	xor r12, r12
	mov qword [cantidad_triangulos_a_rasterizar], 0


.loop_analizar_si_se_ve:


	; Transformo al espacio mundo los tres vectores del triángulo

	lea rcx, [r15+TRIANGULO+vertice1]	
	mov rdx, matriz_mundo
	mov r8,  triangulo_a_analizar+TRIANGULO+vertice1
	call Multiplicar_Vector_Matriz
	
	lea rcx, [r15+TRIANGULO+vertice2]	
	mov rdx, matriz_mundo
	mov r8,  triangulo_a_analizar+TRIANGULO+vertice2
	call Multiplicar_Vector_Matriz
	
	
	lea rcx, [r15+TRIANGULO+vertice3]	
	mov rdx, matriz_mundo
	mov r8,  triangulo_a_analizar+TRIANGULO+vertice3
	call Multiplicar_Vector_Matriz


	; Copio el código de color de paso

	lea rdx, [r15+TRIANGULO+color+rojo]
	mov al, [rdx]
	mov r8, triangulo_a_analizar+TRIANGULO+color+rojo
	mov [r8], al

	lea rdx, [r15+TRIANGULO+color+verde]
	mov al, [rdx]
	mov r8, triangulo_a_analizar+TRIANGULO+color+verde
	mov [r8], al

	lea rdx, [r15+TRIANGULO+color+azul]
	mov al, [rdx]
	mov r8, triangulo_a_analizar+TRIANGULO+color+azul
	mov [r8], al

	
	; Ahora calculo los vectores para sacar la normal. Para ello resto
	; los puntos "1" y "2", y "1" y "3",  componente a componente. 

	fld dword [triangulo_a_analizar+TRIANGULO+vertice2+x]   
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+x]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO+vertice2+y]   
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+y]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO+vertice2+z]   
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+z]
	fsubp
	fstp dword [vector_1_a_2+VECTOR4+vector_3]
	fstp dword [vector_1_a_2+VECTOR4+vector_2]
	fstp dword [vector_1_a_2+VECTOR4+vector_1]

	fld dword [triangulo_a_analizar+TRIANGULO+vertice3+x]   
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+x]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO+vertice3+y]   
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+y]
	fsubp
	fld dword [triangulo_a_analizar+TRIANGULO+vertice3+z]   
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+z]
	fsubp
	fstp dword [vector_1_a_3+VECTOR4+vector_3]
	fstp dword [vector_1_a_3+VECTOR4+vector_2]
	fstp dword [vector_1_a_3+VECTOR4+vector_1]

	; Ahora saco la normal haciendo el producto vectorial con los vectores
	; calculados arriba.	


	fld dword [vector_1_a_2+VECTOR4+vector_2]
	fld dword [vector_1_a_3+VECTOR4+vector_3]
	fmulp
	fld dword [vector_1_a_2+VECTOR4+vector_3]
	fld dword [vector_1_a_3+VECTOR4+vector_2]
 	fmulp
	fsubp
	fstp dword [normal_triangulo+VECTOR4+vector_1]

	fld dword [vector_1_a_2+VECTOR4+vector_3]
	fld dword [vector_1_a_3+VECTOR4+vector_1]
	fmulp
 	fld dword [vector_1_a_2+VECTOR4+vector_1]
	fld dword [vector_1_a_3+VECTOR4+vector_3]
	fmulp
	fsubp
	fstp dword [normal_triangulo+VECTOR4+vector_2]

	fld dword [vector_1_a_2+VECTOR4+vector_1]
	fld dword [vector_1_a_3+VECTOR4+vector_2]
	fmulp
 	fld dword [vector_1_a_2+VECTOR4+vector_2]
	fld dword [vector_1_a_3+VECTOR4+vector_1]
	fmulp
	fsubp
	fstp dword [normal_triangulo+VECTOR4+vector_3]


	


	; Ahora normalizo la normal (esto es super optimizable, aprovechando
	; el valor guardado de la normal, pero por algun motivo lo hice 
	; mal. Ahora esta medio hardcodeado, pero probar volver a optimizarlo)


	fld dword [normal_triangulo+VECTOR4+vector_1]
	fld dword [normal_triangulo+VECTOR4+vector_1]
	fmulp
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fmulp
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [normal_triangulo+VECTOR4+vector_1]
	fdivrp
	fstp dword [normal_normalizada+VECTOR4+vector_1]


	fld dword [normal_triangulo+VECTOR4+vector_1]
	fld dword [normal_triangulo+VECTOR4+vector_1]
	fmulp
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fmulp
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fdivrp
	fstp dword [normal_normalizada+VECTOR4+vector_2]


	fld dword [normal_triangulo+VECTOR4+vector_1]
	fld dword [normal_triangulo+VECTOR4+vector_1]
	fmulp
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fld dword [normal_triangulo+VECTOR4+vector_2]
	fmulp
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fmulp
	faddp
	faddp
	fsqrt
	fld dword [normal_triangulo+VECTOR4+vector_3]
	fdivrp
	fstp dword [normal_normalizada+VECTOR4+vector_3]

	
	; Ahora saco el vector que va desde el triangulo a la cámara. Uso
	; uno de los vertices (el primero), porque total todos viven en un solo
	; plano así que da igual cuál use.

;TODO 	; Probablemente necesite reemplazar ese vector de posición de cámara
	

	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+x]
	fld dword [vector_camara_posicion+VECTOR4+vector_1]
	fsubp
	fstp dword [vector_triangulo_a_camara+VECTOR4+vector_1]
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+y]
	fld dword [vector_camara_posicion+VECTOR4+vector_2]
	fsubp
	fstp dword [vector_triangulo_a_camara+VECTOR4+vector_2]
	fld dword [triangulo_a_analizar+TRIANGULO+vertice1+z]
	fld dword [vector_camara_posicion+VECTOR4+vector_3]
	fsubp
	fstp dword [vector_triangulo_a_camara+VECTOR4+vector_3]

;_______Ahora hago el producto escalar de la normal y el vector que saqué arriba

	fld dword [normal_normalizada+VECTOR4+vector_1]
	fld dword [vector_triangulo_a_camara+VECTOR4+vector_1]
	fmulp
	fld dword [normal_normalizada+VECTOR4+vector_2]
	fld dword [vector_triangulo_a_camara+VECTOR4+vector_2]
	fmulp
	fld dword [normal_normalizada+VECTOR4+vector_3]
	fld dword [vector_triangulo_a_camara+VECTOR4+vector_3]
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

	mov rcx, triangulo_a_analizar+TRIANGULO+vertice1
	mov rdx, matriz_pantalla
	lea r8, [r13+TRIANGULO+vertice1]
	call Multiplicar_Vector_Matriz

	mov rcx, triangulo_a_analizar+TRIANGULO+vertice2
	mov rdx, matriz_pantalla
	lea r8, [r13+TRIANGULO+vertice2]
	call Multiplicar_Vector_Matriz


	mov rcx, triangulo_a_analizar+TRIANGULO+vertice3
	mov rdx, matriz_pantalla	
	lea r8, [r13+TRIANGULO+vertice3]
	call Multiplicar_Vector_Matriz

	
;_______Muevo el color, y lo hago así medio manual porque son 3 bytes	

	mov al, [triangulo_a_analizar+TRIANGULO+color+rojo]
	mov r8, r13
	add r8, TRIANGULO+color+rojo
	mov [r8], al

	mov al, [triangulo_a_analizar+TRIANGULO+color+verde]
	mov r8,r13
	add r8, TRIANGULO+color+verde
	mov [r8], al

	mov al, [triangulo_a_analizar+TRIANGULO+color+azul]
	mov r8,r13
	add r8, TRIANGULO+color+azul
	mov [r8], al

;_______Una vez que tengo cargado el color hago varío el mismo según sombra


;;;;;;;;Debería normalizarlo pero banquemos, ya lo tengo normalizado en el main.asm. Probemos primero que hay
		
	fld dword [normal_normalizada+VECTOR4+vector_1]
	fld dword [vector_luz+VECTOR4+vector_1]
	fmulp
	fld dword [normal_normalizada+VECTOR4+vector_2]
	fld dword [vector_luz+VECTOR4+vector_2]
	fmulp
	fld dword [normal_normalizada+VECTOR4+vector_3]
	fld dword [vector_luz+VECTOR4+vector_3]
	fmulp
	faddp
	faddp
	fild dword [factor_conversion]
	fmulp
	fistp dword [factor_sombra]


	pushf
	push rbx

	xor rax, rax
	mov al, [r13+TRIANGULO+color+rojo]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx
	mov [r13+TRIANGULO+color+rojo], al
	
	xor rax, rax
	mov al, [r13+TRIANGULO+color+verde]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx
	mov [r13+TRIANGULO+color+verde], al
	
	xor rax, rax
	mov al, [r13+TRIANGULO+color+azul]
	xor rdx, rdx
	xor rbx, rbx
	mov ebx, [factor_sombra]
	mul rbx
	xor rdx, rdx
	mov rbx, 100
	div rbx
	mov [r13+TRIANGULO+color+azul], al

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
	fld dword [r13+VECTOR4+vector_3]	
	fld dword [r13+VECTOR4+vector_4]               	
	fcom st2					; Me fijo si st0 es igual a st2 (o sea, si es igual a cero)
	fcmove st0,st1					; Si lo es, entonces muevo el mismo valor de st1 a st0
	fdivp						; y lo divido (así divido por uno en vez de por cero)
	fistp dword [r13+VECTOR4+vector_3]		; (esto va en float pero ni sé si conviene así o dejarlo en entero)
	
	fld dword [r13+VECTOR4+vector_1]
	fld dword [r13+VECTOR4+vector_4]
	fcom st2
	fcmove st0,st1
	fdivp
	fchs ;;;; esto si piden invertir X
	fld1       
	faddp
	fld dword [MitadAnchoPantalla]
	fmulp
	fistp dword [r13+VECTOR4+vector_1]




	fld dword [r13+VECTOR4+vector_2]
	fld dword [r13+VECTOR4+vector_4]
	fcom st2
	fcmove st0,st1
	fdivp
	fchs   ;;;; y esto si piden invertir la Y
	fld1
	faddp
	fld dword [MitadAltoPantalla]
	fmulp
	fistp dword [r13+VECTOR4+vector_2]
	fstp st0

	inc r10
	add r13, VECTOR4_size  
	cmp r10, 3
	jne .loop_viewport

	add r13, TRIANGULO_size - VECTOR4_size*3
	inc r14


.continuar:
	
	
	add r15, TRIANGULO_size
	inc r12 


	cmp r12, [cantidad_triangulos_objeto]
	jb .loop_analizar_si_se_ve

	mov [cantidad_triangulos_a_rasterizar], r14


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







