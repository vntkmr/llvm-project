; REQUIRES: asserts

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -prefer-predicate-with-vp-intrinsics=without-active-vector-length-support \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=WITHOUT-AVL %s

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -prefer-predicate-with-vp-intrinsics=if-active-vector-length-support \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=IF-AVL %s

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -prefer-predicate-with-vp-intrinsics=force-active-vector-length-support \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=FORCE-AVL %s

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -prefer-predicate-with-vp-intrinsics=no-predication \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=NO-VP %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nofree norecurse nounwind uwtable
define dso_local void @foo(i32* noalias nocapture %a, i32* noalias nocapture readonly %b, i32* noalias nocapture readonly %c, i32 %N) local_unnamed_addr {
; WITHOUT-AVL: VPlan 'Initial VPlan for VF={4},UF>=1' {
; WITHOUT-AVL-NEXT: for.body:
; WITHOUT-AVL-NEXT:   WIDEN-INDUCTION %indvars.iv = phi 0, %indvars.iv.next
; WITHOUT-AVL-NEXT:   EMIT vp<%2> = icmp ule ir<%indvars.iv> vp<%0>
; WITHOUT-AVL-NEXT:   CLONE ir<%arrayidx> = getelementptr ir<%b>, ir<%indvars.iv>
; WITHOUT-AVL-NEXT:   EMIT vp<%4> = GENERATE-EXPLICIT-VECTOR-LENGTH
; WITHOUT-AVL-NEXT:   PREDICATED-WIDEN ir<%0> = load ir<%arrayidx>, vp<%2>, vp<%4>
; WITHOUT-AVL-NEXT:   CLONE ir<%arrayidx2> = getelementptr ir<%c>, ir<%indvars.iv>
; WITHOUT-AVL-NEXT:   PREDICATED-WIDEN ir<%1> = load ir<%arrayidx2>, vp<%2>, vp<%4>
; WITHOUT-AVL-NEXT:   PREDICATED-WIDEN ir<%add> = add ir<%1>, ir<%0>, vp<%2>, vp<%4>
; WITHOUT-AVL-NEXT:   CLONE ir<%arrayidx4> = getelementptr ir<%a>, ir<%indvars.iv>
; WITHOUT-AVL-NEXT:   PREDICATED-WIDEN store ir<%arrayidx4>, ir<%add>, vp<%2>, vp<%4>
; WITHOUT-AVL-NEXT: No successors
; WITHOUT-AVL-NEXT: }

; IF-AVL: VPlan 'Initial VPlan for VF={4},UF>=1' {
; IF-AVL-NEXT: for.body:
; IF-AVL-NEXT:   WIDEN-INDUCTION %indvars.iv = phi 0, %indvars.iv.next
; IF-AVL-NEXT:   EMIT vp<%2> = icmp ule ir<%indvars.iv> vp<%0>
; IF-AVL-NEXT:   CLONE ir<%arrayidx> = getelementptr ir<%b>, ir<%indvars.iv>
; IF-AVL-NEXT:   WIDEN ir<%0> = load ir<%arrayidx>, vp<%2>
; IF-AVL-NEXT:   CLONE ir<%arrayidx2> = getelementptr ir<%c>, ir<%indvars.iv>
; IF-AVL-NEXT:   WIDEN ir<%1> = load ir<%arrayidx2>, vp<%2>
; IF-AVL-NEXT:   WIDEN ir<%add> = add ir<%1>, ir<%0>
; IF-AVL-NEXT:   CLONE ir<%arrayidx4> = getelementptr ir<%a>, ir<%indvars.iv>
; IF-AVL-NEXT:   WIDEN store ir<%arrayidx4>, ir<%add>, vp<%2>
; IF-AVL-NEXT: No successors
; IF-AVL-NEXT: }

; FORCE-AVL: VPlan 'Initial VPlan for VF={4},UF>=1' {
; FORCE-AVL-NEXT: for.body:
; FORCE-AVL-NEXT:   WIDEN-INDUCTION %indvars.iv = phi 0, %indvars.iv.next
; FORCE-AVL-NEXT:   CLONE ir<%arrayidx> = getelementptr ir<%b>, ir<%indvars.iv>
; FORCE-AVL-NEXT:   EMIT vp<%2> = all true mask
; FORCE-AVL-NEXT:   EMIT vp<%3> = GENERATE-EXPLICIT-VECTOR-LENGTH
; FORCE-AVL-NEXT:   PREDICATED-WIDEN ir<%0> = load ir<%arrayidx>, vp<%2>, vp<%3>
; FORCE-AVL-NEXT:   CLONE ir<%arrayidx2> = getelementptr ir<%c>, ir<%indvars.iv>
; FORCE-AVL-NEXT:   PREDICATED-WIDEN ir<%1> = load ir<%arrayidx2>, vp<%2>, vp<%3>
; FORCE-AVL-NEXT:   PREDICATED-WIDEN ir<%add> = add ir<%1>, ir<%0>, vp<%2>, vp<%3>
; FORCE-AVL-NEXT:   CLONE ir<%arrayidx4> = getelementptr ir<%a>, ir<%indvars.iv>
; FORCE-AVL-NEXT:   PREDICATED-WIDEN store ir<%arrayidx4>, ir<%add>, vp<%2>, vp<%3>
; FORCE-AVL-NEXT: No successors
; FORCE-AVL-NEXT: }

; NO-VP: VPlan 'Initial VPlan for VF={4},UF>=1' {
; NO-VP-NEXT: for.body:
; NO-VP-NEXT:   WIDEN-INDUCTION %indvars.iv = phi 0, %indvars.iv.next
; NO-VP-NEXT:   EMIT vp<%2> = icmp ule ir<%indvars.iv> vp<%0>
; NO-VP-NEXT:   CLONE ir<%arrayidx> = getelementptr ir<%b>, ir<%indvars.iv>
; NO-VP-NEXT:   WIDEN ir<%0> = load ir<%arrayidx>, vp<%2>
; NO-VP-NEXT:   CLONE ir<%arrayidx2> = getelementptr ir<%c>, ir<%indvars.iv>
; NO-VP-NEXT:   WIDEN ir<%1> = load ir<%arrayidx2>, vp<%2>
; NO-VP-NEXT:   WIDEN ir<%add> = add ir<%1>, ir<%0>
; NO-VP-NEXT:   CLONE ir<%arrayidx4> = getelementptr ir<%a>, ir<%indvars.iv>
; NO-VP-NEXT:   WIDEN store ir<%arrayidx4>, ir<%add>, vp<%2>
; NO-VP-NEXT: No successors
; NO-VP-NEXT: }

entry:
  %cmp10 = icmp sgt i32 %N, 0
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %N to i64
  br label %for.body

for.cond.cleanup.loopexit:                        ; preds = %for.body
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  ret void

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %b, i64 %indvars.iv
  %0 = load i32, i32* %arrayidx, align 4
  %arrayidx2 = getelementptr inbounds i32, i32* %c, i64 %indvars.iv
  %1 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %1, %0
  %arrayidx4 = getelementptr inbounds i32, i32* %a, i64 %indvars.iv
  store i32 %add, i32* %arrayidx4, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond.not, label %for.cond.cleanup.loopexit, label %for.body
}
