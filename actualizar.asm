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


%define normal_normalizada		rbp - 84 ; 16 bytes  ; quitar al optimizar ese proceso infame
%define factor_visibilidad_triangulo   	rbp - 68 ; 4 bytes
%define vector_triangulo_a_camara  	rbp - 64 ; 16 bytes 
%define vector_1_a_2			rbp - 48 ; 16 bytes
%define vector_1_a_3 			rbp - 32 ; 16 bytes
%define normal_triangulo 		rbp - 16 ; 16 bytes


	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE+256 ; revisar esta cantidad (ojo los parametros)


;_______Preparamos la matriz_mundo. Como primero se rota y luego se traslada, vamos a tener
;	que hacer MATRIZ_TRASLACION*MATRIZ_ROTACION (o tantas rotaciones como haya)


	; Inicializo la matriz del espacio "Mundo" con la traslacion


	mov rcx, matriz_mundo	
	mov edx, 0x00000000 ; 0
	mov r8d, 0x00000000 ; 0
	mov r9d, 0x40400000 ; 3  
	call Inicializar_Matriz_Traslacion	

	; Inicializo la matriz B con rotacion
	
	mov rcx, matriz_B
	mov edx, [tita_rotacion_x] 
	call Inicializar_Matriz_Rotacion_X

	; Multiplico ambas (siempre llamar A,B. Esta diseñado para respetar el orden de transformación)

	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz

	; Agrego la rotación en Z, que se ve linda. 

	mov rcx, matriz_B
	mov edx, [tita_rotacion_z]
	call Inicializar_Matriz_Rotacion_Z
	mov rcx, matriz_mundo
	mov rdx, matriz_B
	call Multiplicar_Matriz_Matriz
	
	; Ahora en "matriz_mundo" tengo la transformación (puedo descartar matriz_B)

;_______Ahora preparamos la matriz_camara


;TODO:  ; Falta "rellenar" los vectores de la cámara, porque hay que hacer productos vectoriales 
	; en el caso de que se muevan. En el main están hardcodeados porque no está implementado el
	; movimiento aún.

;TODO   ; La transformación de la cámara está mal (se cuelga).
        ; como no la necesito de momento la capamos (hacerla de nuevo igual)
	;mov rcx, matriz_camara
	;mov rdx, vector_camara_delante
	;mov r8, vector_camara_derecha
	;mov r9, vector_camara_arriba
	;mov qword [rsp + 4 * 8], vector_camara_posicion
	;call Inicializar_Matriz_Camara


;_______Si invertimos la matriz obtenemos la matriz_vista, pero directamente la inicializo
;	sin depender de la matriz_cámara

	mov rcx, matriz_vista
	mov rdx, vector_camara_delante
	mov r8, vector_camara_derecha
	mov r9, vector_camara_arriba
	mov qword [rsp + 4 * 8], vector_camara_posicion
	call Inicializar_Matriz_Vista


;_______Inicializamos la matriz proyección


;TODO   ; ATENCION:
	; Esta matriz de abajo está buggeada.
	; o es un error de pila o algo pasa
	; Estoy armando la matriz sin argumentos, con
	; los valores estandar.
	;mov rcx, matriz_proyeccion
	;mov edx, 768
	;mov r8d, 1366
	;mov r9d, 0x3fc90fdb ; pi/2
	;mov   qword [RSP + 4 * 8], 0x447a0000        
	;mov   qword [RSP + 5 * 8], 0x3dcccccd
	;call Inicializar_Matriz_Proyeccion
	
	;voy a llamar a esta matriz hardcodeada, con los argumentos de arriba
	
	mov rcx, matriz_proyeccion
	call Inicializar_Matriz_Proyeccion_FAKE


	mov rcx, matriz_proyeccion
	mov rdx, matriz_vista
	call Multiplicar_Matriz_Matriz


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

	mov rcx, matriz_mundo
	lea rdx, [r15+TRIANGULO+vertice1]
	mov r8,  triangulo_a_analizar+TRIANGULO+vertice1
	call Multiplicar_Matriz_Vector
	
	
	mov rcx, matriz_mundo
	lea rdx, [r15+TRIANGULO+vertice2]
	mov r8,  triangulo_a_analizar+TRIANGULO+vertice2
	call Multiplicar_Matriz_Vector
	
	mov rcx, matriz_mundo
	lea rdx, [r15+TRIANGULO+vertice3]
	mov r8,  triangulo_a_analizar+TRIANGULO+vertice3
	call Multiplicar_Matriz_Vector


	; Copio el código de color de paso

