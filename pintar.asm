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

	mov rcx, [Pintar.hWnd]  ; instrucción al dope (ver dos lineas arriba), pero la dejo
	call GetDC	
	mov [DC_pantalla], rax

	mov rcx, [Pintar.hWnd]
	mov rdx, rectangulo_pantalla
	;;;call GetClientRect  ;;; no se cuelga si esta WS_composited... no sé, se ve igual que el composited sirve

;      	mov  rcx, [DC_pantalla]
;	mov  rdx, rectangulo_pantalla
;	mov  r8, [BackgroundBrush]
;	call FillRect


	
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


	mov rcx, qword [Pintar.hWnd]
	mov rdx, [DC_pantalla]
	call ReleaseDC


	pop r13

	mov rsp, rbp
	pop rbp

	ret

	






;--------------------------------------------------------------------






Pintar_WMPAINT:


	push rbp
	mov rbp,rsp
	sub rsp, SHADOWSPACE + 256 ;el 4 es para alinear	

	push r13

	mov [Pintar.hWnd], rcx
	mov [puntero_triangulo_a_pintar], rdx	

	mov   rcx, qword [Pintar.hWnd]                        
 	lea   rdx, [ps]                                
 	call  BeginPaint

    	;HDC hdcBuffer = CreateCompatibleDC(hdc);
    	mov rcx, [ps.hdc]
	call CreateCompatibleDC
	mov [hdcBuffer], rax
	
	;HBITMAP hbmBuffer = CreateCompatibleBitmap(hdc, prc->right, prc->bottom);
	mov rcx, [ps.hdc]
	mov rdx, ANCHO_PANTALLA
	mov r8, ALTO_PANTALLA
	call CreateCompatibleBitmap
	mov [hbmBuffer], rax


    	;HBITMAP hbmOldBuffer = SelectObject(hdcBuffer, hbmBuffer);
	mov rcx, [hdcBuffer]
	mov rdx, [hbmBuffer]
	call SelectObject
	mov [hbmOldBuffer], rax   ;;; COMENTAR PARA DESACTIVAR DOUBLEBUFFERING



    	;HDC hdcMem = CreateCompatibleDC(hdc);
	mov rcx, [ps.hdc]
	call CreateCompatibleDC ;;; COMENTAR PARA DESACTIVAR DOUBLEBUFFERING

	mov [hdcMem], rax    	

	;HBITMAP hbmOld = SelectObject(hdcMem, g_hbmMask);
	mov rcx, [hdcMem]
	mov rdx, [hbitmap_pantalla]
	call SelectObject   ;;; COMENTAR PARA DESACTIVAR DOUBLEBUFFERING

	mov [hbmOld], rax	






;Testeamos no limpiar, pero ya está configurado
	mov  rcx, [hdcBuffer]
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
	mov rcx, [hdcBuffer]
	call Pintar_Triangulo

	inc r13
	cmp qword r13, [cantidad_triangulos_a_rasterizar]
	jb .loop1


;_______Copio el bitmap al DC de la pantalla



    ;ESTA VA, PERO ESTA HECHA ARRIBA : SelectObject(hdcMem, g_hbmBall);
    ; Por lo que la ANULO	
	;mov rcx, [hdcMem]
	;mov rdx, [hbitmap_pantalla]
	;call SelectObject    



    ;mepa que esta de abajo no va
    ;BitBlt(hdcBuffer, g_ballInfo.x, g_ballInfo.y, g_ballInfo.width, g_ballInfo.height, hdcMem, 0, 0, SRCPAINT);
    	mov rcx, [hdcBuffer]     
    	mov rdx, 0
    	mov r8, 0
    	mov r9, ANCHO_PANTALLA
    	mov qword [RSP + 4 * 8], ALTO_PANTALLA
    	mov rax, [hdcMem]
    	mov qword [RSP + 5 * 8], rax
    	mov qword [RSP + 6 * 8], 0
    	mov qword [RSP + 7 * 8], 0
    	mov qword [RSP + 8 * 8], 0x00CC0020; SCRCOPY
    	call BitBlt   ;;; COMENTAR PARA DESACTIVAR DOUBLEBUFFERING





    ;BitBlt(hdc, 0, 0, prc->right, prc->bottom, hdcBuffer, 0, 0, SRCCOPY);
   
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




;_______Decimos que terminamos de pintar


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




	