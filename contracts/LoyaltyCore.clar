;; LoyaltyCore.clar
;; Core contract for decentralized loyalty program

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))

;; Data maps
(define-map Businesses principal { name: (string-ascii 50), active: bool })
(define-map UserPoints { user: principal, business: principal } uint)
(define-map BusinessTotalPoints principal uint)

;; Public functions

;; Register a new business
(define-public (register-business (name (string-ascii 50)))
  (let ((caller tx-sender))
    (if (is-eq caller CONTRACT_OWNER)
        (if (map-insert Businesses caller { name: name, active: true })
            (ok true)
            (err ERR_ALREADY_EXISTS))
        (err ERR_UNAUTHORIZED))))

;; Issue points to a user
(define-public (issue-points (user principal) (amount uint))
  (let ((caller tx-sender))
    (if (is-business caller)
        (let ((current-points (default-to u0 (map-get? UserPoints { user: user, business: caller })))
              (new-points (+ current-points amount)))
          (map-set UserPoints { user: user, business: caller } new-points)
          (map-set BusinessTotalPoints caller (+ (default-to u0 (map-get? BusinessTotalPoints caller)) amount))
          (ok new-points))
        (err ERR_UNAUTHORIZED))))

;; Redeem points
(define-public (redeem-points (business principal) (amount uint))
  (let ((caller tx-sender)
        (current-points (default-to u0 (map-get? UserPoints { user: caller, business: business }))))
    (if (>= current-points amount)
        (let ((new-points (- current-points amount)))
          (map-set UserPoints { user: caller, business: business } new-points)
          (map-set BusinessTotalPoints business (- (default-to u0 (map-get? BusinessTotalPoints business)) amount))
          (ok new-points))
        (err ERR_INSUFFICIENT_BALANCE))))

;; Read-only functions

;; Check if an address is a registered business
(define-read-only (is-business (address principal))
  (default-to false (get active (map-get? Businesses address))))

;; Get user points for a specific business
(define-read-only (get-user-points (user principal) (business principal))
  (default-to u0 (map-get? UserPoints { user: user, business: business })))

;; Get total points issued by a business
(define-read-only (get-business-total-points (business principal))
  (default-to u0 (map-get? BusinessTotalPoints business)))

;; Get business details
(define-read-only (get-business-details (business principal))
  (map-get? Businesses business))
