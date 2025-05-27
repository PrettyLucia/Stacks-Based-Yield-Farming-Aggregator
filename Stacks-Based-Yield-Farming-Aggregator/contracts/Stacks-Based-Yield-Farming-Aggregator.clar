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

;; Minimum deposit amounts
(define-map minimum-deposits principal uint)

;; Treasury and insurance fund addresses
(define-data-var treasury-address principal CONTRACT_OWNER)
(define-data-var insurance-fund-address principal CONTRACT_OWNER)

;; Protocol settings
(define-data-var auto-compound-interval uint u24) ;; Hours between auto-compounds
(define-data-var minimum-rebalance-interval uint u168) ;; 7 days (168 hours) between rebalances
(define-data-var maximum-slippage uint u30) ;; 0.3% maximum slippage

;; Supported protocols data
(define-map supported-protocols principal {
  name: (string-ascii 64),
  active: bool,
  tvl-cap: uint, ;; Maximum TVL allowed in this protocol
  risk-score: uint, ;; Risk score from 1-100 (1 is safest)
  audited: bool,
  last-harvest-block: uint,
  last-apr: uint, ;; Last recorded APR in basis points
  protocol-type: (string-ascii 32) ;; lending, AMM, staking, etc.
})

;; Token risk assessments
(define-map token-risk-scores principal {
  volatility-score: uint, ;; 1-100 (1 is lowest volatility)
  liquidity-score: uint, ;; 1-100 (1 is highest liquidity)
  market-cap-score: uint, ;; 1-100 (1 is highest market cap)
  composite-score: uint, ;; Weighted average of above
  risk-level: (string-ascii 16) ;; "low", "medium", "high"
})

;; Token pricing data
(define-map token-prices principal {
  price-in-ustx: uint,
  last-updated: uint,
  source: (string-ascii 32)
})

;; Farming pool data
(define-map farming-pools {protocol: principal, pool-id: uint} {
  input-token: principal, ;; Token to deposit
  reward-token: principal, ;; Token received as reward
  total-staked: uint, ;; Total tokens staked in this pool
  current-apr: uint, ;; Current APR in basis points
  max-capacity: uint, ;; Max capacity of this pool
  active: bool,
  compounded: bool, ;; Whether rewards auto-compound
  last-harvest-block: uint,
  last-rebalance-block: uint,
  historical-apr: (list 30 uint), ;; Last 30 days APR in basis points
  impermanent-loss-factor: uint, ;; IL factor if applicable (0 for single-asset)
  address: principal ;; Contract address
})

;; User positions
(define-map user-positions {user: principal, strategy-id: uint} {
  principal-amount: uint, ;; Original deposit amount
  share-amount: uint, ;; Shares in the strategy
  entry-price: uint, ;; Entry price for perf calculation
  deposit-block: uint, ;; Block when deposited
  last-harvest-block: uint, ;; Last block when user harvested
  claimed-rewards: uint, ;; Total rewards claimed
  unclaimed-rewards: uint ;; Pending rewards
})

;; User totals across all strategies
(define-map user-totals principal {
  total-value-locked: uint,
  total-earnings: uint,
  strategies-count: uint,
  compound-preference: bool ;; Whether user prefers auto-compounding
})

;; Strategy definitions
(define-map strategies uint {
  name: (string-ascii 64),
  description: (string-ascii 256),
  input-token: principal,
  active: bool,
  risk-level: (string-ascii 16), ;; "low", "medium", "high"
  allocation-map: (list 10 {protocol: principal, pool-id: uint, allocation: uint}), ;; Protocol and allocation in percentage
  total-allocation: uint, ;; Must sum to 10000 (100%)
  total-apy: uint, ;; Combined APY in basis points
  total-staked: uint, ;; Total amount staked in this strategy
  share-price: uint, ;; Current price per share
  share-token: principal, ;; Token representing shares
  auto-compound: bool, ;; Whether strategy auto-compounds
  last-rebalance-block: uint,
  creation-block: uint,
  performance-history: (list 30 {block: uint, apy: uint}) ;; Historical performance
})

