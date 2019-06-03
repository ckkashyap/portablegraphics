(load "binary.l")
(load "rfb.l")
(load "buffer.l")
(setq *Port (port 5900))

(setq *Width 500)
(setq *Height 300)
(setq *Image (blank *Width *Height))

(loop
 (setq *Sock (listen *Port))
 (unless (fork)
    (close *Port)
    (handshake *Sock *Width *Height "Hello VNC")
    (loop (process-command *Sock get-image set-pixel))
    (bye))
 (close *Sock))
