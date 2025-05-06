;; Load Forecasting Contract
;; Predicts peak demand periods

(define-data-var admin principal tx-sender)

;; Map to store forecasts by date
(define-map forecasts
  uint  ;; timestamp (in seconds since epoch)
  {
    predicted-load: uint,
    peak-start-time: uint,
    peak-end-time: uint,
    threshold: uint
  })

;; Error codes
(define-constant err-not-admin (err u300))
(define-constant err-forecast-exists (err u301))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Add a new forecast
(define-public (add-forecast
  (timestamp uint)
  (predicted-load uint)
  (peak-start-time uint)
  (peak-end-time uint)
  (threshold uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (asserts! (is-none (map-get? forecasts timestamp)) err-forecast-exists)
    (ok (map-set forecasts timestamp {
      predicted-load: predicted-load,
      peak-start-time: peak-start-time,
      peak-end-time: peak-end-time,
      threshold: threshold
    }))))

;; Update an existing forecast
(define-public (update-forecast
  (timestamp uint)
  (predicted-load uint)
  (peak-start-time uint)
  (peak-end-time uint)
  (threshold uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (map-set forecasts timestamp {
      predicted-load: predicted-load,
      peak-start-time: peak-start-time,
      peak-end-time: peak-end-time,
      threshold: threshold
    }))))

;; Get forecast for a specific date
(define-read-only (get-forecast (timestamp uint))
  (map-get? forecasts timestamp))

;; Check if current time is within peak period
(define-read-only (is-peak-period (timestamp uint))
  (let ((forecast (map-get? forecasts timestamp)))
    (if (is-some forecast)
      (let ((forecast-data (unwrap-panic forecast)))
        (and
          (>= block-height (get peak-start-time forecast-data))
          (<= block-height (get peak-end-time forecast-data))))
      false)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))
