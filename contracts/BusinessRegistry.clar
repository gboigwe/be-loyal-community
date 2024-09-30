;; BusinessRegistry.clar
;; Contract for managing business registrations in the loyalty program

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_INPUT (err u103))
(define-constant MAX_CATEGORY_COUNT u50)

;; Data maps
(define-map Businesses 
  principal 
  { 
    name: (string-ascii 50), 
    description: (string-utf8 280), 
    category: (string-ascii 20),
    active: bool,
    registration-date: uint
  }
)

(define-map Categories (string-ascii 20) bool)

;; To keep track of all categories
(define-data-var CategoryCount uint u0)
(define-map CategoryList uint (string-ascii 20))

;; Private functions

;; Check if a category exists
(define-private (category-exists (category (string-ascii 20)))
  (default-to false (map-get? Categories category)))

;; Public functions

;; Register a new business
(define-public (register-business (name (string-ascii 50)) (description (string-utf8 280)) (category (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (and (> (len name) u0) (<= (len name) u50)) ERR_INVALID_INPUT)
    (asserts! (and (> (len description) u0) (<= (len description) u280)) ERR_INVALID_INPUT)
    (asserts! (and (> (len category) u0) (<= (len category) u20)) ERR_INVALID_INPUT)
    (asserts! (category-exists category) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? Businesses caller)) ERR_ALREADY_EXISTS)
    (ok (map-insert Businesses caller 
      { 
        name: name, 
        description: description, 
        category: category,
        active: true,
        registration-date: block-height
      }
    ))
  )
)

;; Update business details
(define-public (update-business (name (string-ascii 50)) (description (string-utf8 280)) (category (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (and (> (len name) u0) (<= (len name) u50)) ERR_INVALID_INPUT)
    (asserts! (and (> (len description) u0) (<= (len description) u280)) ERR_INVALID_INPUT)
    (asserts! (and (> (len category) u0) (<= (len category) u20)) ERR_INVALID_INPUT)
    (asserts! (category-exists category) ERR_INVALID_INPUT)
    (match (map-get? Businesses caller)
      business (ok (map-set Businesses caller 
        (merge business 
          { 
            name: name, 
            description: description, 
            category: category
          }
        )))
      ERR_NOT_FOUND
    )
  )
)

;; Deactivate a business
(define-public (deactivate-business)
  (let ((caller tx-sender))
    (match (map-get? Businesses caller)
      business (ok (map-set Businesses caller (merge business { active: false })))
      ERR_NOT_FOUND
    )
  )
)

;; Reactivate a business
(define-public (reactivate-business)
  (let ((caller tx-sender))
    (match (map-get? Businesses caller)
      business (ok (map-set Businesses caller (merge business { active: true })))
      ERR_NOT_FOUND
    )
  )
)

;; Add a new category (only contract owner)
(define-public (add-category (category (string-ascii 20)))
  (let ((caller tx-sender)
        (current-count (var-get CategoryCount)))
    (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (> (len category) u0) (<= (len category) u20)) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? Categories category)) ERR_ALREADY_EXISTS)
    (asserts! (< current-count MAX_CATEGORY_COUNT) ERR_INVALID_INPUT)
    (map-set Categories category true)
    (map-set CategoryList current-count category)
    (var-set CategoryCount (+ current-count u1))
    (ok true)
  )
)

;; Remove a category (only contract owner)
(define-public (remove-category (category (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? Categories category)) ERR_NOT_FOUND)
    (map-delete Categories category)
    (ok true)
  )
)

;; Read-only functions

;; Get business details
(define-read-only (get-business-details (business principal))
  (map-get? Businesses business))

;; Check if a business is active
(define-read-only (is-business-active (business principal))
  (default-to false (get active (map-get? Businesses business))))

;; Get all categories
(define-read-only (get-all-categories)
  (let ((category-count (var-get CategoryCount)))
    (map get-category-at-index (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9))))

;; Get category at index
(define-read-only (get-category-at-index (index uint))
  (default-to "" (map-get? CategoryList index)))

;; Check if a category exists
(define-read-only (is-valid-category (category (string-ascii 20)))
  (category-exists category))

;; Get category count
(define-read-only (get-category-count)
  (var-get CategoryCount))
