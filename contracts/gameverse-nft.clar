;; title: GameVerse NFT Protocol
;; summary: A comprehensive protocol for managing a gaming metaverse with NFTs, player avatars, virtual assets, and cross-game interactions.
;; description: This protocol facilitates the creation and management of a gaming metaverse on the Stacks blockchain. 
;; It includes functionalities for minting and transferring NFTs, managing player avatars, tracking achievements, 
;; and distributing rewards across multiple game worlds.


;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GAME-ASSET (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-TRANSFER-FAILED (err u4))
(define-constant ERR-LEADERBOARD-FULL (err u5))
(define-constant ERR-ALREADY-REGISTERED (err u6))
(define-constant ERR-INVALID-REWARD (err u7))
(define-constant ERR-INVALID-INPUT (err u8))
(define-constant ERR-INVALID-SCORE (err u9))
(define-constant ERR-INVALID-FEE (err u10))
(define-constant ERR-INVALID-ENTRIES (err u11))
(define-constant ERR-PLAYER-NOT-FOUND (err u12))
(define-constant ERR-INVALID-AVATAR (err u13))
(define-constant ERR-WORLD-NOT-FOUND (err u14))
(define-constant ERR-INVALID-NAME (err u15))
(define-constant ERR-INVALID-DESCRIPTION (err u16))
(define-constant ERR-INVALID-RARITY (err u17))
(define-constant ERR-INVALID-POWER-LEVEL (err u18))
(define-constant ERR-INVALID-ATTRIBUTES (err u19))
(define-constant ERR-INVALID-WORLD-ACCESS (err u20))


;; Protocol Configuration

(define-data-var protocol-fee uint u10)
(define-data-var max-leaderboard-entries uint u50)
(define-data-var total-prize-pool uint u0)
(define-data-var total-assets uint u0)
(define-data-var total-avatars uint u0)
(define-data-var total-worlds uint u0)

;; Protocol Administrator Whitelist
(define-map protocol-admin-whitelist principal bool)

;; Input Validation Functions

(define-private (is-valid-name (name (string-ascii 50)))
  (and 
    (>= (len name) u1)
    (<= (len name) u50)
    (not (is-eq name ""))
  )
)

(define-private (is-valid-description (description (string-ascii 200)))
  (and 
    (>= (len description) u1)
    (<= (len description) u200)
    (not (is-eq description ""))
  )
)

(define-private (is-valid-rarity (rarity (string-ascii 20)))
  (or 
    (is-eq rarity "common")
    (is-eq rarity "uncommon")
    (is-eq rarity "rare")
    (is-eq rarity "epic")
    (is-eq rarity "legendary")
  )
)

(define-private (is-valid-power-level (power uint))
  (and (>= power u1) (<= power u1000))
)

(define-private (is-valid-attributes (attributes (list 10 (string-ascii 20))))
  (and 
    (>= (len attributes) u1)
    (<= (len attributes) u10)
  )
)

(define-private (is-valid-world-access (worlds (list 10 uint)))
  (and 
    (>= (len worlds) u1)
    (<= (len worlds) u10)
    (fold check-world-exists worlds true)
  )
)

(define-private (check-world-exists (world-id uint) (valid bool))
  (and valid (is-some (get-world-details world-id)))
)

;; NFT Definitions
(define-non-fungible-token gameverse-asset uint)
(define-non-fungible-token player-avatar uint)

;; Enhanced Asset Metadata Map
(define-map gameverse-asset-metadata 
  { token-id: uint }
  { 
    name: (string-ascii 50),
    description: (string-ascii 200),
    rarity: (string-ascii 20),
    power-level: uint,
    world-id: uint,
    attributes: (list 10 (string-ascii 20)),
    experience: uint,
    level: uint
  }
)

;; Player Avatar Map
(define-map avatar-metadata
  { avatar-id: uint }
  {
    name: (string-ascii 50),
    level: uint,
    experience: uint,
    achievements: (list 20 (string-ascii 50)),
    equipped-assets: (list 5 uint),
    world-access: (list 10 uint)
  })

;; Game Worlds
(define-map game-worlds
  { world-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    entry-requirement: uint,
    active-players: uint,
    total-rewards: uint
  }
)

;; Leaderboard System
(define-map leaderboard 
  { player: principal }
  { 
    score: uint, 
    games-played: uint,
    total-rewards: uint,
    avatar-id: uint,
    rank: uint,
    achievements: (list 20 (string-ascii 50))
  }
)

;; Utility Functions
(define-read-only (is-protocol-admin (sender principal))
  (default-to false (map-get? protocol-admin-whitelist sender))
)

(define-read-only (is-valid-principal (input principal))
  (and 
    (not (is-eq input tx-sender))
    (not (is-eq input (as-contract tx-sender)))
  )
)

(define-read-only (is-safe-principal (input principal))
  (and 
    (is-valid-principal input)
    (or 
      (is-protocol-admin input)
      (is-some (map-get? leaderboard { player: input }))
    )
  )
)

(define-read-only (get-world-details (world-id uint))
  (map-get? game-worlds { world-id: world-id })
)

(define-read-only (get-avatar-details (avatar-id uint))
  (map-get? avatar-metadata { avatar-id: avatar-id })
)

