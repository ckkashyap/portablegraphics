(de server-init (W H Ttl)
      (setq *ImageChanged T)
      (setq *Width W)
      (setq *Height H)
      (wr16 W) # WIDTH
      (wr16 H) # HEIGHT
      (wr 32) # BPP
      (wr 24) # depth
      (wr 1) # big endian
      (wr 1) # true color
      (wr16 255) # red max
      (wr 0 255) # green max
      (wr 0 255) # blue max
      (wr 16) # red shift
      (wr 8) # green shift
      (wr 0) # blue shift
      (wr 0) # padding
      (wr 0) #  padding
      (wr 0) #  padding
      (wr32 (length Ttl))
      (prin Ttl))

(de handshake (Skt W H Ttl)
  (out Skt (prinl "RFB 003.003"))
  (prinl (in Skt (line)))
  (out Skt (wr32 1)) # security
  (in Skt (rd 1)) # should share?
  (out Skt (server-init W H Ttl)))

(de set-pixel-format (Skt)
    (prinl "SetPixelFormat")
    (in Skt
        (let (
            _ (rd 3) # padding
            BPP (rd 1)
	    DEPTH (rd 1)
	    BIG (rd 1)
	    TC (rd 1)
	    RMAX (rd 2)
	    GMAX (rd 2)
	    BMAX (rd 2)
	    RSHFT (rd 1)
	    GSHFT (rd 1)
	    BSHFT (rd 1)
	    _ (rd 3)
            )
              (until (member BPP (list 8 24 32))
                     (prinl BPP " bits per pixel is not supported")
                     (prinl "Only 8, 16 and 24 bits per pixel supported")
                     (bye))
              (prinl "Setting " BPP " bits per pixel")
              (setq *BPP BPP))))
        

(de set-encodings (Skt)
    (prinl "SetEncodings")
    (in Skt
        (rd 1) # padding
	(let N (rd 2)
             (prinl N " Encodings from the client")
             (rd (* 4 N)))))

(de key-event (Skt)
    (prin "KeyEvent -> ")
    (in Skt
    (let (DownFlag (rd 1)
          _ (rd 2) # padding
          Key (rd 4))
       (prinl Key " " DownFlag))))


(de set-pixel (X Y)
    (let (R (car (nth *Image Y))
          FR (place X R (list 255 255 255))
          N (place Y *Image FR))
      (setq *Image N)))

(de pointer-event (Skt SetPixel GetImage)
    (prin "PointerEvent -> ")
    (in Skt
    (let (ButtonMask (rd 1)
          X (rd 2)
          Y (rd 2))
       
       (SetPixel (inc X) (inc Y))
       (unless *ImageChanged
             (setq *ImageChanged T)
             (send-pixel-update Skt GetImage X Y))
       (prinl ButtonMask " " X ", " Y))))

(de send-pixel-update (Skt GetImage X Y)
(when *ImageChanged
    (out Skt
        (wr 0) # FB update
        (wr 0) # padding
        (wr 0)
        (wr 1) # of rectangles
        (wr16 X) # X
        (wr16 Y) # Y
        (wr16 1) # width
        (wr16 1) # height
        (wr32 0) # raw encoding
    
	  (case *BPP
	      (32 (wr 255 255 255 255))
	      (24 (wr 255 255 255))
	      (8 (wr 0)))
         
         (setq *ImageChanged NIL))))

(de send-frame-buffer-update (Skt GetImage W H)
(when *ImageChanged
    (out Skt
        (wr 0) # FB update
        (wr 0) # padding
    
        (wr 0)
        (wr 1) # of rectangles
    
        (wr16 0) # X
        (wr16 0) # Y
        (wr16 W) # width
        (wr16 H) # height
        (wr32 0) # raw encoding
    
        (for I (GetImage)
             (for J I
                  (case *BPP
                      (32 (wr (car J) (cadr J) (caddr J) 255))
                      (24 (wr 255 (cadr J) (caddr J)))
                      (8 (wr 3))))))
         
         (setq *ImageChanged NIL)))

(de frame-buffer-request (Skt GetImage)
 (in Skt
    (prin "Framebuffer request -> ")
    (let (Incremental (rd 1)
          X (rd 2)
          Y (rd 2)
          W (rd 2)
          H (rd 2))
       (prinl Incremental " " X " " Y " " W " " H " " *BPP)
       (send-frame-buffer-update Skt GetImage W H)
       )))

                    
(de client-cut-text (Skt)
    (prin "ClientCutText -> ")
    (in Skt
    (let (_ (rd 3) # padding
          Length (rd 4)
          Text (rd Length))
       (prinl Length))))
         
(de process-command (Skt GetImage SetPixel)
	  (case (in Skt (rd 1))
	      (0 (set-pixel-format Skt))
	      (2 (set-encodings Skt))
	      (3 (frame-buffer-request Skt GetImage))
	      (4 (key-event Skt))
	      (5 (pointer-event Skt SetPixel GetImage))
	      (6 (client-cut-text Skt))))
