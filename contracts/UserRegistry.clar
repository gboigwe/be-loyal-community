;; UserRegistry.clar
;; Contract for managing user registrations in the loyalty program

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_INPUT (err u103))
(define-constant ERR_INSUFFICIENT_POINTS (err u104))

;; Data maps
(define-map Users
  principal
  {
    username: (string-ascii 50),
    email: (string-ascii 100),
    registration-date: uint,
    last-activity: uint,
    total-points: uint,
    tier: (string-ascii 20)
  }
)

(define-map Tiers
  (string-ascii 20)
  {
    points-threshold: uint,
    benefits: (string-utf8 280)
  }
)

;; Variables
(define-data-var UserCount uint u0)
(define-data-var TierList (list 10 (string-ascii 20)) (list ))

;; Private functions

;; Get tier based on points
(define-private (get-tier-for-points (points uint))
  (let ((bronze-threshold (default-to u0 (get points-threshold (map-get? Tiers "Bronze"))))
        (silver-threshold (default-to u0 (get points-threshold (map-get? Tiers "Silver"))))
        (gold-threshold (default-to u0 (get points-threshold (map-get? Tiers "Gold"))))
        (platinum-threshold (default-to u0 (get points-threshold (map-get? Tiers "Platinum")))))
    (if (>= points platinum-threshold)
      "Platinum"
      (if (>= points gold-threshold)
        "Gold"
        (if (>= points silver-threshold)
          "Silver"
          "Bronze")))))

;; Public functions

;; Register a new user
(define-public (register-user (username (string-ascii 50)) (email (string-ascii 100)))
  (let ((caller tx-sender))
    (asserts! (and (> (len username) u0) (<= (len username) u50)) ERR_INVALID_INPUT)
    (asserts! (and (> (len email) u0) (<= (len email) u100)) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? Users caller)) ERR_ALREADY_EXISTS)
    (map-set Users caller
      {
        username: username,
        email: email,
        registration-date: block-height,
        last-activity: block-height,
        total-points: u0,
        tier: "Bronze" ;; Default tier
      }
    )
    (var-set UserCount (+ (var-get UserCount) u1))
    (ok true)
  )
)

;; Update user profile
(define-public (update-user-profile (username (string-ascii 50)) (email (string-ascii 100)))
  (let ((caller tx-sender))
    (asserts! (and (> (len username) u0) (<= (len username) u50)) ERR_INVALID_INPUT)
    (asserts! (and (> (len email) u0) (<= (len email) u100)) ERR_INVALID_INPUT)
    (match (map-get? Users caller)
      user (ok (map-set Users caller
                (merge user
                  {
                    username: username,
                    email: email,
                    last-activity: block-height
                  }
                )))
      ERR_NOT_FOUND
    )
  )
)

;; Update user points (to be called by LoyaltyCore contract)
(define-public (update-user-points (user principal) (points-delta int))
  (let ((caller tx-sender))
    (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED) ;; Ensure only the LoyaltyCore contract can call this
    (match (map-get? Users user)
      existing-user 
        (let ((current-points (get total-points existing-user))
              (new-total (if (> points-delta 0)
                            (+ current-points (to-uint points-delta))
                            (if (>= current-points (to-uint (abs points-delta)))
                              (- current-points (to-uint (abs points-delta)))
                              u0))))
          (let ((new-tier (get-tier-for-points new-total)))
            (ok (map-set Users user
              (merge existing-user
                {
                  total-points: new-total,
                  tier: new-tier,
                  last-activity: block-height
                }
              ))))
        )
      ERR_NOT_FOUND
    )
  )
)

;; Add a new tier (only contract owner)
(define-public (add-tier (tier-name (string-ascii 20)) (points-threshold uint) (benefits (string-utf8 280)))
  (let ((caller tx-sender)
        (current-tiers (var-get TierList)))
    (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (> (len tier-name) u0) (<= (len tier-name) u20)) ERR_INVALID_INPUT)
    (asserts! (and (> (len benefits) u0) (<= (len benefits) u280)) ERR_INVALID_INPUT)
    (asserts! (< (len current-tiers) u10) ERR_INVALID_INPUT)
    (map-insert Tiers tier-name { points-threshold: points-threshold, benefits: benefits })
    (var-set TierList (unwrap-panic (as-max-len? (append current-tiers tier-name) u10)))
    (ok true)
  )
)

;; Read-only functions

;; Get user details
(define-read-only (get-user-details (user principal))
  (map-get? Users user))

;; Get user count
(define-read-only (get-user-count)
  (var-get UserCount))

;; Get tier details
(define-read-only (get-tier-details (tier-name (string-ascii 20)))
  (map-get? Tiers tier-name))

;; Get all tiers
(define-read-only (get-all-tiers)
  (var-get TierList))