(define-read-only (get-top-players)
  (let 
    (
      (max-entries (var-get max-leaderboard-entries))
    )
    (list 
      tx-sender
    )
  )
)

;; Protocol Management
(define-public (initialize-protocol 
  (entry-fee uint) 
  (max-entries uint)
)
  (begin
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= entry-fee u1) (<= entry-fee u1000)) ERR-INVALID-FEE)
    (asserts! (and (>= max-entries u1) (<= max-entries u500)) ERR-INVALID-ENTRIES)
    
    (var-set protocol-fee entry-fee)
    (var-set max-leaderboard-entries max-entries)
    
    (ok true)
  )
)

;; ===================
;; Asset Management
;; ===================
(define-public (mint-gameverse-asset 
    (name (string-ascii 50))
    (description (string-ascii 200))
    (rarity (string-ascii 20))
    (power-level uint)
    (world-id uint)
    (attributes (list 10 (string-ascii 20)))
  )
  (let 
    ((token-id (+ (var-get total-assets) u1)))
    
    ;; Input validation
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
    (asserts! (is-valid-rarity rarity) ERR-INVALID-RARITY)
    (asserts! (is-valid-power-level power-level) ERR-INVALID-POWER-LEVEL)
    (asserts! (is-some (get-world-details world-id)) ERR-WORLD-NOT-FOUND)
    (asserts! (is-valid-attributes attributes) ERR-INVALID-ATTRIBUTES)
    
    (try! (nft-mint? gameverse-asset token-id tx-sender))
    
    (map-set gameverse-asset-metadata 
      { token-id: token-id }
      {
        name: name,
        description: description,
        rarity: rarity,
        power-level: power-level,
        world-id: world-id,
        attributes: attributes,
        experience: u0,
        level: u1
      }
    )
    
    (var-set total-assets token-id)
    (ok token-id)
  )
)

(define-public (transfer-game-asset 
  (token-id uint) 
  (recipient principal)
)
  (begin
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? gameverse-asset token-id) ERR-INVALID-GAME-ASSET))
      ERR-NOT-AUTHORIZED
    )
    
    (asserts! (is-valid-principal recipient) ERR-INVALID-INPUT)
    
    (nft-transfer? gameverse-asset token-id tx-sender recipient)
  )
)

;; Avatar System
(define-public (create-avatar
    (name (string-ascii 50))
    (world-access (list 10 uint))
  )
  (let
    ((avatar-id (+ (var-get total-avatars) u1)))
    
    ;; Input validation
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (is-valid-world-access world-access) ERR-INVALID-WORLD-ACCESS)
    (asserts! 
      (is-none (map-get? leaderboard { player: tx-sender }))
      ERR-ALREADY-REGISTERED
    )
    
    (try! (nft-mint? player-avatar avatar-id tx-sender))
    
    (map-set avatar-metadata
      { avatar-id: avatar-id }
      {
        name: name,
        level: u1,
        experience: u0,
        achievements: (list),
        equipped-assets: (list),
        world-access: world-access
      }
    )
    
    (map-set leaderboard
      { player: tx-sender }
      {
        score: u0,
        games-played: u0,
        total-rewards: u0,
        avatar-id: avatar-id,
        rank: u0,
        achievements: (list)
      }
    )
    
    (var-set total-avatars avatar-id)
    (ok avatar-id)
  )
)

(define-public (update-avatar-experience
    (avatar-id uint)
    (experience-gained uint)
  )
  (let
    ((current-metadata (unwrap! (get-avatar-details avatar-id) ERR-INVALID-AVATAR)))
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= experience-gained u0) ERR-INVALID-INPUT)
    
    (map-set avatar-metadata
      { avatar-id: avatar-id }
      (merge current-metadata
        {
          experience: (+ (get experience current-metadata) experience-gained),
          level: (+ (get level current-metadata) u1)
        }
      )
    )
    (ok true)
  )
)

;; Game World Management
(define-public (create-game-world 
    (name (string-ascii 50))
    (description (string-ascii 200))
    (entry-requirement uint)
  )
  (let
    ((world-id (+ (var-get total-worlds) u1)))
    
    ;; Input validation
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
    (asserts! (>= entry-requirement u0) ERR-INVALID-INPUT)
    
    (map-set game-worlds
      { world-id: world-id }
      {
        name: name,
        description: description,
        entry-requirement: entry-requirement,
        active-players: u0,
        total-rewards: u0
      }
    )
    
    (var-set total-worlds world-id)
    (ok world-id)
  )
)

;; Leaderboard Management
(define-public (update-player-score 
  (player principal) 
  (new-score uint)
)
  (let 
    (
      (current-stats (unwrap! 
        (map-get? leaderboard { player: player }) 
        ERR-PLAYER-NOT-FOUND
      ))
    )
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-principal player) ERR-INVALID-INPUT)
    (asserts! (and (>= new-score u0) (<= new-score u10000)) ERR-INVALID-SCORE)
    
    (map-set leaderboard 
      { player: player }
      (merge current-stats 
        {
          score: new-score,
          games-played: (+ (get games-played current-stats) u1)
        }
      )
    )
    
    (ok true)
  )
)