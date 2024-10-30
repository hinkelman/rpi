;; http://dpmartin42.github.io/posts/r/college-basketball-rankings
;; https://hackastat.eu/en/learn-a-stat-strength-of-schedule-sos/

(import (dataframe))

(define df (csv->dataframe "GameResults.csv"))

(define (calc-wl game-data team type)
  (length (filter (lambda (x) (string=? team x)) ($ game-data type))))

(define (filter-team game-data team)
  (dataframe-filter*
   game-data
   (winner loser)
   (or (string=? winner team)
       (string=? loser team))))

(define (filter-team-opp game-data team opp)
  (dataframe-filter*
   (filter-team game-data team)
   (winner loser)
   (and (not (string=? winner opp))
        (not (string=? loser opp)))))

(define (wp winners team)
  (let ([team-winners (filter (lambda (x) (string=? team x)) winners)])
    (inexact (/ (length team-winners) (length winners)))))

;; no home and away adjustment b/c all played at neutral court
(define (calc-wp game-data team)
  (let ([games-played (filter-team game-data team)])
    (wp ($ games-played 'winner) team)))

(define (calc-pd game-data team)
  (let* ([games-played (filter-team game-data team)])
    (sum (map (lambda (w ws ls) (if (string=? team w) (- ws ls) (- ls ws)))
              ($ games-played 'winner)
              ($ games-played 'winner_score)
              ($ games-played 'loser_score)))))

;; (define (calc-pd game-data team)
;;   (-> game-data
;;       (filter-team team)
;;       (dataframe-modify*
;;        (pd (winner winner_score loser_score)
;;            (if (string=? team winner)
;;                (- winner_score loser_score)
;;                (- loser_score winner_score))))
;;       ($ 'pd)
;;       (sum)))

(define (calc-owp game-data team)
  (let* ([opp-games (filter-team game-data team)]
         [opps (map (lambda (w l) (if (string=? team w) l w))
                    ($ opp-games 'winner)
                    ($ opp-games 'loser))]
         [owp (map (lambda (x) (calc-wp-owp game-data x team)) opps)])
    (mean owp)))

;; wp calc used in calc-owp
(define (calc-wp-owp game-data team opp)
  (let ([games-played (filter-team-opp game-data team opp)])
    (wp ($ games-played 'winner) team)))

(define (calc-oowp game-data team)
  (let* ([opp-games (filter-team game-data team)]
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

(define teams (remove-duplicates (append ($ df 'winner) ($ df 'loser))))

(-> (make-dataframe
     (list (make-series 'Team teams)
           (make-series 'Win (map (lambda (x) (calc-wl df x 'winner)) teams))
           (make-series 'Loss (map (lambda (x) (calc-wl df x 'loser)) teams))
           (make-series 'WP (map (lambda (x) (calc-wp df x)) teams))
           (make-series 'PD (map (lambda (x) (calc-pd df x)) teams))
           (make-series 'SOS (map (lambda (x) (calc-sos df x)) teams))
           (make-series 'RPI (map (lambda (x) (calc-rpi df x)) teams))))
    (dataframe-sort* (> RPI))
    (dataframe-display (length teams)))
