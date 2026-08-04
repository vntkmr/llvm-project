! Test lowering of conditional arguments (Fortran 2023 R1526-R1528)
! RUN: %flang_fc1 -emit-hlfir -o - %s 2>&1 | FileCheck %s

module m
  implicit none
  interface
    subroutine takes_int(x)
      integer, intent(in) :: x
    end subroutine
    subroutine takes_int_out(x)
      integer, intent(out) :: x
    end subroutine
    subroutine takes_int_inout(x)
      integer, intent(inout) :: x
    end subroutine
    subroutine takes_optional_int(x)
      integer, intent(in), optional :: x
    end subroutine
    subroutine takes_real(x)
      real, intent(in) :: x
    end subroutine
  end interface
end module

! Test simple conditional arg with INTENT(IN): two variable branches
! CHECK-LABEL: func.func @_QPtest_simple_intent_in(
subroutine test_simple_intent_in(flag, x, y)
  use m
  logical :: flag
  integer :: x, y

  call takes_int((flag ? x : y))
  ! CHECK: %[[COND:.*]] = fir.convert {{.*}} : (!fir.logical<4>) -> i1
  ! CHECK: %[[RESULT:.*]] = fir.if %[[COND]] -> (!fir.ref<i32>) {
  ! CHECK:   fir.result {{.*}} : !fir.ref<i32>
  ! CHECK: } else {
  ! CHECK:   fir.result {{.*}} : !fir.ref<i32>
  ! CHECK: }
end subroutine

! Test conditional arg with .NIL. and optional dummy
! CHECK-LABEL: func.func @_QPtest_nil_optional(
subroutine test_nil_optional(flag, x)
  use m
  logical :: flag
  integer :: x

  call takes_optional_int((flag ? x : .NIL.))
  ! CHECK: %[[COND:.*]] = fir.convert {{.*}} : (!fir.logical<4>) -> i1
  ! CHECK: %[[IF_RESULTS:.*]]:2 = fir.if %[[COND]] -> (!fir.ref<i32>, i1) {
  ! CHECK:   %[[TRUE:.*]] = arith.constant true
  ! CHECK:   fir.result {{.*}}, %[[TRUE]] : !fir.ref<i32>, i1
  ! CHECK: } else {
  ! CHECK:   %[[ABSENT:.*]] = fir.absent !fir.ref<i32>
  ! CHECK:   %[[FALSE:.*]] = arith.constant false
  ! CHECK:   fir.result %[[ABSENT]], %[[FALSE]] : !fir.ref<i32>, i1
  ! CHECK: }
end subroutine

! Test multi-branch conditional arg (3 branches: f1 ? x : f2 ? y : z)
! CHECK-LABEL: func.func @_QPtest_multi_branch(
subroutine test_multi_branch(f1, f2, x, y, z)
  use m
  logical :: f1, f2
  integer :: x, y, z

  call takes_int((f1 ? x : f2 ? y : z))
  ! CHECK: fir.if {{.*}} -> (!fir.ref<i32>) {
  ! CHECK:   fir.result {{.*}} : !fir.ref<i32>
  ! CHECK: } else {
  ! CHECK:   %[[INNER:.*]] = fir.if {{.*}} -> (!fir.ref<i32>) {
  ! CHECK:     fir.result {{.*}} : !fir.ref<i32>
  ! CHECK:   } else {
  ! CHECK:     fir.result {{.*}} : !fir.ref<i32>
  ! CHECK:   }
  ! CHECK:   fir.result %[[INNER]] : !fir.ref<i32>
  ! CHECK: }
end subroutine

! Test conditional arg with variable and INTENT(INOUT)
! CHECK-LABEL: func.func @_QPtest_intent_inout(
subroutine test_intent_inout(flag, x, y)
  use m
  logical :: flag
  integer :: x, y

  call takes_int_inout((flag ? x : y))
  ! CHECK: %[[COND:.*]] = fir.convert {{.*}} : (!fir.logical<4>) -> i1
  ! CHECK: %[[RESULT:.*]] = fir.if %[[COND]] -> (!fir.ref<i32>) {
  ! CHECK:   fir.result {{.*}} : !fir.ref<i32>
  ! CHECK: } else {
  ! CHECK:   fir.result {{.*}} : !fir.ref<i32>
  ! CHECK: }
end subroutine
