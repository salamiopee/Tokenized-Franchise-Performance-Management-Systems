;; Franchise Coordinator Verification Contract
;; Manages verification and authorization of franchise coordinators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Data structures
(define-map coordinators
  { coordinator: principal }
  {
    verified: bool,
    verification-date: uint,
    region: (string-ascii 50),
    status: (string-ascii 20)
  }
)

(define-map coordinator-permissions
  { coordinator: principal }
  {
    can-monitor: bool,
    can-audit: bool,
    can-train: bool,
    can-support: bool
  }
)

(define-data-var total-coordinators uint u0)

;; Public functions
(define-public (register-coordinator (coordinator principal) (region (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? coordinators { coordinator: coordinator })) ERR_ALREADY_EXISTS)

    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: false,
        verification-date: u0,
        region: region,
        status: "pending"
      }
    )

    (var-set total-coordinators (+ (var-get total-coordinators) u1))
    (ok true)
  )
)

(define-public (verify-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? coordinators { coordinator: coordinator })) ERR_NOT_FOUND)

    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: true,
        verification-date: block-height,
        region: (get region (unwrap-panic (map-get? coordinators { coordinator: coordinator }))),
        status: "verified"
      }
    )

    (map-set coordinator-permissions
      { coordinator: coordinator }
      {
        can-monitor: true,
        can-audit: true,
        can-train: true,
        can-support: true
      }
    )

    (ok true)
  )
)

(define-public (revoke-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? coordinators { coordinator: coordinator })) ERR_NOT_FOUND)

    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: false,
        verification-date: u0,
        region: (get region (unwrap-panic (map-get? coordinators { coordinator: coordinator }))),
        status: "revoked"
      }
    )

    (map-delete coordinator-permissions { coordinator: coordinator })
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-coordinator-info (coordinator principal))
  (map-get? coordinators { coordinator: coordinator })
)

(define-read-only (get-coordinator-permissions (coordinator principal))
  (map-get? coordinator-permissions { coordinator: coordinator })
)

(define-read-only (is-verified-coordinator (coordinator principal))
  (match (map-get? coordinators { coordinator: coordinator })
    coordinator-data (get verified coordinator-data)
    false
  )
)

(define-read-only (get-total-coordinators)
  (var-get total-coordinators)
)