;	lea rdx, [r15+TRIANGULO+color+rojo]
;	mov al, [rdx]
;	mov r8, triangulo_a_analizar+TRIANGULO+color+rojo
;	mov [r8], al

;	lea rdx, [r15+TRIANGULO+color+verde]
;	mov al, [rdx]
;	mov r8, triangulo_a_analizar+TRIANGULO+color+verde
;	mov [r8], al

;	lea rdx, [r15+TRIANGULO+color+azul]
;	mov al, [rdx]
;	mov r8, triangulo_a_analizar+TRIANGULO+color+azul
;	mov [r8], al

	
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


	mov rcx, matriz_proyeccion
	mov rdx, triangulo_a_analizar+TRIANGULO+vertice1
	lea r8, [r13+TRIANGULO+vertice1]
	call Multiplicar_Matriz_Vector
	mov rcx, matriz_proyeccion
	mov rdx, triangulo_a_analizar+TRIANGULO+vertice2
	lea r8, [r13+TRIANGULO+vertice2]
	call Multiplicar_Matriz_Vector
	mov rcx, matriz_proyeccion
	mov rdx, triangulo_a_analizar+TRIANGULO+vertice3
	lea r8, [r13+TRIANGULO+vertice3]
	call Multiplicar_Matriz_Vector
	
;_______Muevo el color, y lo hago así medio manual porque son 3 bytes	

;	mov al, [triangulo_a_analizar+TRIANGULO+color+rojo]
;	mov r8, r13
;	add r8, TRIANGULO+color+rojo
;	mov [r8], al

;	mov al, [triangulo_a_analizar+TRIANGULO+color+verde]
;	mov r8,r13
;	add r8, TRIANGULO+color+verde
;	mov [r8], al

;	mov al, [triangulo_a_analizar+TRIANGULO+color+azul]
;	mov r8,r13
;	add r8, TRIANGULO+color+azul
;	mov [r8], al

	
;_______Ahora se hacen las modificaciones del Viewport y se suelen hacer sin matriz, y consisten en:
	;
	; 1) Dividir cada componente por w (si w != 0) 
	; 2) Invertir Y (acá invierto solo la X...lo que significa que tengo la cámara al reves?!) 	
	; 2) Luego sumarle uno a cada X e Y (no Z)
	; 3) Escalar a pantalla 

	mov rax, 0

.loop_viewport:

	fldz
	fld dword [r13+VECTOR4+vector_3]	
	fld dword [r13+VECTOR4+vector_4]               	
	fcom st2
	fcmove st0,st1
	fdivp
	fistp dword [r13+VECTOR4+vector_3]		; esto va en float pero ni sé si conviene así o dejarlo en entero
	
	fld dword [r13+VECTOR4+vector_1]
	fld dword [r13+VECTOR4+vector_4]
	fcom st2
	fcmove st0,st1
	fdivp
	fchs
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
	;fchs    ; comentar esto es mi humilde manera de invertir la Y
	fld1
	faddp
	fld dword [MitadAltoPantalla]
	fmulp
	fistp dword [r13+VECTOR4+vector_2]
	fstp st0
	
	inc rax
	add r13, VECTOR4_size  
	cmp rax, 3
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
	
	xor rax, rax	
	mov rsp, rbp
	pop rbp
	ret