;; Strategy counter
(define-data-var next-strategy-id uint u1)

;; Harvested rewards tracking
(define-map harvested-rewards {protocol: principal, pool-id: uint} {
  last-amount: uint,
  total-amount: uint,
  last-harvest-block: uint
})

;; Protocol revenue tracking
(define-map protocol-revenue {
  token: principal
} {
  performance-fees: uint,
  withdrawal-fees: uint,
  total-fees: uint
})

;; Historical APY data for each protocol
(define-map protocol-apy-history {protocol: principal, day: uint} uint)

;; User activity log
(define-map user-activity {user: principal, activity-id: uint} {
  activity-type: (string-ascii 16), ;; "deposit", "withdraw", "harvest", "claim"
  strategy-id: uint,
  amount: uint,
  block-height: uint,
  success: bool
})

;; User activity counter
(define-map user-activity-count principal uint)

;; === Protocol Management Functions ===

;; Pause/unpause protocol
(define-public (set-protocol-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (var-set protocol-paused paused))))

;; Set fee parameters
(define-public (set-performance-fee (fee-bps uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= fee-bps u2000) ERR_INVALID_AMOUNT) ;; Max 20% fee
    (ok (var-set performance-fee-bps fee-bps))))

(define-public (set-withdrawal-fee (fee-bps uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= fee-bps u500) ERR_INVALID_AMOUNT) ;; Max 5% fee
    (ok (var-set withdrawal-fee-bps fee-bps))))

;; Set fee allocations
(define-public (set-fee-allocations (treasury uint) (staking uint) (insurance uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (+ (+ treasury staking) insurance) u10000) ERR_INVALID_AMOUNT)
    (var-set treasury-allocation treasury)
    (var-set staking-allocation staking)
    (var-set insurance-allocation insurance)
    (ok true)))

;; Set treasury and insurance fund addresses
(define-public (set-treasury-address (address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (var-set treasury-address address))))

(define-public (set-insurance-fund-address (address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (var-set insurance-fund-address address))))


;; Add or update supported protocol
(define-public (add-supported-protocol 
                (protocol-address principal) 
                (name (string-ascii 64))
                (tvl-cap uint)
                (risk-score uint)
                (audited bool)
                (protocol-type (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= risk-score u100) ERR_INVALID_AMOUNT)
    
    (ok (map-set supported-protocols protocol-address {
      name: name,
      active: true,
      tvl-cap: tvl-cap,
      risk-score: risk-score,
      audited: audited,
      last-harvest-block: u0,
      last-apr: u0,
      protocol-type: protocol-type
    }))))

;; Update protocol status
(define-public (update-protocol-status (protocol-address principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (let ((protocol (unwrap! (map-get? supported-protocols protocol-address) ERR_INVALID_PROTOCOL)))
      (ok (map-set supported-protocols protocol-address (merge protocol {active: active}))))))

;; Add or update farming pool
(define-public (add-farming-pool 
                (protocol-address principal) 
                (pool-id uint)
                (input-token principal)
                (reward-token principal)
                (max-capacity uint)
                (compounded bool)
                (impermanent-loss-factor uint)
                (pool-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (is-none (map-get? supported-protocols protocol-address))) ERR_INVALID_PROTOCOL)
    
    (ok (map-set farming-pools {protocol: protocol-address, pool-id: pool-id} {
      input-token: input-token,
      reward-token: reward-token,
      total-staked: u0,
      current-apr: u0,
      max-capacity: max-capacity,
      active: true,
      compounded: compounded,
      last-harvest-block: u0,
      last-rebalance-block: u0,
      historical-apr: (list),
      impermanent-loss-factor: impermanent-loss-factor,
      address: pool-address
    }))))

;; Update token price
(define-public (update-token-price (token principal) (price-in-ustx uint) (source (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (ok (map-set token-prices token {
      price-in-ustx: price-in-ustx,
      last-updated: stacks-block-height,
      source: source
    }))))

;; Set minimum deposit for a token
(define-public (set-minimum-deposit (token principal) (min-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set minimum-deposits token min-amount))))


