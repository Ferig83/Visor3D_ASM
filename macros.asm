%macro imprimir_rax 0

        push rax 
	push rbx 
	push rcx 
	push rdx
	push r8
	push r9

;_______Agregamos "10" a la cadena

        mov byte [cadena_auxiliar], 0   ; antes era 10, pero pongamos cero porque asi quiere el messagebox
        mov rbx, cadena_auxiliar
        inc rbx
        mov rcx, 10 ; para dividir o multiplicar
        
%%macroloop:

        xor rdx, rdx    ; limpio RDX para que no concatene y ahí vaya el resto
        div rcx 	; divido por 10 el contenido de RAX
        add dl, 48      ; agrego 48 para transformarlo en numero bajo el ASCII  

        mov [rbx], dl
        inc rbx
        cmp rax, 0
        jne %%macroloop

;Listo, se metieron los datos, pero al reves ( tipo 10,unidades,decenas, centenas, etc)
;Ahora falta meter los datos bien en cadena_impresion.

        mov rdx, cadena_impresion
        dec rbx

%%macroloop2:


        mov rcx, [rbx]
        mov [rdx], rcx
        dec rbx
        inc rdx
        cmp byte [rbx], 0
        jne %%macroloop2


        mov byte [rdx], 0

	
	
;	push rbp
;	mov rbp, rsp
;	sub rsp, 32
;;	sub rsp, 16


 	mov   rcx, 0; qword [hWnd]                 ; [RBP + 16]
	lea   rdx, [REL cadena_impresion]		
	lea   r8, [REL WindowName]
 	mov   r9d, NULL ; es el ok solo. Antes: MB_YESNO | MB_DEFBUTTON2           
 	call  MessageBoxA
	
;	xor rax, rax
;	mov rsp, rbp
;	pop rbp
	



	pop r9
	pop r8
        pop rdx 
	pop rcx 
	pop rbx 
	pop rax
%endmacro








%macro imprimir_eax 0

        push rax 
	push rbx 
	push rcx 
	push rdx


;_______Agregamos "10" a la cadena
        mov byte [cadena_auxiliar], 0  ;antes era 10, pero pongamos cero porque asi quiere el messagebox
        mov ebx, cadena_auxiliar
        inc ebx
        mov ecx, 10 ; para dividir o multiplicar
        
%%macroloop:

        xor edx, edx  ; limpio RDX para que no concatene y ahí vaya el resto
        div ecx ; divido por 10 el contenido de EAX
        add dl, 48

        mov [ebx], dl
        inc ebx
        cmp eax, 0
        jne %%macroloop

;Listo, se metieron los datos, pero al reves ( tipo 10,unidades,decenas, centenas, etc)
;Ahora falta meter los datos bien en cadena_impresion.

        mov edx, cadena_impresion
        dec ebx

%%macroloop2:


        mov ecx, [ebx]
        mov [edx], ecx
        dec ebx
        inc edx
        cmp byte [ebx], 0
        jne %%macroloop2
        mov byte [edx], 0

   	mov   rcx, 0; qword [hWnd]                 ; [RBP + 16]
	lea   rdx, [REL cadena_impresion]		
	lea   r8, [REL WindowName]
 	mov   r9d, NULL ; es el ok solo. Antes: MB_YESNO | MB_DEFBUTTON2           
 	call  MessageBoxA

        pop rdx 
	pop rcx 
	pop rbx 
	pop rax
%endmacro
