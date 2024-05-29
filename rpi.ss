;; http://dpmartin42.github.io/posts/r/college-basketball-rankings
;; https://hackastat.eu/en/learn-a-stat-strength-of-schedule-sos/
;; run from terminal with scheme --script rpi.ss 4
;; where 4 indicates max number of weeks to include

(import (dataframe))

(define df (csv->dataframe "GameResults.csv"))
(define teams (remove-duplicates (append ($ df 'winner) ($ df 'loser))))

;; no home and away adjustment b/c all played at neutral court
(define (calc-wp game-data team)
  (calc-wp-helper (game-filter game-data team) team))

;; used in calc-owp
(define (calc-wp2 game-data team team-drop)
  (calc-wp-helper (game-filter2 game-data team team-drop) team))

(define (calc-wp-helper games-played team)
  (let* ([all-winners ($ games-played 'winner)]
         [team-winners (filter (lambda (x) (string=? team x)) all-winners)])
    (inexact (/ (length team-winners) (length all-winners)))))

(define (game-filter df team)
  (dataframe-filter*
   df
   (winner loser)
   (or (string=? winner team)
       (string=? loser team))))

(define (game-filter2 df team team-drop)
  (dataframe-filter*
   df
   (winner loser)
   (and (or (string=? winner team)
            (string=? loser team))
        (not (string=? winner team-drop))
        (not (string=? loser team-drop)))))

(define (calc-wl game-data team type)
  (length (filter (lambda (x) (string=? team x)) ($ game-data type))))

(define (calc-pd game-data team)
  (let* ([games-played (game-filter game-data team)])
    (sum (map (lambda (w ws ls) (if (string=? team w) (- ws ls) (- ls ws)))
              ($ games-played 'winner)
              ($ games-played 'winner_score)
              ($ games-played 'loser_score)))))

;; (define (calc-pd game-data team)
;;   (-> game-data
;;       (game-filter team)
;;       (dataframe-modify*
;;        (pd (winner winner_score loser_score)
;;            (if (string=? team winner)
;;                (- winner_score loser_score)
;;                (- loser_score winner_score))))
;;       ($ 'pd)
;;       (sum)))
 
(define (calc-owp game-data team)
  (let* ([opp-games (game-filter game-data team)]
         [opps (map (lambda (w l) (if (string=? team w) l w))
                    ($ opp-games 'winner)
                    ($ opp-games 'loser))]
         [owp (map (lambda (x) (calc-wp2 game-data x team)) opps)])
    (mean owp)))

(define (calc-oowp game-data team)
  (let* ([opp-games (game-filter game-data team)]
         [opps (map (lambda (w l) (if (string=? team w) l w))
                    ($ opp-games 'winner)
                    ($ opp-games 'loser))]
         [oowp (map (lambda (x) (calc-owp game-data x)) opps)])
    (mean oowp)))

(define (calc-sos game-data team)
  (/ (+ (* 2 (calc-owp game-data team)) (calc-oowp game-data team)) 3))

(define (calc-rpi game-data team)
  (+ (* 0.25 (calc-wp game-data team))
     (* 0.5 (calc-owp game-data team))
     (* 0.25 (calc-oowp game-data team))))

(define df2
  (dataframe-filter*
   df
   (week)
   (<= week (string->number (cadr (command-line))))))

(-> (make-dataframe (list (make-series 'Team teams)
                          (make-series 'Win (map (lambda (x) (calc-wl df2 x 'winner)) teams))
                          (make-series 'Loss (map (lambda (x) (calc-wl df2 x 'loser)) teams))
                          (make-series 'WP (map (lambda (x) (calc-wp df2 x)) teams))
                          (make-series 'PD (map (lambda (x) (calc-pd df2 x)) teams))
                          (make-series 'SOS (map (lambda (x) (calc-sos df2 x)) teams))
                          (make-series 'RPI (map (lambda (x) (calc-rpi df2 x)) teams))))
    (dataframe-sort* (> RPI))
    (dataframe-display 14))

(exit)
         

                   
