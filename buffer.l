(de blank (W H)
    (mapcar '((Y)
        (mapcar '((X) 
            (list 255 0 0)) (range 1 W)))
                  (range 1 H)))

(de get-image () *Image)

(de set-pixel (X Y)
    (let (R (car (nth *Image Y))
          FR (place X R (list 255 255 255))
          N (place Y *Image FR))
      (setq *Image N)))
