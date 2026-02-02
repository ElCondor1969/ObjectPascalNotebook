// Eric Grange
// https://github.com/EricGrange/LibCBLAS

unit LibCBLAS;

interface

{$MINENUMSIZE 4}

uses
   SysUtils;

type
   Tcblas_INDEX = LongInt;

   Tcblas_LAYOUT = (
      cblasRowMajor = 101,
      cblasColMajor = 102
   );
   Tcblas_TRANSPOSE = (
      cblasNoTrans = 111,
      cblasTrans = 112,
      cblasConjTrans = 113
   );
   Tcblas_UPLO = (
      cblasUpper = 121,
      cblasLower = 122
   );
   Tcblas_DIAG = (
      cblasNonUnit = 131,
      cblasUnit = 132
   );
   Tcblas_SIDE = (
      CblasLeft = 141,
      CblasRight = 142
   );

   Tcblas_ORDER = Tcblas_LAYOUT;

   TcblasProcedures = record

      openblas_set_num_threads : procedure(num_threads : LongInt); cdecl;
      openblas_get_num_threads : function : LongInt; cdecl;
      openblas_get_num_procs : function : LongInt; cdecl;
      openblas_get_config : function : PAnsiChar; cdecl;
      openblas_get_corename : function : PAnsiChar; cdecl;

      // BLAS

      sdsdot : function(n : LongInt; alpha : Single; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt) : Single; cdecl;
      dsdot : function(n : LongInt; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt) : Double; cdecl;
      // historical BLAS bug, sdor returns a double
      sdot : function(n : LongInt; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt) : Double; cdecl;
      ddot : function(n : LongInt; X : PDouble; incX : LongInt; Y : PDouble; incY : LongInt) : Double; cdecl;

      cdotu_sub : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt; dotu : Pointer); cdecl;
      cdotc_sub : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt; dotc : Pointer); cdecl;
      zdotu_sub : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt; dotu : Pointer); cdecl;
      zdotc_sub : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt; dotc : Pointer); cdecl;

      // historical BLAS bug, snrm2 returns a double
      snrm2 : function(n : LongInt; x : PSingle; incX : LongInt) : Double; cdecl;
      sasum : function(n : LongInt; x : PSingle; incX : LongInt) : Single; cdecl;
      dnrm2 : function(n : LongInt; X : PDouble; incX : LongInt) : Double; cdecl;
      dasum : function(n : LongInt; X : PDouble; incX : LongInt) : Double; cdecl;

      scnrm2 : function(n : LongInt; X : Pointer; incX : LongInt) : Single; cdecl;
      scasum : function(n : LongInt; X : Pointer; incX : LongInt) : Single; cdecl;
      dznrm2 : function(n : LongInt; X : Pointer; incX : LongInt) : Double; cdecl;
      dzasum : function(n : LongInt; X : Pointer; incX : LongInt) : Double; cdecl;

      isamax : function(n : LongInt; x : PSingle; incX : LongInt) : Tcblas_INDEX; cdecl;
      idamax : function(n : LongInt; X : PDouble; incX : LongInt) : Tcblas_INDEX; cdecl;
      icamax : function(n : LongInt; X : Pointer; incX : LongInt) : Tcblas_INDEX; cdecl;
      izamax : function(n : LongInt; X : Pointer; incX : LongInt) : Tcblas_INDEX; cdecl;

      sswap : procedure(n : LongInt; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt); cdecl;
      scopy : procedure(n : LongInt; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt); cdecl;
      saxpy : procedure(n : LongInt; alpha : Single; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt); cdecl;
      dswap : procedure(n : LongInt; X : PDouble; incX : LongInt; Y : PDouble; incY : LongInt); cdecl;
      dcopy : procedure(n : LongInt; X : PDouble; incX : LongInt; Y : PDouble; incY : LongInt); cdecl;
      daxpy : procedure(n : LongInt; alpha : Double; X : PDouble; incX : LongInt; Y : PDouble; incY : LongInt); cdecl;
      cswap : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt); cdecl;
      ccopy : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt); cdecl;
      caxpy : procedure(n : LongInt; alpha : Pointer; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt); cdecl;
      zswap : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt); cdecl;
      zcopy : procedure(n : LongInt; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt); cdecl;
      zaxpy : procedure(n : LongInt; alpha : Pointer; X : Pointer; incX : LongInt; Y : Pointer; incY : LongInt); cdecl;

      srotg : procedure(a : PSingle; b : PSingle; c : PSingle; s : PSingle); cdecl;
      srotmg : procedure(d1 : PSingle; d2 : PSingle; b1 : PSingle; b2 : Single; P : PSingle); cdecl;
      srot : procedure(n : LongInt; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt; c : Single; s : Single); cdecl;
      srotm : procedure(n : LongInt; x : PSingle; incX : LongInt; Y : PSingle; incY : LongInt; P : PSingle); cdecl;
      drotg : procedure(a : PDouble; b : PDouble; c : PDouble; s : PDouble); cdecl;
      drotmg : procedure(d1 : PDouble; d2 : PDouble; b1 : PDouble; b2 : Double; P : PDouble); cdecl;
      drot : procedure(n : LongInt; X : PDouble; incX : LongInt; Y : PDouble; incY : LongInt; c : Double; s : Double); cdecl;
      drotm : procedure(n : LongInt; X : PDouble; incX : LongInt; Y : PDouble; incY : LongInt; P : PDouble); cdecl;

      sscal : procedure(n : LongInt; alpha : Single; x : PSingle; incX : LongInt); cdecl;
      dscal : procedure(n : LongInt; alpha : Double; X : PDouble; incX : LongInt); cdecl;
      cscal : procedure(n : LongInt; alpha : Pointer; X : Pointer; incX : LongInt); cdecl;
      zscal : procedure(n : LongInt; alpha : Pointer; X : Pointer; incX : LongInt); cdecl;
      csscal : procedure(n : LongInt; alpha : Single; X : Pointer; incX : LongInt); cdecl;
      zdscal : procedure(n : LongInt; alpha : Double; X : Pointer; incX : LongInt); cdecl;

      sgemv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; alpha : Single;
                        a : PSingle; lda : LongInt; x : PSingle; incX : LongInt; beta : Single;
                        y : PSingle; incY : LongInt); cdecl;
      sgbmv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; kl : LongInt;
                        ku : LongInt; alpha : Single; a : PSingle; lda : LongInt; x : PSingle;
                        incX : LongInt; beta : Single; y : PSingle; incY : LongInt); cdecl;
      strmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : PSingle; lda : LongInt; x : PSingle; incX : LongInt); cdecl;
      stbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : PSingle; lda : LongInt; x : PSingle; incX : LongInt); cdecl;
      stpmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : PSingle; x : PSingle; incX : LongInt); cdecl;

      strsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : PSingle; lda : LongInt; x : PSingle; incX : LongInt); cdecl;
      stbsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : PSingle; lda : LongInt; x : PSingle; incX : LongInt); cdecl;
      stpsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : PSingle; x : PSingle; incX : LongInt); cdecl;
      dgemv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; alpha : Double;
                        a : PDouble; lda : LongInt; x : PDouble; incX : LongInt; beta : Double;
                        y : PDouble; incY : LongInt); cdecl;
      dgbmv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; kl : LongInt;
                        ku : LongInt; alpha : Double; a : PDouble; lda : LongInt; x : PDouble;
                        incX : LongInt; beta : Double; y : PDouble; incY : LongInt); cdecl;
      dtrmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : PDouble; lda : LongInt; x : PDouble; incX : LongInt); cdecl;
      dtbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : PDouble; lda : LongInt; x : PDouble; incX : LongInt); cdecl;
      dtpmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : PDouble; x : PDouble; incX : LongInt); cdecl;
      dtrsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : PDouble; x : PDouble; incX : LongInt); cdecl;
      dtbsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : PDouble; lda : LongInt; x : PDouble; incX : LongInt); cdecl;
      dtpsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : PDouble; x : PDouble; incX : LongInt); cdecl;
      cgemv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; alpha : Pointer;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt; beta : Pointer;
                        y : Pointer; incY : LongInt); cdecl;
      cgbmv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; kl : LongInt;
                        ku : LongInt; alpha : Pointer; a : Pointer; lda : LongInt; x : Pointer;
                        incX : LongInt; beta : Pointer; y : Pointer; incY : LongInt); cdecl;
      ctrmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ctbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ctpmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : Pointer; x : Pointer; incX : LongInt); cdecl;
      ctrsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ctbsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ctpsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : Pointer; x : Pointer; incX : LongInt); cdecl;

      zgemv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; alpha : Pointer;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt; beta : Pointer;
                        y : Pointer; incY : LongInt); cdecl;
      zgbmv : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; m : LongInt; n : LongInt; kl : LongInt;
                        ku : LongInt; alpha : Pointer; a : Pointer; lda : LongInt; x : Pointer;
                        incX : LongInt; beta : Pointer; y : Pointer; incY : LongInt); cdecl;
      ztrmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ztbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ztpmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        ap : Pointer; x : Pointer; incX : LongInt); cdecl;
      ztrsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ztbsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
                        k : LongInt; a : Pointer; lda : LongInt; x : Pointer; incX : LongInt); cdecl;
      ztpsv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG; n : LongInt;
              ap : Pointer; x : Pointer; incX : LongInt); cdecl;

      ssymv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; a : PSingle;
                        lda : LongInt; x : PSingle; incX : LongInt; beta : Single; y : PSingle;
                        incY : LongInt); cdecl;
      ssbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; k : LongInt; alpha : Single;
                        a : PSingle; lda : LongInt; x : PSingle; incX : LongInt; beta : Single;
                        y : PSingle; incY : LongInt); cdecl;
      sspmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; ap : PSingle;
                        x : PSingle; incX : LongInt; beta : Single; y : PSingle; incY : LongInt); cdecl;
      sger : procedure(order : Tcblas_ORDER; m : LongInt; n : LongInt; alpha : Single; x : PSingle;
                       incX : LongInt; y : PSingle; incY : LongInt; a : PSingle; lda : LongInt); cdecl;
      ssyr : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; x : PSingle;
                       incX : LongInt; a : PSingle; lda : LongInt); cdecl;
      sspr : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; x : PSingle;
                       incX : LongInt; ap : PSingle); cdecl;
      ssyr2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; x : PSingle;
                        incX : LongInt; y : PSingle; incY : LongInt; a : PSingle; lda : LongInt); cdecl;
      sspr2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; x : PSingle;
                        incX : LongInt; y : PSingle; incY : LongInt; a : PSingle); cdecl;

      dsymv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; a : PDouble;
                        lda : LongInt; x : PDouble; incX : LongInt; beta : Double; y : PDouble;
                        incY : LongInt); cdecl;
      dsbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; k : LongInt; alpha : Double;
                        a : PDouble; lda : LongInt; x : PDouble; incX : LongInt; beta : Double;
                        y : PDouble; incY : LongInt); cdecl;
      dspmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; ap : PDouble;
                        x : PDouble; incX : LongInt; beta : Double; y : PDouble; incY : LongInt); cdecl;
      dger : procedure(order : Tcblas_ORDER; m : LongInt; n : LongInt; alpha : Double; x : PDouble;
                       incX : LongInt; y : PDouble; incY : LongInt; a : PDouble; lda : LongInt); cdecl;
      dsyr : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; x : PDouble;
                       incX : LongInt; a : PDouble; lda : LongInt); cdecl;
      dspr : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; x : PDouble;
                       incX : LongInt; ap : PDouble); cdecl;
      dsyr2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; x : PDouble;
                        incX : LongInt; y : PDouble; incY : LongInt; a : PDouble; lda : LongInt); cdecl;
      dspr2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; x : PDouble;
                        incX : LongInt; y : PDouble; incY : LongInt; a : PDouble); cdecl;

      chemv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; a : Pointer;
                        lda : LongInt; x : Pointer; incX : LongInt; beta : Pointer; y : Pointer;
                        incY : LongInt); cdecl;
      chbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; k : LongInt; alpha : Pointer;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt; beta : Pointer;
                        y : Pointer; incY : LongInt); cdecl;
      chpmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; ap : Pointer;
                        x : Pointer; incX : LongInt; beta : Pointer; y : Pointer; incY : LongInt); cdecl;
      cgeru : procedure(order : Tcblas_ORDER; m : LongInt; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; a : Pointer; lda : LongInt); cdecl;
      cgerc : procedure(order : Tcblas_ORDER; m : LongInt; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; a : Pointer; lda : LongInt); cdecl;
      cher : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; x : Pointer;
                       incX : LongInt; a : Pointer; lda : LongInt); cdecl;
      chpr : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Single; x : Pointer;
                       incX : LongInt; a : Pointer); cdecl;
      cher2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; a : Pointer; lda : LongInt); cdecl;
      chpr2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; ap : Pointer); cdecl;

      zhemv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; a : Pointer;
                        lda : LongInt; x : Pointer; incX : LongInt; beta : Pointer; y : Pointer;
                        incY : LongInt); cdecl;
      zhbmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; k : LongInt; alpha : Pointer;
                        a : Pointer; lda : LongInt; x : Pointer; incX : LongInt; beta : Pointer;
                        y : Pointer; incY : LongInt); cdecl;
      zhpmv : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; ap : Pointer;
                        x : Pointer; incX : LongInt; beta : Pointer; y : Pointer; incY : LongInt); cdecl;
      zgeru : procedure(order : Tcblas_ORDER; m : LongInt; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; a : Pointer; lda : LongInt); cdecl;
      zgerc : procedure(order : Tcblas_ORDER; m : LongInt; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; a : Pointer; lda : LongInt); cdecl;
      zher : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; x : Pointer;
                       incX : LongInt; a : Pointer; lda : LongInt); cdecl;
      zhpr : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Double; x : Pointer;
                       incX : LongInt; a : Pointer); cdecl;
      zher2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; a : Pointer; lda : LongInt); cdecl;
      zhpr2 : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; n : LongInt; alpha : Pointer; x : Pointer;
                        incX : LongInt; y : Pointer; incY : LongInt; ap : Pointer); cdecl;

      sgemm : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; TransB : Tcblas_TRANSPOSE; m : LongInt; n : LongInt;
                        k : LongInt; alpha : Single; a : PSingle; lda : LongInt; B : PSingle;
                        ldb : LongInt; beta : Single; C : PSingle; ldc : LongInt); cdecl;
      ssymm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; m : LongInt; n : LongInt;
                        alpha : Single; a : PSingle; lda : LongInt; B : PSingle; ldb : LongInt;
                        beta : Single; C : PSingle; ldc : LongInt); cdecl;
      ssyrk : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                        alpha : Single; a : PSingle; lda : LongInt; beta : Single; C : PSingle;
                        ldc : LongInt); cdecl;
      ssyr2k : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                         alpha : Single; a : PSingle; lda : LongInt; B : PSingle; ldb : LongInt;
                         beta : Single; C : PSingle; ldc : LongInt); cdecl;
      strmm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
                        m : LongInt; n : LongInt; alpha : Single; a : PSingle; lda : LongInt;
                        B : PSingle; ldb : LongInt); cdecl;
      strsm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
                        m : LongInt; n : LongInt; alpha : Single; a : PSingle; lda : LongInt;
                        B : PSingle; ldb : LongInt); cdecl;

      dgemm : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; TransB : Tcblas_TRANSPOSE; m : LongInt; n : LongInt;
              k : LongInt; alpha : Double; a : PDouble; lda : LongInt; B : PDouble;
              ldb : LongInt; beta : Double; C : PDouble; ldc : LongInt); cdecl;
      dsymm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; m : LongInt; n : LongInt;
              alpha : Double; a : PDouble; lda : LongInt; B : PDouble; ldb : LongInt;
              beta : Double; C : PDouble; ldc : LongInt); cdecl;
      dsyrk : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
              alpha : Double; a : PDouble; lda : LongInt; beta : Double; C : PDouble;
              ldc : LongInt); cdecl;
      dsyr2k : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
              alpha : Double; a : PDouble; lda : LongInt; B : PDouble; ldb : LongInt;
              beta : Double; C : PDouble; ldc : LongInt); cdecl;
      dtrmm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
              m : LongInt; n : LongInt; alpha : Double; a : PDouble; lda : LongInt;
              B : PDouble; ldb : LongInt); cdecl;
      dtrsm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
              m : LongInt; n : LongInt; alpha : Double; a : PDouble; lda : LongInt;
              B : PDouble; ldb : LongInt); cdecl;

      cgemm : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; TransB : Tcblas_TRANSPOSE; m : LongInt; n : LongInt;
                        k : LongInt; alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer;
                        ldb : LongInt; beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      csymm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; m : LongInt; n : LongInt;
                        alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                        beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      csyrk : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                        alpha : Pointer; a : Pointer; lda : LongInt; beta : Pointer; C : Pointer;
                        ldc : LongInt); cdecl;
      csyr2k : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                         alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                         beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      ctrmm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
                        m : LongInt; n : LongInt; alpha : Pointer; a : Pointer; lda : LongInt;
                        B : Pointer; ldb : LongInt); cdecl;
      ctrsm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
                        m : LongInt; n : LongInt; alpha : Pointer; a : Pointer; lda : LongInt;
                        B : Pointer; ldb : LongInt); cdecl;

      zgemm : procedure(order : Tcblas_ORDER; transA : Tcblas_TRANSPOSE; TransB : Tcblas_TRANSPOSE; m : LongInt; n : LongInt;
                        k : LongInt; alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer;
                        ldb : LongInt; beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      zsymm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; m : LongInt; n : LongInt;
                        alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                        beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      zsyrk : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                        alpha : Pointer; a : Pointer; lda : LongInt; beta : Pointer; C : Pointer;
                        ldc : LongInt); cdecl;
      zsyr2k : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                         alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                         beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      ztrmm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
                        m : LongInt; n : LongInt; alpha : Pointer; a : Pointer; lda : LongInt;
                        B : Pointer; ldb : LongInt); cdecl;
      ztrsm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; transA : Tcblas_TRANSPOSE; Diag : Tcblas_DIAG;
                        m : LongInt; n : LongInt; alpha : Pointer; a : Pointer; lda : LongInt;
                        B : Pointer; ldb : LongInt); cdecl;

      chemm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; m : LongInt; n : LongInt;
                        alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                        beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      cherk : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                        alpha : Single; a : Pointer; lda : LongInt; beta : Single; C : Pointer;
                        ldc : LongInt); cdecl;
      cher2k : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                         alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                         beta : Single; C : Pointer; ldc : LongInt); cdecl;
      zhemm : procedure(order : Tcblas_ORDER; Side : Tcblas_SIDE; uplo : Tcblas_UPLO; m : LongInt; n : LongInt;
                        alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                        beta : Pointer; C : Pointer; ldc : LongInt); cdecl;
      zherk : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                        alpha : Double; a : Pointer; lda : LongInt; beta : Double; C : Pointer;
                        ldc : LongInt); cdecl;
      zher2k : procedure(order : Tcblas_ORDER; uplo : Tcblas_UPLO; Trans : Tcblas_TRANSPOSE; n : LongInt; k : LongInt;
                         alpha : Pointer; a : Pointer; lda : LongInt; B : Pointer; ldb : LongInt;
                         beta : Double; C : Pointer; ldc : LongInt); cdecl;

      // LAPACKE

      sgetrf : function (matrix_layout : Tcblas_ORDER; m, n : LongInt; a : Pointer;
                         lda : LongInt; ipiv : Pointer) : LongInt;
      sgetri : function(matrix_layout : Tcblas_ORDER; n : LongInt; a : Pointer;
                        lda : LongInt; ipiv : Pointer) : LongInt; cdecl

   end;

