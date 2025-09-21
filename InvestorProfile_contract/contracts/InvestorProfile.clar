;; title: InvestorProfile
;; version: 1.0.0
;; summary: Address reputation system for investor behavior and portfolio performance scoring
;; description: A smart contract that tracks investor profiles, portfolio performance, and calculates reputation scores

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PROFILE-NOT-FOUND (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-INVALID-SCORE (err u4))
(define-constant ERR-PROFILE-ALREADY-EXISTS (err u5))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures

;; Investor profile data
(define-map investor-profiles
  { address: principal }
  {
    total-investments: uint,
    successful-investments: uint,
    failed-investments: uint,
    total-portfolio-value: uint,
    reputation-score: uint,
    registration-block: uint,
    last-updated: uint,
    is-verified: bool
  }
)

;; Investment tracking
(define-map investment-history
  { investor: principal, investment-id: uint }
  {
    amount: uint,
    investment-type: (string-ascii 50),
    timestamp: uint,
    outcome: (optional bool), ;; none = pending, true = success, false = failure
    roi-percentage: int ;; return on investment as percentage (can be negative)
  }
)

;; Investment counter for each investor
(define-map investment-counters
  { investor: principal }
  { counter: uint }
)

;; Reputation score weights (can be updated by contract owner)
(define-data-var success-rate-weight uint u40)
(define-data-var portfolio-value-weight uint u30)
(define-data-var experience-weight uint u20)
(define-data-var verification-weight uint u10)

;; Total number of registered investors
(define-data-var total-investors uint u0)

;; Public functions

;; Register a new investor profile
(define-public (register-investor)
  (let (
    (caller tx-sender)
    (current-block block-height)
  )
    ;; Check if profile already exists
    (asserts! (is-none (map-get? investor-profiles { address: caller })) ERR-PROFILE-ALREADY-EXISTS)

    ;; Create new profile
    (map-set investor-profiles
      { address: caller }
      {
        total-investments: u0,
        successful-investments: u0,
        failed-investments: u0,
        total-portfolio-value: u0,
        reputation-score: u0,
        registration-block: current-block,
        last-updated: current-block,
        is-verified: false
      }
    )

    ;; Initialize investment counter
    (map-set investment-counters
      { investor: caller }
      { counter: u0 }
    )

    ;; Increment total investors
    (var-set total-investors (+ (var-get total-investors) u1))

    (ok true)
  )
)

;; Record a new investment
(define-public (record-investment (amount uint) (investment-type (string-ascii 50)))
  (let (
    (caller tx-sender)
    (current-block block-height)
    (counter-data (default-to { counter: u0 } (map-get? investment-counters { investor: caller })))
    (new-counter (+ (get counter counter-data) u1))
  )
    ;; Validate input
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    ;; Check if investor profile exists
    (asserts! (is-some (map-get? investor-profiles { address: caller })) ERR-PROFILE-NOT-FOUND)

    ;; Record the investment
    (map-set investment-history
      { investor: caller, investment-id: new-counter }
      {
        amount: amount,
        investment-type: investment-type,
        timestamp: current-block,
        outcome: none,
        roi-percentage: 0
      }
    )

    ;; Update investment counter
    (map-set investment-counters
      { investor: caller }
      { counter: new-counter }
    )

    ;; Update investor profile
    (match (map-get? investor-profiles { address: caller })
      profile (begin
        (map-set investor-profiles
          { address: caller }
          (merge profile {
            total-investments: (+ (get total-investments profile) u1),
            total-portfolio-value: (+ (get total-portfolio-value profile) amount),
            last-updated: current-block
          })
        )
        (ok true)
      )
      ERR-PROFILE-NOT-FOUND
    )
  )
)

;; Update investment outcome
(define-public (update-investment-outcome (investment-id uint) (success bool) (roi-percentage int))
  (let (
    (caller tx-sender)
    (current-block block-height)
  )
    ;; Check if investment exists
    (match (map-get? investment-history { investor: caller, investment-id: investment-id })
      investment (begin
        ;; Update investment outcome
        (map-set investment-history
          { investor: caller, investment-id: investment-id }
          (merge investment {
            outcome: (some success),
            roi-percentage: roi-percentage
          })
        )

        ;; Update investor profile statistics
        (match (map-get? investor-profiles { address: caller })
          profile (begin
            (map-set investor-profiles
              { address: caller }
              (merge profile {
                successful-investments: (if success
                  (+ (get successful-investments profile) u1)
                  (get successful-investments profile)),
                failed-investments: (if success
                  (get failed-investments profile)
                  (+ (get failed-investments profile) u1)),
                last-updated: current-block
              })
            )
            ;; Recalculate reputation score
            (try! (calculate-and-update-reputation caller))
            (ok true)
          )
          ERR-PROFILE-NOT-FOUND
        )
      )
      ERR-PROFILE-NOT-FOUND
    )
  )
)

