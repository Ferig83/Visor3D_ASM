
struc QUEUE_CIRCULAR

	QUEUE_CIRCULAR__inicio_memoria resq 1
	QUEUE_CIRCULAR__fin_memoria resq 1
	QUEUE_CIRCULAR__inicio_datos resq 1
	QUEUE_CIRCULAR__fin_datos resq 1
	QUEUE_CIRCULAR__tamanio_datos resq 1
	QUEUE_CIRCULAR__capacidad_en_cantidad_de_datos resq 1
	QUEUE_CIRCULAR__cantidad_elementos resq 1

	; IMPORTANTE! El tamaño de los datos tiene que ser múltiplo de 8	

endstruc  ; Ocupa 56 bytes



Inicializar_Queue_Circular:

	; rcx : dirección a la estructura de los datos
	; rdx : capacidad en cantidad de datos
	; r8  : tamaño de los datos
	; r9  : direccion a la memoria donde están los datos

	mov [rcx+QUEUE_CIRCULAR__inicio_memoria], r9
	mov [rcx+QUEUE_CIRCULAR__inicio_datos], r9
	mov [rcx+QUEUE_CIRCULAR__fin_datos], r9
	mov [rcx+QUEUE_CIRCULAR__capacidad_en_cantidad_de_datos], rdx
	mov [rcx+QUEUE_CIRCULAR__tamanio_datos], r8
	mov rax, rdx
	dec rax 
	mul r8
	add r9, rax
	mov [rcx+QUEUE_CIRCULAR__fin_memoria], r9
	xor rdx, rdx
	mov [rcx+QUEUE_CIRCULAR__cantidad_elementos], rdx
	
	ret	


Agregar_Elemento_en_Queue_Circular:

	; rcx : la estructura de los datos del queue
	; rdx : dirección del elemento a agregar
	
	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE
	push rbx

	
	mov rax, [rcx+QUEUE_CIRCULAR__fin_datos]
	mov r8, [rcx+QUEUE_CIRCULAR__tamanio_datos]
	mov r9, [rcx+QUEUE_CIRCULAR__fin_memoria]


	xor rbx, rbx

	; Ahora copio los datos. 

.loop_copia_datos:


	mov r10, [rdx] 
	mov [rax], r10
	add rdx, 8
	add rax, 8
	add rbx, 8
	cmp rbx, r8
	jb .loop_copia_datos



	; Una vez que copié todo, verifico si la dirección de fin_datos es la misma que fin_memoria
	; y si son iguales, fin_datos da la vuelta al círculo y pasa a ser inicio_memoria.
	
	
	mov rdx, [rcx+QUEUE_CIRCULAR__inicio_memoria]
	mov rax, [rcx+QUEUE_CIRCULAR__fin_datos]
	mov r10, rax
	add r10, r8
	cmp rax, r9
	cmove rax, rdx
	cmovne rax, r10
	mov [rcx+QUEUE_CIRCULAR__fin_datos], rax 
	
	mov rax, [rcx+QUEUE_CIRCULAR__cantidad_elementos]
	inc rax
	mov [rcx+QUEUE_CIRCULAR__cantidad_elementos], rax

	pop rbx

	mov rsp, rbp
	pop rbp
	
	ret
	

Pop_Primer_Elemento_de_Queue_Circular:
	
	; rcx : dirección a la estructura
	; rdx : dirección a donde voy a copiar el elemento

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE
	push rbx

	xor rbx, rbx

	mov rax, [rcx+QUEUE_CIRCULAR__inicio_datos]
	mov r9, [rcx+QUEUE_CIRCULAR__fin_memoria]
	mov r8, [rcx+QUEUE_CIRCULAR__tamanio_datos]

	; Ahora copio los datos. 

.loop_copia_datos:


	mov r10, [rax] 
	mov [rdx], r10
	add rdx, 8
	add rax, 8
	add rbx, 8
	cmp rbx, r8
	jb .loop_copia_datos

	; Una vez que copié todo, tengo que hacer avanzar la dirección
	; de inicio datos y restarle uno a la cantidad de elementos, sin
	; embargo debo verificar que inicio datos no es igual a la dirección
	; del fin de memoria.	


	mov rdx, [rcx+QUEUE_CIRCULAR__inicio_memoria]
	mov rax, [rcx+QUEUE_CIRCULAR__inicio_datos]
	mov r10, rax
	add r10, r8
	cmp rax, r9
	cmove rax, rdx
	cmovne rax, r10
	mov [rcx+QUEUE_CIRCULAR__inicio_datos], rax 

	
	mov rax, [rcx+QUEUE_CIRCULAR__cantidad_elementos]
	dec rax
	mov [rcx+QUEUE_CIRCULAR__cantidad_elementos], rax
	

	pop rbx

	mov rsp, rbp
	pop rbp
	
	ret



	
Cantidad_Elementos_Queue_Circular:

	; rcx : puntero a la estructura del queue circular

	mov rax, [rcx+QUEUE_CIRCULAR__cantidad_elementos]
	ret

Obtener_Direccion_Primer_Elemento_Queue_Circular:

	; rcx : puntero a la estructura del queue circular


	mov rax, [rcx+QUEUE_CIRCULAR__inicio_datos]

	ret

 