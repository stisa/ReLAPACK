** CHETRF_ROOK_REC2 computes a partial factorization of a complex Hermitian indefinite matrix using the bounded Bunch-Kaufman ("rook") diagonal pivoting method
*
* This routine is a minor modification of LAPACK's clahef_rook.
* It serves as an unblocked kernel in the recursive algorithms.
* The blocked BLAS Level 3 updates were removed and moved to the
* recursive algorithm.
      SUBROUTINE CHETRF_ROOK_REC2( UPLO, N, NB, KB, A, LDA, IPIV, W,
     $                             LDW, INFO )
      CHARACTER          UPLO
      INTEGER            INFO, KB, LDA, LDW, N, NB
      INTEGER            IPIV( * )
      COMPLEX            A( LDA, * ), W( LDW, * )
      REAL               ZERO, ONE
      PARAMETER          ( ZERO = 0.0E+0, ONE = 1.0E+0 )
      COMPLEX            CONE
      PARAMETER          ( CONE = ( 1.0E+0, 0.0E+0 ) )
      REAL               EIGHT, SEVTEN
      PARAMETER          ( EIGHT = 8.0E+0, SEVTEN = 17.0E+0 )
      LOGICAL            DONE
      INTEGER            IMAX, ITEMP, II, J, JJ, JMAX, JP1, JP2, K,
     $                   KK, KKW, KP, KSTEP, KW, P
      REAL               ABSAKK, ALPHA, COLMAX, STEMP, R1, ROWMAX, T,
     $                   SFMIN
      COMPLEX            D11, D21, D22, Z
      LOGICAL            LSAME
      INTEGER            ICAMAX
      REAL               SLAMCH
      EXTERNAL           LSAME, ICAMAX, SLAMCH
      EXTERNAL           CCOPY, CSSCAL, CGEMM, CGEMV, CLACGV, CSWAP
      INTRINSIC          ABS, CONJG, AIMAG, MAX, MIN, REAL, SQRT
      REAL               CABS1
      CABS1( Z ) = ABS( REAL( Z ) ) + ABS( AIMAG( Z ) )
      INFO = 0
      ALPHA = ( ONE+SQRT( SEVTEN ) ) / EIGHT
      SFMIN = SLAMCH( 'S' )
      IF( LSAME( UPLO, 'U' ) ) THEN
         K = N
   10    CONTINUE
         KW = NB + K - N
         IF( ( K.LE.N-NB+1 .AND. NB.LT.N ) .OR. K.LT.1 )
     $      GO TO 30
         KSTEP = 1
         P = K
         IF( K.GT.1 )
     $      CALL CCOPY( K-1, A( 1, K ), 1, W( 1, KW ), 1 )
         W( K, KW ) = REAL( A( K, K ) )
         IF( K.LT.N ) THEN
            CALL CGEMV( 'No transpose', K, N-K, -CONE, A( 1, K+1 ), LDA,
     $                  W( K, KW+1 ), LDW, CONE, W( 1, KW ), 1 )
            W( K, KW ) = REAL( W( K, KW ) )
         END IF
         ABSAKK = ABS( REAL( W( K, KW ) ) )
         IF( K.GT.1 ) THEN
            IMAX = ICAMAX( K-1, W( 1, KW ), 1 )
            COLMAX = CABS1( W( IMAX, KW ) )
         ELSE
            COLMAX = ZERO
         END IF
         IF( MAX( ABSAKK, COLMAX ).EQ.ZERO ) THEN
            IF( INFO.EQ.0 )
     $         INFO = K
            KP = K
            A( K, K ) = REAL( W( K, KW ) )
            IF( K.GT.1 )
     $         CALL CCOPY( K-1, W( 1, KW ), 1, A( 1, K ), 1 )
         ELSE
            IF( .NOT.( ABSAKK.LT.ALPHA*COLMAX ) ) THEN
               KP = K
            ELSE
               DONE = .FALSE.
   12          CONTINUE
                  IF( IMAX.GT.1 )
     $               CALL CCOPY( IMAX-1, A( 1, IMAX ), 1, W( 1, KW-1 ),
     $                           1 )
                  W( IMAX, KW-1 ) = REAL( A( IMAX, IMAX ) )
                  CALL CCOPY( K-IMAX, A( IMAX, IMAX+1 ), LDA,
     $                        W( IMAX+1, KW-1 ), 1 )
                  CALL CLACGV( K-IMAX, W( IMAX+1, KW-1 ), 1 )
                  IF( K.LT.N ) THEN
                     CALL CGEMV( 'No transpose', K, N-K, -CONE,
     $                           A( 1, K+1 ), LDA, W( IMAX, KW+1 ), LDW,
     $                           CONE, W( 1, KW-1 ), 1 )
                     W( IMAX, KW-1 ) = REAL( W( IMAX, KW-1 ) )
                  END IF
                  IF( IMAX.NE.K ) THEN
                     JMAX = IMAX + ICAMAX( K-IMAX, W( IMAX+1, KW-1 ),
     $                                     1 )
                     ROWMAX = CABS1( W( JMAX, KW-1 ) )
                  ELSE
                     ROWMAX = ZERO
                  END IF
                  IF( IMAX.GT.1 ) THEN
                     ITEMP = ICAMAX( IMAX-1, W( 1, KW-1 ), 1 )
                     STEMP = CABS1( W( ITEMP, KW-1 ) )
                     IF( STEMP.GT.ROWMAX ) THEN
                        ROWMAX = STEMP
                        JMAX = ITEMP
                     END IF
                  END IF
                  IF( .NOT.( ABS( REAL( W( IMAX,KW-1 ) ) )
     $                       .LT.ALPHA*ROWMAX ) ) THEN
                     KP = IMAX
                     CALL CCOPY( K, W( 1, KW-1 ), 1, W( 1, KW ), 1 )
                     DONE = .TRUE.
                  ELSE IF( ( P.EQ.JMAX ) .OR. ( ROWMAX.LE.COLMAX ) )
     $            THEN
                     KP = IMAX
                     KSTEP = 2
                     DONE = .TRUE.
                  ELSE
                     P = IMAX
                     COLMAX = ROWMAX
                     IMAX = JMAX
                     CALL CCOPY( K, W( 1, KW-1 ), 1, W( 1, KW ), 1 )
                  END IF
               IF( .NOT.DONE ) GOTO 12
            END IF
            KK = K - KSTEP + 1
            KKW = NB + KK - N
            IF( ( KSTEP.EQ.2 ) .AND. ( P.NE.K ) ) THEN
               A( P, P ) = REAL( A( K, K ) )
               CALL CCOPY( K-1-P, A( P+1, K ), 1, A( P, P+1 ),
     $                     LDA )
               CALL CLACGV( K-1-P, A( P, P+1 ), LDA )
               IF( P.GT.1 )
     $            CALL CCOPY( P-1, A( 1, K ), 1, A( 1, P ), 1 )
               IF( K.LT.N )
     $            CALL CSWAP( N-K, A( K, K+1 ), LDA, A( P, K+1 ),
     $                        LDA )
               CALL CSWAP( N-KK+1, W( K, KKW ), LDW, W( P, KKW ),
     $                     LDW )
            END IF
            IF( KP.NE.KK ) THEN
               A( KP, KP ) = REAL( A( KK, KK ) )
               CALL CCOPY( KK-1-KP, A( KP+1, KK ), 1, A( KP, KP+1 ),
     $                     LDA )
               CALL CLACGV( KK-1-KP, A( KP, KP+1 ), LDA )
               IF( KP.GT.1 )
     $            CALL CCOPY( KP-1, A( 1, KK ), 1, A( 1, KP ), 1 )
               IF( K.LT.N )
     $            CALL CSWAP( N-K, A( KK, K+1 ), LDA, A( KP, K+1 ),
     $                        LDA )
               CALL CSWAP( N-KK+1, W( KK, KKW ), LDW, W( KP, KKW ),
     $                     LDW )
            END IF
            IF( KSTEP.EQ.1 ) THEN
               CALL CCOPY( K, W( 1, KW ), 1, A( 1, K ), 1 )
               IF( K.GT.1 ) THEN
                  T = REAL( A( K, K ) )
                  IF( ABS( T ).GE.SFMIN ) THEN
                     R1 = ONE / T
                     CALL CSSCAL( K-1, R1, A( 1, K ), 1 )
                  ELSE
                     DO 14 II = 1, K-1
                        A( II, K ) = A( II, K ) / T
   14                CONTINUE
                  END IF
                  CALL CLACGV( K-1, W( 1, KW ), 1 )
               END IF
            ELSE
               IF( K.GT.2 ) THEN
                  D21 = W( K-1, KW )
                  D11 = W( K, KW ) / CONJG( D21 )
                  D22 = W( K-1, KW-1 ) / D21
                  T = ONE / ( REAL( D11*D22 )-ONE )
                  DO 20 J = 1, K - 2
                     A( J, K-1 ) = T*( ( D11*W( J, KW-1 )-W( J, KW ) ) /
     $                             D21 )
                     A( J, K ) = T*( ( D22*W( J, KW )-W( J, KW-1 ) ) /
     $                           CONJG( D21 ) )
   20             CONTINUE
               END IF
               A( K-1, K-1 ) = W( K-1, KW-1 )
               A( K-1, K ) = W( K-1, KW )
               A( K, K ) = W( K, KW )
               CALL CLACGV( K-1, W( 1, KW ), 1 )
               CALL CLACGV( K-2, W( 1, KW-1 ), 1 )
            END IF
         END IF
         IF( KSTEP.EQ.1 ) THEN
            IPIV( K ) = KP
         ELSE
            IPIV( K ) = -P
            IPIV( K-1 ) = -KP
         END IF
         K = K - KSTEP
         GO TO 10
   30    CONTINUE
         J = K + 1
   60    CONTINUE
            KSTEP = 1
            JP1 = 1
            JJ = J
            JP2 = IPIV( J )
            IF( JP2.LT.0 ) THEN
               JP2 = -JP2
               J = J + 1
               JP1 = -IPIV( J )
               KSTEP = 2
            END IF
            J = J + 1
            IF( JP2.NE.JJ .AND. J.LE.N )
     $         CALL CSWAP( N-J+1, A( JP2, J ), LDA, A( JJ, J ), LDA )
            JJ = JJ + 1
            IF( KSTEP.EQ.2 .AND. JP1.NE.JJ .AND. J.LE.N )
     $         CALL CSWAP( N-J+1, A( JP1, J ), LDA, A( JJ, J ), LDA )
         IF( J.LT.N )
     $      GO TO 60
         KB = N - K
      ELSE
         K = 1
   70    CONTINUE
         IF( ( K.GE.NB .AND. NB.LT.N ) .OR. K.GT.N )
     $      GO TO 90
         KSTEP = 1
         P = K
         W( K, K ) = REAL( A( K, K ) )
         IF( K.LT.N )
     $      CALL CCOPY( N-K, A( K+1, K ), 1, W( K+1, K ), 1 )
         IF( K.GT.1 ) THEN
            CALL CGEMV( 'No transpose', N-K+1, K-1, -CONE, A( K, 1 ),
     $                  LDA, W( K, 1 ), LDW, CONE, W( K, K ), 1 )
            W( K, K ) = REAL( W( K, K ) )
         END IF
         ABSAKK = ABS( REAL( W( K, K ) ) )
         IF( K.LT.N ) THEN
            IMAX = K + ICAMAX( N-K, W( K+1, K ), 1 )
            COLMAX = CABS1( W( IMAX, K ) )
         ELSE
            COLMAX = ZERO
         END IF
         IF( MAX( ABSAKK, COLMAX ).EQ.ZERO ) THEN
            IF( INFO.EQ.0 )
     $         INFO = K
            KP = K
            A( K, K ) = REAL( W( K, K ) )
            IF( K.LT.N )
     $         CALL CCOPY( N-K, W( K+1, K ), 1, A( K+1, K ), 1 )
         ELSE
            IF( .NOT.( ABSAKK.LT.ALPHA*COLMAX ) ) THEN
               KP = K
            ELSE
               DONE = .FALSE.
   72          CONTINUE
                  CALL CCOPY( IMAX-K, A( IMAX, K ), LDA, W( K, K+1 ), 1)
                  CALL CLACGV( IMAX-K, W( K, K+1 ), 1 )
                  W( IMAX, K+1 ) = REAL( A( IMAX, IMAX ) )
                  IF( IMAX.LT.N )
     $               CALL CCOPY( N-IMAX, A( IMAX+1, IMAX ), 1,
     $                           W( IMAX+1, K+1 ), 1 )
                  IF( K.GT.1 ) THEN
                     CALL CGEMV( 'No transpose', N-K+1, K-1, -CONE,
     $                            A( K, 1 ), LDA, W( IMAX, 1 ), LDW,
     $                            CONE, W( K, K+1 ), 1 )
                     W( IMAX, K+1 ) = REAL( W( IMAX, K+1 ) )
                  END IF
                  IF( IMAX.NE.K ) THEN
                     JMAX = K - 1 + ICAMAX( IMAX-K, W( K, K+1 ), 1 )
                     ROWMAX = CABS1( W( JMAX, K+1 ) )
                  ELSE
                     ROWMAX = ZERO
                  END IF
                  IF( IMAX.LT.N ) THEN
                     ITEMP = IMAX + ICAMAX( N-IMAX, W( IMAX+1, K+1 ), 1)
                     STEMP = CABS1( W( ITEMP, K+1 ) )
                     IF( STEMP.GT.ROWMAX ) THEN
                        ROWMAX = STEMP
                        JMAX = ITEMP
                     END IF
                  END IF
                  IF( .NOT.( ABS( REAL( W( IMAX,K+1 ) ) )
     $                       .LT.ALPHA*ROWMAX ) ) THEN
                     KP = IMAX
                     CALL CCOPY( N-K+1, W( K, K+1 ), 1, W( K, K ), 1 )
                     DONE = .TRUE.
                  ELSE IF( ( P.EQ.JMAX ) .OR. ( ROWMAX.LE.COLMAX ) )
     $            THEN
                     KP = IMAX
                     KSTEP = 2
                     DONE = .TRUE.
                  ELSE
                     P = IMAX
                     COLMAX = ROWMAX
                     IMAX = JMAX
                     CALL CCOPY( N-K+1, W( K, K+1 ), 1, W( K, K ), 1 )
                  END IF
               IF( .NOT.DONE ) GOTO 72
            END IF
            KK = K + KSTEP - 1
            IF( ( KSTEP.EQ.2 ) .AND. ( P.NE.K ) ) THEN
               A( P, P ) = REAL( A( K, K ) )
               CALL CCOPY( P-K-1, A( K+1, K ), 1, A( P, K+1 ), LDA )
               CALL CLACGV( P-K-1, A( P, K+1 ), LDA )
               IF( P.LT.N )
     $            CALL CCOPY( N-P, A( P+1, K ), 1, A( P+1, P ), 1 )
               IF( K.GT.1 )
     $            CALL CSWAP( K-1, A( K, 1 ), LDA, A( P, 1 ), LDA )
               CALL CSWAP( KK, W( K, 1 ), LDW, W( P, 1 ), LDW )
            END IF
            IF( KP.NE.KK ) THEN
               A( KP, KP ) = REAL( A( KK, KK ) )
               CALL CCOPY( KP-KK-1, A( KK+1, KK ), 1, A( KP, KK+1 ),
     $                     LDA )
               CALL CLACGV( KP-KK-1, A( KP, KK+1 ), LDA )
               IF( KP.LT.N )
     $            CALL CCOPY( N-KP, A( KP+1, KK ), 1, A( KP+1, KP ), 1 )
               IF( K.GT.1 )
     $            CALL CSWAP( K-1, A( KK, 1 ), LDA, A( KP, 1 ), LDA )
               CALL CSWAP( KK, W( KK, 1 ), LDW, W( KP, 1 ), LDW )
            END IF
            IF( KSTEP.EQ.1 ) THEN
               CALL CCOPY( N-K+1, W( K, K ), 1, A( K, K ), 1 )
               IF( K.LT.N ) THEN
                  T = REAL( A( K, K ) )
                  IF( ABS( T ).GE.SFMIN ) THEN
                     R1 = ONE / T
                     CALL CSSCAL( N-K, R1, A( K+1, K ), 1 )
                  ELSE
                     DO 74 II = K + 1, N
                        A( II, K ) = A( II, K ) / T
   74                CONTINUE
                  END IF
                  CALL CLACGV( N-K, W( K+1, K ), 1 )
               END IF
            ELSE
               IF( K.LT.N-1 ) THEN
                  D21 = W( K+1, K )
                  D11 = W( K+1, K+1 ) / D21
                  D22 = W( K, K ) / CONJG( D21 )
                  T = ONE / ( REAL( D11*D22 )-ONE )
                  DO 80 J = K + 2, N
                     A( J, K ) = T*( ( D11*W( J, K )-W( J, K+1 ) ) /
     $                           CONJG( D21 ) )
                     A( J, K+1 ) = T*( ( D22*W( J, K+1 )-W( J, K ) ) /
     $                             D21 )
   80             CONTINUE
               END IF
               A( K, K ) = W( K, K )
               A( K+1, K ) = W( K+1, K )
               A( K+1, K+1 ) = W( K+1, K+1 )
               CALL CLACGV( N-K, W( K+1, K ), 1 )
               CALL CLACGV( N-K-1, W( K+2, K+1 ), 1 )
            END IF
         END IF
         IF( KSTEP.EQ.1 ) THEN
            IPIV( K ) = KP
         ELSE
            IPIV( K ) = -P
            IPIV( K+1 ) = -KP
         END IF
         K = K + KSTEP
         GO TO 70
   90    CONTINUE
         J = K - 1
  120    CONTINUE
            KSTEP = 1
            JP1 = 1
            JJ = J
            JP2 = IPIV( J )
            IF( JP2.LT.0 ) THEN
               JP2 = -JP2
               J = J - 1
               JP1 = -IPIV( J )
               KSTEP = 2
            END IF
            J = J - 1
            IF( JP2.NE.JJ .AND. J.GE.1 )
     $         CALL CSWAP( J, A( JP2, 1 ), LDA, A( JJ, 1 ), LDA )
            JJ = JJ -1
            IF( KSTEP.EQ.2 .AND. JP1.NE.JJ .AND. J.GE.1 )
     $         CALL CSWAP( J, A( JP1, 1 ), LDA, A( JJ, 1 ), LDA )
         IF( J.GT.1 )
     $      GO TO 120
         KB = K - 1
      END IF
      RETURN
      END