const
   cDefaultLibCBLASdll =
{$if defined(MSWINDOWS)}
  'libopenblas.dll'
{$elseif defined(LINUX)}
  'libopenblas.so'
{$elseif defined(MACOS)}
  'libopenblas.dylib'
{$else}
  'libopenblas.dll'
{$ifend}
  ;
var
   CBLAS : TcblasProcedures;
   CBLAS_available : Boolean;

procedure LoadLibCBLAS(const dllName : String = cDefaultLibCBLASdll);
procedure FreeLibCBLAS;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses 
  uUtility, uDynLibLoader;

var
   vLibraryHandle : TDynLibHandle;
   vRefCount : Integer;
   vLibraryName : String;

// LoadLibCBLAS
//
procedure LoadLibCBLAS(const dllName : String);

   function GetProc(const name : AnsiString) : Pointer;
   begin
      Result := GetDynProc(vLibraryHandle, PAnsiChar('cblas_' + name));
   end;

   function GetLapackeProc(const name : AnsiString) : Pointer;
   begin
      Result := GetDynProc(vLibraryHandle, PAnsiChar('LAPACKE_' + name));
   end;

begin
   Inc(vRefCount);
   if vRefCount > 1 then
     if (vLibraryName<>dllName) then
       RaiseException('LibCBLAS already loaded from a different DLL');

   vLibraryName := dllName;
   vLibraryHandle := LoadDynLib(dllName);
   if vLibraryHandle = 0 then
      RaiseLastOSError;

   cblas.openblas_set_num_threads := GetDynProc(vLibraryHandle, 'openblas_set_num_threads');
   cblas.openblas_get_num_threads := GetDynProc(vLibraryHandle, 'openblas_get_num_threads');
   cblas.openblas_get_num_procs := GetDynProc(vLibraryHandle, 'openblas_get_num_procs');
   cblas.openblas_get_config := GetDynProc(vLibraryHandle, 'openblas_get_config');
   cblas.openblas_get_corename := GetDynProc(vLibraryHandle, 'openblas_get_corename');

   cblas.sdsdot      := GetProc('sdsdot');
   cblas.dsdot       := GetProc('dsdot');
   cblas.sdot        := GetProc('sdot');
   cblas.ddot        := GetProc('ddot');
   cblas.cdotu_sub   := GetProc('cdotu_sub');
   cblas.cdotc_sub   := GetProc('cdotc_sub');
   cblas.zdotu_sub   := GetProc('zdotu_sub');
   cblas.zdotc_sub   := GetProc('zdotc_sub');
   cblas.snrm2       := GetProc('snrm2');
   cblas.sasum       := GetProc('sasum');
   cblas.dnrm2       := GetProc('dnrm2');
   cblas.dasum       := GetProc('dasum');
   cblas.scnrm2      := GetProc('scnrm2');
   cblas.scasum      := GetProc('scasum');
   cblas.dznrm2      := GetProc('dznrm2');
   cblas.dzasum      := GetProc('dzasum');
   cblas.isamax      := GetProc('isamax');
   cblas.idamax      := GetProc('idamax');
   cblas.icamax      := GetProc('icamax');
   cblas.izamax      := GetProc('izamax');
   cblas.sswap       := GetProc('sswap');
   cblas.scopy       := GetProc('scopy');
   cblas.saxpy       := GetProc('saxpy');
   cblas.dswap       := GetProc('dswap');
   cblas.dcopy       := GetProc('dcopy');
   cblas.daxpy       := GetProc('daxpy');
   cblas.cswap       := GetProc('cswap');
   cblas.ccopy       := GetProc('ccopy');
   cblas.caxpy       := GetProc('caxpy');
   cblas.zswap       := GetProc('zswap');
   cblas.zcopy       := GetProc('zcopy');
   cblas.zaxpy       := GetProc('zaxpy');
   cblas.srotg       := GetProc('srotg');
   cblas.srotmg      := GetProc('srotmg');
   cblas.srot        := GetProc('srot');
   cblas.srotm       := GetProc('srotm');
   cblas.drotg       := GetProc('drotg');
   cblas.drotmg      := GetProc('drotmg');
   cblas.drot        := GetProc('drot');
   cblas.drotm       := GetProc('drotm');
   cblas.sscal       := GetProc('sscal');
   cblas.dscal       := GetProc('dscal');
   cblas.cscal       := GetProc('cscal');
   cblas.zscal       := GetProc('zscal');
   cblas.csscal      := GetProc('csscal');
   cblas.zdscal      := GetProc('zdscal');
   cblas.sgemv       := GetProc('sgemv');
   cblas.sgbmv       := GetProc('sgbmv');
   cblas.strmv       := GetProc('strmv');
   cblas.stbmv       := GetProc('stbmv');
   cblas.stpmv       := GetProc('stpmv');
   cblas.strsv       := GetProc('strsv');
   cblas.stbsv       := GetProc('stbsv');
   cblas.stpsv       := GetProc('stpsv');
   cblas.dgbmv       := GetProc('dgbmv');
   cblas.dgemv       := GetProc('dgemv');
   cblas.dgbmv       := GetProc('dgbmv');
   cblas.dtrmv       := GetProc('dtrmv');
   cblas.dtbmv       := GetProc('dtbmv');
   cblas.dtpmv       := GetProc('dtpmv');
   cblas.dtrsv       := GetProc('dtrsv');
   cblas.dtbsv       := GetProc('dtbsv');
   cblas.dtpsv       := GetProc('dtpsv');
   cblas.cgemv       := GetProc('cgemv');
   cblas.cgbmv       := GetProc('cgbmv');
   cblas.ctrmv       := GetProc('ctrmv');
   cblas.ctbmv       := GetProc('ctbmv');
   cblas.ctpmv       := GetProc('ctpmv');
   cblas.ctrsv       := GetProc('ctrsv');
   cblas.ctbsv       := GetProc('ctbsv');
   cblas.ctpsv       := GetProc('ctpsv');
   cblas.zgemv       := GetProc('zgemv');
   cblas.zgbmv       := GetProc('zgbmv');
   cblas.ztrmv       := GetProc('ztrmv');
   cblas.ztbmv       := GetProc('ztbmv');
   cblas.ztpmv       := GetProc('ztpmv');
   cblas.ztrsv       := GetProc('ztrsv');
   cblas.ztbsv       := GetProc('ztbsv');
   cblas.ztpsv       := GetProc('ztpsv');
   cblas.ssymv       := GetProc('ssymv');
   cblas.ssbmv       := GetProc('ssbmv');
   cblas.sspmv       := GetProc('sspmv');
   cblas.sger        := GetProc('sger');
   cblas.ssyr        := GetProc('ssyr');
   cblas.sspr        := GetProc('sspr');
   cblas.ssyr2       := GetProc('ssyr2');
   cblas.sspr2       := GetProc('sspr2');
   cblas.dsymv       := GetProc('dsymv');
   cblas.dsbmv       := GetProc('dsbmv');
   cblas.dspmv       := GetProc('dspmv');
   cblas.dger        := GetProc('dger');
   cblas.dsyr        := GetProc('dsyr');
   cblas.dspr        := GetProc('dspr');
   cblas.dsyr2       := GetProc('dsyr2');
   cblas.dspr2       := GetProc('dspr2');
   cblas.chemv       := GetProc('chemv');
   cblas.chbmv       := GetProc('chbmv');
   cblas.chpmv       := GetProc('chpmv');
   cblas.cgeru       := GetProc('cgeru');
   cblas.cgerc       := GetProc('cgerc');
   cblas.cher        := GetProc('cher');
   cblas.chpr        := GetProc('chpr');
   cblas.cher2       := GetProc('cher2');
   cblas.chpr2       := GetProc('chpr2');
   cblas.zhemv       := GetProc('zhemv');
   cblas.zhbmv       := GetProc('zhbmv');
   cblas.zhpmv       := GetProc('zhpmv');
   cblas.zgeru       := GetProc('zgeru');
   cblas.zgerc       := GetProc('zgerc');
   cblas.zher        := GetProc('zher');
   cblas.zhpr        := GetProc('zhpr');
   cblas.zher2       := GetProc('zher2');
   cblas.zhpr2       := GetProc('zhpr2');
   cblas.sgemm       := GetProc('sgemm');
   cblas.ssymm       := GetProc('ssymm');
   cblas.ssyrk       := GetProc('ssyrk');
   cblas.ssyr2k      := GetProc('ssyr2k');
   cblas.strmm       := GetProc('strmm');
   cblas.strsm       := GetProc('strsm');
   cblas.dgemm       := GetProc('dgemm');
   cblas.dsymm       := GetProc('dsymm');
   cblas.dsyrk       := GetProc('dsyrk');
   cblas.dsyr2k      := GetProc('dsyr2k');
   cblas.dtrmm       := GetProc('dtrmm');
   cblas.dtrsm       := GetProc('dtrsm');
   cblas.cgemm       := GetProc('cgemm');
   cblas.csymm       := GetProc('csymm');
   cblas.csyrk       := GetProc('csyrk');
   cblas.csyr2k      := GetProc('csyr2k');
   cblas.ctrmm       := GetProc('ctrmm');
   cblas.ctrsm       := GetProc('ctrsm');
   cblas.zgemm       := GetProc('zgemm');
   cblas.zsymm       := GetProc('zsymm');
   cblas.zsyrk       := GetProc('zsyrk');
   cblas.zsyr2k      := GetProc('zsyr2k');
   cblas.ztrmm       := GetProc('ztrmm');
   cblas.ztrsm       := GetProc('ztrsm');
   cblas.chemm       := GetProc('chemm');
   cblas.cherk       := GetProc('cherk');
   cblas.cher2k      := GetProc('cher2k');
   cblas.zhemm       := GetProc('zhemm');
   cblas.zherk       := GetProc('zherk');
   cblas.zher2k      := GetProc('zher2k');

   cblas.sgetrf      := GetLapackeProc('sgetrf');
   cblas.sgetri      := GetLapackeProc('sgetri');

   CBLAS_available := True;
end;

// FreeLibCBLAS
//
procedure FreeLibCBLAS;
begin
   Dec(vRefCount);
   if vRefCount = 0 then begin
      if (vLibraryHandle = 0) then 
        Exit;
      FreeDynLib(vLibraryHandle);
      vLibraryHandle := 0;
      FillChar(cblas, SizeOf(cblas), 0);
      CBLAS_available := False;
   end;
end;

end.
