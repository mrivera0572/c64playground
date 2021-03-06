;;; -*- mode: asm -*-
;;; Ripped from https://gist.github.com/visy/1f800697f2c1025c212fc72de0b41130
;;
;; Switch bank in VIC-II
;;
;; Args:
;;    bank: bank number to switch to. Valid values: 0-3.
;;
.macro SwitchVICBank bank
	;; The VIC-II chip can only access 16K bytes at a time. In order to
	;; have it access all of the 64K available, we have to tell it to look
	;; at one of four banks.
	;;
	;; This is controller by bits 0 and 1 in $dd00 (PORT A of CIA #2).
	;;
	;;  +------+-------+----------+-------------------------------------+
	;;  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
	;;  |      |       | LOCATION |                                     |
	;;  +------+-------+----------+-------------------------------------+
	;;  |  00  |   3   |   49152  | ($C000-$FFFF)*                      |
	;;  |  01  |   2   |   32768  | ($8000-$BFFF)                       |
	;;  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
	;;  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
	;;  +------+-------+----------+-------------------------------------+
	;;
	;; Set Data Direction for CIA #2, Port A to output
	;;
	lda	$dd02
	and	#%11111100	;; Mask the bits we're interested in.
	ora	#%00000011	;; Set bits 0 and 1.
	sta	$dd02
	;;
	;; Tell VIC-II to switch to bank
	;;
	lda	$dd00
	and	#%11111100
	ora	#(~bank)&%00000011
	sta	$dd00
	.endmacro

;;; Enter hires bitmap mode (a.k.a. standard bitmap mode)
	.macro SetHiresBitmapMode
	;; Clear extended color mode (bit 6) and set bitmap mode (bit 5)
	lda	$d011
	and	#%10111111
	ora	#%00100000
	sta	$d011
	;; Clear multi color mode (bit 4)
	lda $d016
	and #%11101111
	sta $d016
	.endmacro


;; Set location of bitmap.
;;
;; Args:
;;    address: Address relative to VIC-II bank address.
;;             Valid values: $0000 (bitmap at $0000-$1FFF)
;;                           $2000 (bitmap at $2000-$3FFF)
;;
.macro SetBitmapAddress address
	;;
	;; In standard bitmap mode the location of the bitmap area can
	;; be set to either BANK address + $0000 or BANK address + $2000
	;;
	;; By setting bit 3, we can configure which of the locations to use.
	;;
	lda	$d018
	.if address=0
        and	#%11110111
	.else
        ora	#%00001000
	.endif
	sta	$d018
.endmacro


;;
;; Switch location of screen memory.
;;
;; Args:
;;   address: Address relative to current VIC-II bank base address.
;;            Valid values: $0000-$3c00. Must be a multiple of $0400.
;;
.macro SetScreenMemory	address
    ;; 
    ;; The most significant nibble of $D018 selects where the screen is
    ;; located in the current VIC-II bank.
    ;;
    ;;  +------------+-----------------------------+
    ;;  |            |         LOCATION*           |
    ;;  |    BITS    +---------+-------------------+
    ;;  |            | DECIMAL |        HEX        |
    ;;  +------------+---------+-------------------+
    ;;  |  0000XXXX  |      0  |  $0000            |
    ;;  |  0001XXXX  |   1024  |  $0400 (DEFAULT)  |
    ;;  |  0010XXXX  |   2048  |  $0800            |
    ;;  |  0011XXXX  |   3072  |  $0C00            |
    ;;  |  0100XXXX  |   4096  |  $1000            |
    ;;  |  0101XXXX  |   5120  |  $1400            |
    ;;  |  0110XXXX  |   6144  |  $1800            |
    ;;  |  0111XXXX  |   7168  |  $1C00            |
    ;;  |  1000XXXX  |   8192  |  $2000            |
    ;;  |  1001XXXX  |   9216  |  $2400            |
    ;;  |  1010XXXX  |  10240  |  $2800            |
    ;;  |  1011XXXX  |  11264  |  $2C00            |
    ;;  |  1100XXXX  |  12288  |  $3000            |
    ;;  |  1101XXXX  |  13312  |  $3400            |
    ;;  |  1110XXXX  |  14336  |  $3800            |
    ;;  |  1111XXXX  |  15360  |  $3C00            |
    ;;  +------------+---------+-------------------+
    ;;
	lda	$d018
	and	#%00001111
	ora	#(address/$0400)<<4
	sta	$d018
.endmacro
