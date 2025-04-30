;; standards-compliance.clar
;; This contract records adherence to sustainability criteria

(define-data-var admin principal tx-sender)

;; Define sustainability standards
(define-map sustainability-standards
  uint
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    created-at: uint
  }
)

;; Map to track supplier compliance with standards
(define-map supplier-compliance
  {supplier: principal, standard-id: uint}
  {
    compliant: bool,
    verification-date: uint,
    expiration-date: uint,
    verifier: principal
  }
)

;; Counter for standard IDs
(define-data-var standard-id-counter uint u1)

;; Add a new sustainability standard
(define-public (add-standard (name (string-utf8 100)) (description (string-utf8 500)))
  (let ((caller tx-sender)
        (current-id (var-get standard-id-counter)))
    (asserts! (is-eq caller (var-get admin)) (err u403))
    (map-insert sustainability-standards current-id
                {
                  name: name,
                  description: description,
                  created-at: block-height
                })
    (var-set standard-id-counter (+ current-id u1))
    (ok current-id)
  )
)

;; Record compliance for a supplier
(define-public (record-compliance
                (supplier principal)
                (standard-id uint)
                (is-compliant bool)
                (expiration-blocks uint))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403))
    (asserts! (is-some (map-get? sustainability-standards standard-id)) (err u404))

    (map-set supplier-compliance
             {supplier: supplier, standard-id: standard-id}
             {
               compliant: is-compliant,
               verification-date: block-height,
               expiration-date: (+ block-height expiration-blocks),
               verifier: caller
             })
    (ok true)
  )
)

;; Check if a supplier is compliant with a standard
(define-read-only (check-compliance (supplier principal) (standard-id uint))
  (match (map-get? supplier-compliance {supplier: supplier, standard-id: standard-id})
    compliance-data (and
                      (get compliant compliance-data)
                      (< block-height (get expiration-date compliance-data)))
    false
  )
)

;; Get standard details
(define-read-only (get-standard (standard-id uint))
  (map-get? sustainability-standards standard-id)
)

;; Get compliance details
(define-read-only (get-compliance-details (supplier principal) (standard-id uint))
  (map-get? supplier-compliance {supplier: supplier, standard-id: standard-id})
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