;; Verify an investor (only contract owner)
(define-public (verify-investor (investor principal))
  (begin
    ;; Check authorization
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update verification status
    (match (map-get? investor-profiles { address: investor })
      profile (begin
        (map-set investor-profiles
          { address: investor }
          (merge profile { is-verified: true, last-updated: block-height })
        )
        ;; Recalculate reputation score with verification bonus
        (try! (calculate-and-update-reputation investor))
        (ok true)
      )
      ERR-PROFILE-NOT-FOUND
    )
  )
)

;; Update reputation score weights (only contract owner)
(define-public (update-score-weights (new-success-weight uint) (new-portfolio-weight uint) (new-experience-weight uint) (new-verification-weight uint))
  (begin
    ;; Check authorization
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Validate weights sum to 100
    (asserts! (is-eq (+ new-success-weight new-portfolio-weight new-experience-weight new-verification-weight) u100) ERR-INVALID-SCORE)

    ;; Update weights
    (var-set success-rate-weight new-success-weight)
    (var-set portfolio-value-weight new-portfolio-weight)
    (var-set experience-weight new-experience-weight)
    (var-set verification-weight new-verification-weight)

    (ok true)
  )
)

;; Read-only functions

;; Get investor profile
(define-read-only (get-investor-profile (investor principal))
  (map-get? investor-profiles { address: investor })
)

;; Get investment details
(define-read-only (get-investment (investor principal) (investment-id uint))
  (map-get? investment-history { investor: investor, investment-id: investment-id })
)

;; Get investor's total investments count
(define-read-only (get-investment-count (investor principal))
  (match (map-get? investment-counters { investor: investor })
    counter (get counter counter)
    u0
  )
)

;; Calculate success rate percentage
(define-read-only (get-success-rate (investor principal))
  (match (map-get? investor-profiles { address: investor })
    profile (let (
      (total (get total-investments profile))
      (successful (get successful-investments profile))
    )
      (if (> total u0)
        (/ (* successful u100) total)
        u0
      )
    )
    u0
  )
)

;; Get current reputation score weights
(define-read-only (get-score-weights)
  {
    success-rate-weight: (var-get success-rate-weight),
    portfolio-value-weight: (var-get portfolio-value-weight),
    experience-weight: (var-get experience-weight),
    verification-weight: (var-get verification-weight)
  }
)

;; Get total number of registered investors
(define-read-only (get-total-investors)
  (var-get total-investors)
)

;; Get investor rank based on reputation score
(define-read-only (get-investor-rank (investor principal))
  (match (map-get? investor-profiles { address: investor })
    profile (let (
      (score (get reputation-score profile))
    )
      (if (>= score u90)
        "Elite"
        (if (>= score u75)
          "Expert"
          (if (>= score u60)
            "Advanced"
            (if (>= score u40)
              "Intermediate"
              (if (>= score u20)
                "Novice"
                "Beginner"
              )
            )
          )
        )
      )
    )
    "Not Registered"
  )
)

;; Private functions

;; Calculate and update reputation score
(define-private (calculate-and-update-reputation (investor principal))
  (match (map-get? investor-profiles { address: investor })
    profile (let (
      (success-rate (get-success-rate investor))
      (portfolio-value (get total-portfolio-value profile))
      (total-investments (get total-investments profile))
      (is-verified (get is-verified profile))
      (blocks-since-registration (- block-height (get registration-block profile)))

      ;; Calculate weighted scores
      (success-score (/ (* success-rate (var-get success-rate-weight)) u100))
      (portfolio-score (/ (* (min portfolio-value u1000000) (var-get portfolio-value-weight)) u10000)) ;; Cap at 1M for scoring
      (experience-score (/ (* (min total-investments u100) (var-get experience-weight)) u100)) ;; Cap at 100 investments
      (verification-score (if is-verified (var-get verification-weight) u0))

      ;; Calculate final reputation score
      (reputation-score (+ success-score portfolio-score experience-score verification-score))
    )
      ;; Update the profile with new reputation score
      (map-set investor-profiles
        { address: investor }
        (merge profile { reputation-score: reputation-score })
      )
      (ok reputation-score)
    )
    ERR-PROFILE-NOT-FOUND
  )
)

;; Helper function to get minimum of two values
(define-private (min (a uint) (b uint))
  (if (<= a b) a b)
)