;; LoyaltyCore.clar
;; Core contract for decentralized loyalty program

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_INVALID_INPUT (err u104))

;; Data maps
(define-map Businesses principal { name: (string-ascii 50), active: bool })
(define-map UserPoints { user: principal, business: principal } uint)
(define-map BusinessTotalPoints principal uint)

;; Private functions

;; Validate business existence
(define-private (validate-business (business principal))
  (match (map-get? Businesses business)
    business-data (ok true)
    (err ERR_NOT_FOUND)))

;; Public functions

;; Register a new business
(define-public (register-business (name (string-ascii 50)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? Businesses caller)) ERR_ALREADY_EXISTS)
    (ok (asserts! (map-insert Businesses caller { name: name, active: true }) ERR_ALREADY_EXISTS))))

;; Issue points to a user
(define-public (issue-points (user principal) (amount uint))
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? Businesses caller)) ERR_UNAUTHORIZED)
    (let ((current-points (default-to u0 (map-get? UserPoints { user: user, business: caller })))
          (new-points (+ current-points amount)))
      (map-set UserPoints { user: user, business: caller } new-points)
      (map-set BusinessTotalPoints caller 
        (+ (default-to u0 (map-get? BusinessTotalPoints caller)) amount))
      (ok new-points))))

;; Redeem points
(define-public (redeem-points (business principal) (amount uint))
  (let ((caller tx-sender)
        (current-points (default-to u0 (map-get? UserPoints { user: caller, business: business }))))
    (asserts! (is-some (map-get? Businesses business)) ERR_NOT_FOUND)
    (asserts! (>= current-points amount) ERR_INSUFFICIENT_BALANCE)
    (let ((new-points (- current-points amount)))
      (map-set UserPoints { user: caller, business: business } new-points)
      (map-set BusinessTotalPoints business 
        (- (default-to u0 (map-get? BusinessTotalPoints business)) amount))
      (ok new-points))))

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
