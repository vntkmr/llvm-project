! RUN: %flang_fc1 -fdebug-unparse-no-sema %s 2>&1 | FileCheck %s
! RUN: %flang_fc1 -fdebug-dump-parse-tree-no-sema %s 2>&1 | FileCheck %s -check-prefix=TREE

! Test parsing of conditional arguments (F2023:R1526-R1528)

subroutine test_conditional_arg
  implicit none
  integer :: x, a, b, c
  integer :: arr(5)
  real :: r1, r2
  logical :: flag, flag2

  ! Test 1: Simple two-branch conditional arg
  ! CHECK: CALL sub(( x>0 ? a : b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE-NEXT: Scalar -> Logical -> Expr -> GT
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub((x > 0 ? a : b))

  ! Test 2: Multi-branch conditional arg
  ! CHECK: CALL sub(( x>10 ? a : x>5 ? b : c ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'c'
  call sub((x > 10 ? a : x > 5 ? b : c))

  ! Test 3: .NIL. in else position (absent optional)
  ! CHECK: CALL sub(( flag ? a : .NIL. ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Nil
  call sub((flag ? a : .NIL.))

  ! Test 4: .NIL. in middle branch
  ! CHECK: CALL sub(( flag ? .NIL. : flag2 ? a : .NIL. ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Nil
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE: Consequent -> Nil
  call sub((flag ? .NIL. : flag2 ? a : .NIL.))

  ! Test 5: Keyword argument with conditional arg
  ! CHECK: CALL sub(arg=( flag ? a : b ))
  ! TREE: ActualArgSpec
  ! TREE-NEXT: Keyword -> Name = 'arg'
  ! TREE-NEXT: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub(arg = (flag ? a : b))

  ! Test 6: Multiple arguments, one conditional
  ! CHECK: CALL sub(arg1=a, arg2=( flag ? b : c ))
  ! TREE: ActualArg -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'c'
  call sub(arg1 = a, arg2 = (flag ? b : c))

  ! Test 7: Expression consequent-args
  ! CHECK: CALL sub(( x>0 ? a+1 : b*2 ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Add
  ! TREE: Consequent -> Expr -> Multiply
  call sub((x > 0 ? a+1 : b*2))

  ! Test 8: Real variable consequent-args
  ! CHECK: CALL sub(( r1>0.0 ? r1 : r2 ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Scalar -> Logical -> Expr -> GT
  ! TREE: RealLiteralConstant
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'r1'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'r2'
  call sub((r1 > 0.0 ? r1 : r2))

  ! Test 9: Logical condition with .AND.
  ! CHECK: CALL sub(( x>0.AND.flag ? a : b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE-NEXT: Scalar -> Logical -> Expr -> AND
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub((x > 0 .and. flag ? a : b))

  ! Test 10: Logical condition with .NOT.
  ! CHECK: CALL sub(( .NOT.flag ? a : b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE-NEXT: Scalar -> Logical -> Expr -> NOT
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub((.not. flag ? a : b))

  ! Test 11: Logical condition with .OR.
  ! CHECK: CALL sub(( flag.OR.flag2 ? a : b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE-NEXT: Scalar -> Logical -> Expr -> OR
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub((flag .or. flag2 ? a : b))

  ! Test 12: Four-branch conditional arg
  ! CHECK: CALL sub(( x>30 ? a : x>20 ? b : x>10 ? c : x ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'c'
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'x'
  call sub((x > 30 ? a : x > 20 ? b : x > 10 ? c : x))

  ! Test 13: Array element consequent-args (parsed as FunctionReference pre-sema)
  ! CHECK: CALL sub(( x>0 ? arr(1) : arr(2) ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> FunctionReference -> Call
  ! TREE-NEXT: ProcedureDesignator -> Name = 'arr'
  ! TREE: Consequent -> Expr -> FunctionReference -> Call
  ! TREE-NEXT: ProcedureDesignator -> Name = 'arr'
  call sub((x > 0 ? arr(1) : arr(2)))

  ! Test 14: Array element with .NIL.
  ! CHECK: CALL sub(( flag ? arr(3) : .NIL. ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> FunctionReference -> Call
  ! TREE: Consequent -> Nil
  call sub((flag ? arr(3) : .NIL.))

  ! Test 15: Multiple conditional args in one call
  ! CHECK: CALL sub(( flag ? a : b ), ( flag2 ? c : x ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'x'
  call sub((flag ? a : b), (flag2 ? c : x))

  ! Test 16: Two keyword conditional args
  ! CHECK: CALL sub(p=( flag ? a : b ), q=( x>0 ? c : x ))
  ! TREE: Keyword -> Name = 'p'
  ! TREE-NEXT: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  ! TREE: Keyword -> Name = 'q'
  ! TREE-NEXT: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'c'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'x'
  call sub(p = (flag ? a : b), q = (x > 0 ? c : x))

  ! Test 17: Conditional arg with complex condition (comparison chain)
  ! CHECK: CALL sub(( x>5.AND.x<20 ? a : b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE-NEXT: Scalar -> Logical -> Expr -> AND
  ! TREE-NEXT: Expr -> GT
  ! TREE: Expr -> LT
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub((x > 5 .and. x < 20 ? a : b))

  ! Test 18: Consequent that is a parenthesized expression
  ! CHECK: CALL sub(( x>0 ? (a+b) : (b-c) ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Parentheses -> Expr -> Add
  ! TREE: Consequent -> Expr -> Parentheses -> Expr -> Subtract
  call sub((x > 0 ? (a+b) : (b-c)))

  ! Test 19: .NIL. only in middle of three branches
  ! CHECK: CALL sub(( flag ? .NIL. : flag2 ? a : b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Nil
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  call sub((flag ? .NIL. : flag2 ? a : b))

  ! Test 20: All-NIL except one branch
  ! CHECK: CALL sub(( flag ? .NIL. : flag2 ? .NIL. : a ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Nil
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Nil
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  call sub((flag ? .NIL. : flag2 ? .NIL. : a))

end subroutine

! Test conditional arg in a function reference context
subroutine test_func_ref
  implicit none
  integer :: x, a, b, result
  logical :: flag

  ! Test 21: Conditional arg passed to a function
  ! CHECK: result = func(( flag ? a : b ))
  ! TREE: FunctionReference -> Call
  ! TREE-NEXT: ProcedureDesignator -> Name = 'func'
  ! TREE-NEXT: ActualArgSpec
  ! TREE-NEXT: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  result = func((flag ? a : b))

  ! Test 22: Conditional arg as one of multiple function args
  ! CHECK: result = func(a, ( flag ? b : x ))
  ! TREE: ActualArg -> Expr -> Designator -> DataRef -> Name = 'a'
  ! TREE: ActualArg -> ConditionalArg
  ! TREE-NEXT: Branch
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'b'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'x'
  result = func(a, (flag ? b : x))

end subroutine

! Test conditional arg with various kinds
subroutine test_kinds
  implicit none
  integer(kind=4) :: i4a, i4b
  integer(kind=8) :: i8a, i8b
  real(kind=4)    :: r4a, r4b
  real(kind=8)    :: r8a, r8b
  logical         :: cond

  ! Test 23: Integer kind=4 consequent-args
  ! CHECK: CALL sub(( cond ? i4a : i4b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'i4a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'i4b'
  call sub((cond ? i4a : i4b))

  ! Test 24: Integer kind=8 consequent-args
  ! CHECK: CALL sub(( cond ? i8a : i8b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'i8a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'i8b'
  call sub((cond ? i8a : i8b))

  ! Test 25: Real kind=4 consequent-args
  ! CHECK: CALL sub(( cond ? r4a : r4b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'r4a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'r4b'
  call sub((cond ? r4a : r4b))

  ! Test 26: Real kind=8 consequent-args
  ! CHECK: CALL sub(( cond ? r8a : r8b ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 'r8a'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 'r8b'
  call sub((cond ? r8a : r8b))

end subroutine

! Test conditional arg with character variables
subroutine test_character
  implicit none
  character(len=10) :: s1, s2
  logical :: flag

  ! Test 27: Character variable consequent-args
  ! CHECK: CALL sub(( flag ? s1 : s2 ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 's1'
  ! TREE-NEXT: Consequent -> Expr -> Designator -> DataRef -> Name = 's2'
  call sub((flag ? s1 : s2))

  ! Test 28: Character variable with .NIL.
  ! CHECK: CALL sub(( flag ? s1 : .NIL. ))
  ! TREE: ActualArg -> ConditionalArg
  ! TREE: Consequent -> Expr -> Designator -> DataRef -> Name = 's1'
  ! TREE-NEXT: Consequent -> Nil
  call sub((flag ? s1 : .NIL.))

end subroutine
