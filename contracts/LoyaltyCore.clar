;; LoyaltyCore.clar
;; Core contract for decentralized loyalty program

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_INVALID_INPUT (err u104))
(define-constant ERR_ARITHMETIC_OVERFLOW (err u105))
(define-constant MAX_POINTS_PER_TRANSACTION u1000000)

;; Data maps
(define-map Businesses principal { name: (string-ascii 50), active: bool })
(define-map UserPoints { user: principal, business: principal } uint)
(define-map BusinessTotalPoints principal uint)

;; Private functions

;; Safe addition
(define-private (safe-add (a uint) (b uint))
  (let ((sum (+ a b)))
    (if (>= sum a)
        (ok sum)
        (err ERR_ARITHMETIC_OVERFLOW))))

;; Safe subtraction
(define-private (safe-subtract (a uint) (b uint))
  (if (>= a b)
      (ok (- a b))
      (err ERR_ARITHMETIC_OVERFLOW)))

;; Public functions

;; Register a new business
(define-public (register-business (name (string-ascii 50)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? Businesses caller)) ERR_ALREADY_EXISTS)
    (asserts! (and (> (len name) u0) (<= (len name) u50)) ERR_INVALID_INPUT)
    (ok (map-insert Businesses caller { name: name, active: true }))))

;; Issue points to a user
(define-public (issue-points (user principal) (amount uint))
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? Businesses caller)) ERR_UNAUTHORIZED)
    (asserts! (is-ok (principal-destruct? user)) ERR_INVALID_INPUT)
    (asserts! (<= amount MAX_POINTS_PER_TRANSACTION) ERR_INVALID_INPUT)
    (let ((current-points (default-to u0 (map-get? UserPoints { user: user, business: caller }))))
      (match (safe-add current-points amount)
        new-points
          (match (safe-add (default-to u0 (map-get? BusinessTotalPoints caller)) amount)
            new-total 
              (begin
                (map-set UserPoints { user: user, business: caller } new-points)
                (map-set BusinessTotalPoints caller new-total)
                (ok new-points))
            err-value err-value)
        err-value err-value))))

;; Redeem points
(define-public (redeem-points (business principal) (amount uint))
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? Businesses business)) ERR_NOT_FOUND)
    (asserts! (<= amount MAX_POINTS_PER_TRANSACTION) ERR_INVALID_INPUT)
    (let ((current-points (default-to u0 (map-get? UserPoints { user: caller, business: business }))))
      (asserts! (>= current-points amount) ERR_INSUFFICIENT_BALANCE)
      (match (safe-subtract current-points amount)
        new-points
          (match (safe-subtract (default-to u0 (map-get? BusinessTotalPoints business)) amount)
            new-total 
              (begin
                (map-set UserPoints { user: caller, business: business } new-points)
                (map-set BusinessTotalPoints business new-total)
                (ok new-points))
            err-value err-value)
        err-value err-value))))

;; Read-only functions

;; Check if an address is a registered business
(define-read-only (is-business (address principal))
  (is-some (map-get? Businesses address)))

;; Get user points for a specific business
(define-read-only (get-user-points (user principal) (business principal))
  (default-to u0 (map-get? UserPoints { user: user, business: business })))

;; Get total points issued by a business
(define-read-only (get-business-total-points (business principal))
  (default-to u0 (map-get? BusinessTotalPoints business)))

;; Get business details
(define-read-only (get-business-details (business principal))
  (map-get? Businesses business))
