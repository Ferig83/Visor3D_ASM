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


;--------------------------------------------------------------------

Pintar_WMPAINT:


;; esto esta copiado tal cual está en 3D_pruebas con el agregado de Pintar_Triangulo_Vertices nada más

	push rbp
	mov rbp,rsp
	sub rsp, SHADOWSPACE + 256 ; hay 8*10 parametros, ojo

	push r13

	mov [Pintar.hWnd], rcx
	mov [puntero_triangulo_a_pintar], rdx	

;---------------

	mov   rcx, qword [Pintar.hWnd]                        
	lea   rdx, [ps]                                
 	call  BeginPaint

	mov rcx, [ps.hdc]
	call CreateCompatibleDC
	mov [hdcBuffer],rax
		
	mov rcx, [hdcBuffer]
	mov rdx, [hBitmap]
	call SelectObject
	mov [hbmOld], rax

	mov rcx, [ps.hdc]
	call CreateCompatibleDC
	mov [hdcMem], rax

	mov rcx, [hdcMem]
	mov rdx, [hbitmap_pantalla]    ;; DE DONDE SALIO ESTE
	call SelectObject
	mov [hbmOld], rax		

	mov  rcx, [hdcBuffer]
	lea  rdx, [ps.rcPaint.left]
	mov  r8, [BackgroundBrush]
	call FillRect


;_______Armo la rasterización


	mov r13,0


.loop1:

	xor rdx,rdx
	xor rcx,rcx
	mov rax, TRIANGULO_size
	mul r13
	
	mov rcx, [puntero_triangulo_a_pintar]
	add rcx, rax
	call Rasterizar_Triangulo  ;;call Pintar_Triangulo_Vertices
	

	inc r13
	cmp dword r13d, [array_rasterizacion+ARRAY_DINAMICO__cantidad_elementos]
	jb .loop1


;_______Bliteo

	mov rcx, [hdcBuffer]
	mov rdx, 0;10
	mov r8, 0;10
	mov r9, ANCHO_PANTALLA
	mov qword [rsp + 4*8], ALTO_PANTALLA
	mov rax, [hdcMem]
	mov qword [rsp + 5*8], rax 
	mov qword [rsp + 6*8], 0
	mov qword [rsp + 7*8], 0
	mov qword [rsp + 9*8], 0x00cc0020 ;SCRCOPY
	call BitBlt
	

 
 	mov rcx, [ps.hdc]     
    	mov rdx, 0
    	mov r8, 0
    	mov r9, ANCHO_PANTALLA
    	mov qword [RSP + 4 * 8], ALTO_PANTALLA
    	mov rax, [hdcBuffer]
    	mov qword [RSP + 5 * 8], rax
    	mov qword [RSP + 6 * 8], 0
    	mov qword [RSP + 7 * 8], 0
    	mov qword [RSP + 8 * 8], 0x00CC0020; SCRCOPY
 	call BitBlt


 	;SelectObject(hdcMem, hbmOld);
	mov rcx, [hdcMem]
	mov rdx, [hbmOld]
	call SelectObject
	

    	;DeleteDC(hdcMem);
	mov rcx, [hdcMem]
	call DeleteDC


    	;SelectObject(hdcBuffer, hbmOldBuffer);
	mov rcx, [hdcBuffer]
	mov rdx, [hbmOldBuffer]
	call SelectObject

    	;DeleteDC(hdcBuffer);
	mov rcx, [hdcBuffer]
	call DeleteDC
   

 	;DeleteObject(hbmBuffer);
	mov rcx, [hbmBuffer]
	call DeleteObject

 	mov   rcx, qword [Pintar.hWnd]                        
 	lea   rdx, [ps]                                
 	call  EndPaint




	pop r13

	mov rsp, rbp
	pop rbp

	ret


	