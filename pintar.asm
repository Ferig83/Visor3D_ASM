%define puntero_triangulo_a_pintar      RBP - 96 	    ; 8 bytes
%define Pintar.hWnd 	  	 	RBP - 88            ; 8 bytes
%define ps                  		RBP - 80            ; PAINTSTRUCT structure. 72 bytes
%define ps.hdc              		RBP - 80            ; 8 bytes. Start on an 8 byte boundary
%define ps.fErase           		RBP - 72            ; 4 bytes
%define ps.rcPaint.left     		RBP - 68            ; 4 bytes
%define ps.rcPaint.top      		RBP - 64            ; 4 bytes
%define ps.rcPaint.right    		RBP - 60            ; 4 bytes
%define ps.rcPaint.bottom   		RBP - 56            ; 4 bytes
%define ps.Restore          		RBP - 52            ; 4 bytes
%define ps.fIncUpdate       		RBP - 48            ; 4 bytes
%define ps.rgbReserved      		RBP - 44            ; 32 bytes
%define ps.Padding          		RBP - 12            ; 4 bytes. Structure length padding
%define hdc                 		RBP - 8             ; 8 bytes



Pintar:


	push rbp
	mov rbp,rsp
	sub rsp, SHADOWSPACE + 124 +4 ;el 4 es para alinear	

	push r13

	mov [Pintar.hWnd], rcx
	mov [puntero_triangulo_a_pintar], rdx	

	mov rcx, [Pintar.hWnd]
		;mov rdx, 0  			; 0
		;mov r8, 0x00000020; | 0x00000002		; DCX_PARENTCLIP | DCX_CACHE
	call GetDC	;Ex
	mov [DC_pantalla], rax


       	mov  rcx, [DC_pantalla]
	mov  rdx, rectangulo_pantalla
	mov  r8, [BackgroundBrush]
	call FillRect

	
;_______Lo pintamos

	mov r13,0


.loop1:

	xor rdx,rdx
	mov rax, TRIANGULO_size 
	mul r13
	
	mov rdx, [puntero_triangulo_a_pintar]
	add rdx, rax
	mov rcx, [DC_pantalla]
	call Pintar_Triangulo 	      
	
	inc r13
	cmp qword r13, [cantidad_triangulos_a_rasterizar]
	jb .loop1


;_______Decimos que terminamos de pintar


	mov rcx, [Pintar.hWnd]
	mov rdx, [DC_pantalla]
	call ReleaseDC


	pop r13

	mov rsp, rbp
	pop rbp

	ret

	


Pintar_WMPAINT:


	push rbp
	mov rbp,rsp
	sub rsp, SHADOWSPACE + 124 +4 ;el 4 es para alinear	

	push r13

	mov [Pintar.hWnd], rcx
	mov [puntero_triangulo_a_pintar], rdx	


	mov   rcx, qword [Pintar.hWnd]                        
 	lea   rdx, [ps]                                
 	call  BeginPaint
 	mov   qword [DC_pantalla], rax                         

	mov  rcx, [hdc]
	lea  rdx, [ps.rcPaint.left]
	mov  r8, [BackgroundBrush]
	call FillRect

	
;_______Lo pintamos

	mov r13,0


.loop1:

	xor rdx,rdx
	mov rax, TRIANGULO_size
	mul r13
	
	mov rdx, [puntero_triangulo_a_pintar]
	add rdx, rax
	mov rcx, [DC_pantalla]
	call Pintar_Triangulo 	      
	
	inc r13
	cmp qword r13, [cantidad_triangulos_a_rasterizar]
	jb .loop1


;_______Decimos que terminamos de pintar


 	mov   rcx, qword [Pintar.hWnd]                        
 	lea   rdx, [ps]                                
 	call  EndPaint


	pop r13

	mov rsp, rbp
	pop rbp

	ret




	