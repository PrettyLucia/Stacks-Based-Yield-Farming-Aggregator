;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1000))
(define-constant ERR_INVALID_POOL (err u1001))
(define-constant ERR_INVALID_PROTOCOL (err u1002))
(define-constant ERR_INVALID_AMOUNT (err u1003))
(define-constant ERR_INSUFFICIENT_BALANCE (err u1004))
(define-constant ERR_STRATEGY_NOT_FOUND (err u1005))
(define-constant ERR_PROTOCOL_PAUSED (err u1006))
(define-constant ERR_SLIPPAGE_EXCEEDED (err u1007))
(define-constant ERR_INVALID_TOKEN (err u1008))
(define-constant ERR_CALCULATION_ERROR (err u1009))
(define-constant ERR_DEPOSIT_FAILED (err u1010))
(define-constant ERR_WITHDRAW_FAILED (err u1011))
(define-constant ERR_HARVEST_FAILED (err u1012))
(define-constant ERR_INVALID_STRATEGY (err u1013))
(define-constant ERR_STRATEGY_EXECUTION_FAILED (err u1014))
(define-constant ERR_MINIMUM_DEPOSIT (err u1015))
(define-constant ERR_MAXIMUM_CAPACITY (err u1016))
(define-constant ERR_TOKEN_UNSUPPORTED (err u1017))
(define-constant ERR_REBALANCE_TOO_SOON (err u1018))


;; Protocol status
(define-data-var protocol-paused bool false)

;; Fee settings (in basis points, 1/100 of a percent)
(define-data-var performance-fee-bps uint u1000) ;; 10% performance fee
(define-data-var withdrawal-fee-bps uint u50) ;; 0.5% withdrawal fee
(define-data-var basis-points-denominator uint u10000) ;; 10000 basis points = 100%

;; Protocol fee split ratios
(define-data-var treasury-allocation uint u3000) ;; 30% to treasury
(define-data-var staking-allocation uint u5000) ;; 50% to stakers
(define-data-var insurance-allocation uint u2000) ;; 20% to insurance fund


