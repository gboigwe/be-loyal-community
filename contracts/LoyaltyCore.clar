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

;; Validate and sanitize string input
(define-private (validate-string (input (string-ascii 50)))
  (if (and (> (len input) u0) (<= (len input) u50))
      (ok input)
      (err ERR_INVALID_INPUT)))

;; Validate amount
(define-private (validate-amount (amount uint))
  (if (<= amount MAX_POINTS_PER_TRANSACTION)
      (ok amount)
      (err ERR_INVALID_INPUT)))

;; Validate principal
(define-private (validate-principal (user principal))
  (match (principal-destruct? user)
    success (ok user)
    error (err ERR_INVALID_INPUT)))

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
    (match (validate-string name)
      sanitized-name (ok (asserts! (map-insert Businesses caller { name: sanitized-name, active: true }) ERR_ALREADY_EXISTS))
      err-value err-value)))

;; Issue points to a user
(define-public (issue-points (user principal) (amount uint))
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? Businesses caller)) ERR_UNAUTHORIZED)
    (match (validate-principal user)
      valid-user
        (match (validate-amount amount)
          validated-amount 
            (let ((current-points (default-to u0 (map-get? UserPoints { user: valid-user, business: caller }))))
              (match (safe-add current-points validated-amount)
                new-points
                  (match (safe-add (default-to u0 (map-get? BusinessTotalPoints caller)) validated-amount)
                    new-total 
                      (begin
                        (map-set UserPoints { user: valid-user, business: caller } new-points)
                        (map-set BusinessTotalPoints caller new-total)
                        (ok new-points))
                    err-value err-value)
                err-value err-value))
          err-value err-value)
      err-value err-value)))

;; Redeem points
(define-public (redeem-points (business principal) (amount uint))
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? Businesses business)) ERR_NOT_FOUND)
    (match (validate-amount amount)
      validated-amount
        (let ((current-points (default-to u0 (map-get? UserPoints { user: caller, business: business }))))
          (asserts! (>= current-points validated-amount) ERR_INSUFFICIENT_BALANCE)
          (match (safe-subtract current-points validated-amount)
            new-points
              (match (safe-subtract (default-to u0 (map-get? BusinessTotalPoints business)) validated-amount)
                new-total 
                  (begin
                    (map-set UserPoints { user: caller, business: business } new-points)
                    (map-set BusinessTotalPoints business new-total)
                    (ok new-points))
                err-value err-value)
            err-value err-value))
      err-value err-value)))

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
