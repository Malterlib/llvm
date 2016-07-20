; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

define i64 @test_sext_zext(i16 %A) {
; CHECK-LABEL: @test_sext_zext(
; CHECK-NEXT:    [[C2:%.*]] = zext i16 %A to i64
; CHECK-NEXT:    ret i64 [[C2]]
;
  %c1 = zext i16 %A to i32
  %c2 = sext i32 %c1 to i64
  ret i64 %c2
}

define <2 x i64> @test2(<2 x i1> %A) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    [[TMP1:%.*]] = zext <2 x i1> %A to <2 x i64>
; CHECK-NEXT:    [[ZEXT:%.*]] = xor <2 x i64> [[TMP1]], <i64 1, i64 1>
; CHECK-NEXT:    ret <2 x i64> [[ZEXT]]
;
  %xor = xor <2 x i1> %A, <i1 true, i1 true>
  %zext = zext <2 x i1> %xor to <2 x i64>
  ret <2 x i64> %zext
}

define <2 x i64> @test3(<2 x i64> %A) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[AND:%.*]] = and <2 x i64> %A, <i64 23, i64 42>
; CHECK-NEXT:    ret <2 x i64> [[AND]]
;
  %trunc = trunc <2 x i64> %A to <2 x i32>
  %and = and <2 x i32> %trunc, <i32 23, i32 42>
  %zext = zext <2 x i32> %and to <2 x i64>
  ret <2 x i64> %zext
}

define <2 x i64> @test4(<2 x i64> %A) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[TMP1:%.*]] = xor <2 x i64> %A, <i64 4294967295, i64 4294967295>
; CHECK-NEXT:    [[XOR:%.*]] = and <2 x i64> [[TMP1]], <i64 23, i64 42>
; CHECK-NEXT:    ret <2 x i64> [[XOR]]
;
  %trunc = trunc <2 x i64> %A to <2 x i32>
  %and = and <2 x i32> %trunc, <i32 23, i32 42>
  %xor = xor <2 x i32> %and, <i32 23, i32 42>
  %zext = zext <2 x i32> %xor to <2 x i64>
  ret <2 x i64> %zext
}

; FIXME: If the xor was done in the smaller type, the back-to-back zexts would get combined.

define i64 @fold_xor_zext_sandwich(i1 %a) {
; CHECK-LABEL: @fold_xor_zext_sandwich(
; CHECK-NEXT:    [[ZEXT1:%.*]] = zext i1 %a to i32
; CHECK-NEXT:    [[XOR:%.*]] = xor i32 [[ZEXT1]], 1
; CHECK-NEXT:    [[ZEXT2:%.*]] = zext i32 [[XOR]] to i64
; CHECK-NEXT:    ret i64 [[ZEXT2]]
;
  %zext1 = zext i1 %a to i32
  %xor = xor i32 %zext1, 1
  %zext2 = zext i32 %xor to i64
  ret i64 %zext2
}

define <2 x i64> @fold_xor_zext_sandwich_vec(<2 x i1> %a) {
; CHECK-LABEL: @fold_xor_zext_sandwich_vec(
; CHECK-NEXT:    [[ZEXT1:%.*]] = zext <2 x i1> %a to <2 x i64>
; CHECK-NEXT:    [[XOR:%.*]] = xor <2 x i64> [[ZEXT1]], <i64 1, i64 1>
; CHECK-NEXT:    ret <2 x i64> [[XOR]]
;
  %zext1 = zext <2 x i1> %a to <2 x i32>
  %xor = xor <2 x i32> %zext1, <i32 1, i32 1>
  %zext2 = zext <2 x i32> %xor to <2 x i64>
  ret <2 x i64> %zext2
}

; Assert that zexts in logic(zext(icmp), zext(icmp)) can be folded
; CHECK-LABEL: @fold_logic_zext_icmp(
; CHECK-NEXT:    [[ICMP1:%.*]] = icmp sgt i64 %a, %b
; CHECK-NEXT:    [[ICMP2:%.*]] = icmp slt i64 %a, %c
; CHECK-NEXT:    [[AND:%.*]] = and i1 [[ICMP1]], [[ICMP2]]
; CHECK-NEXT:    [[ZEXT:%.*]] = zext i1 [[AND]] to i8
; CHECK-NEXT:    ret i8 [[ZEXT]]
define i8 @fold_logic_zext_icmp(i64 %a, i64 %b, i64 %c) {
  %1 = icmp sgt i64 %a, %b
  %2 = zext i1 %1 to i8
  %3 = icmp slt i64 %a, %c
  %4 = zext i1 %3 to i8
  %5 = and i8 %2, %4
  ret i8 %5
}

; Assert that zexts in logic(zext(icmp), zext(icmp)) are also folded accross
; nested logical operators.
; CHECK-LABEL: @fold_nested_logic_zext_icmp(
; CHECK-NEXT:    [[ICMP1:%.*]] = icmp sgt i64 %a, %b
; CHECK-NEXT:    [[ICMP2:%.*]] = icmp slt i64 %a, %c
; CHECK-NEXT:    [[AND:%.*]] = and i1 [[ICMP1]], [[ICMP2]]
; CHECK-NEXT:    [[ICMP3:%.*]] = icmp eq i64 %a, %d
; CHECK-NEXT:    [[OR:%.*]] = or i1 [[AND]], [[ICMP3]]
; CHECK-NEXT:    [[ZEXT:%.*]] = zext i1 [[OR]] to i8
; CHECK-NEXT:    ret i8 [[ZEXT]]
define i8 @fold_nested_logic_zext_icmp(i64 %a, i64 %b, i64 %c, i64 %d) {
  %1 = icmp sgt i64 %a, %b
  %2 = zext i1 %1 to i8
  %3 = icmp slt i64 %a, %c
  %4 = zext i1 %3 to i8
  %5 = and i8 %2, %4
  %6 = icmp eq i64 %a, %d
  %7 = zext i1 %6 to i8
  %8 = or i8 %5, %7
  ret i8 %8
}

