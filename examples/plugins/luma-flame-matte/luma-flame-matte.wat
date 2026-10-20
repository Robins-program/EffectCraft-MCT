;; Original work, MIT OR Apache-2.0. API v1, no imports, premultiplied RGBA.
;; Allocator reserves the first page for the manifest and caps memory at 64 MiB.
(module
 (memory (export "memory") 2 1024)
 (data (i32.const 16)
  "{\"api\":1,\"id\":\"org.mct.luma-flame-matte\","
  "\"name\":\"Luma Flame Matte\","
  "\"category\":\"MCT Trials\","
  "\"version\":\"0.1.0\","
  "\"author\":\"MCT contributors\","
  "\"description\":\"Maps source luminance to a warm premultiplied flame and a soft alpha matte; preserves source coverage.\","
  "\"params\":["
  "{\"id\":\"threshold\",\"name\":\"Threshold\",\"type\":\"slider\",\"default\":0.4,\"min\":0,\"max\":1}"
  ",{\"id\":\"softness\",\"name\":\"Softness\",\"type\":\"slider\",\"default\":0.25,\"min\":0.001,\"max\":1}"
  ",{\"id\":\"heat\",\"name\":\"Heat\",\"type\":\"slider\",\"default\":1,\"min\":0,\"max\":4}]}")
 (func (export "ec_api_version") (result i32) (i32.const 1))
 (func (export "ec_manifest_ptr") (result i32) (i32.const 16))
 (func (export "ec_manifest_len") (result i32) (i32.const 510))
 (func (export "ec_alloc") (param $n i32) (result i32)
  (local $pages i32)
  (if (i32.or (i32.lt_s (local.get $n) (i32.const 0)) (i32.gt_u (local.get $n) (i32.const 67043328))) (then (return (i32.const 0))))
  (local.set $pages (i32.sub (i32.shr_u (i32.add (local.get $n) (i32.const 131071)) (i32.const 16)) (memory.size)))
  (if (i32.gt_s (local.get $pages) (i32.const 0)) (then
   (if (i32.eq (memory.grow (local.get $pages)) (i32.const -1)) (then (return (i32.const 0))))))
  (i32.const 65536))
 (func $clamp (param $x f32) (result f32) (f32.min (f32.const 1) (f32.max (f32.const 0) (local.get $x))))
 (func (export "ec_render") (param $px i32) (param $w i32) (param $h i32) (param $p i32) (param $np i32) (param $time f64) (param $scale f64) (result i32)
  (local $end i32) (local $a f32) (local $y f32) (local $m f32) (local $hot f32)
  (local $threshold f32) (local $softness f32) (local $heat f32)
  (if (i32.or (i32.ne (local.get $np) (i32.const 3))
       (i32.or (i32.le_s (local.get $w) (i32.const 0)) (i32.le_s (local.get $h) (i32.const 0)))) (then (return (i32.const 1))))
  ;; Host validates ranges; also bound the product here before 32-bit arithmetic.
  (if (i64.gt_u (i64.mul (i64.extend_i32_u (local.get $w)) (i64.extend_i32_u (local.get $h))) (i64.const 4190208)) (then (return (i32.const 1))))
  (local.set $threshold (call $clamp (f32.demote_f64 (f64.load (local.get $p)))))
  (local.set $softness (f32.max (f32.const 0.001) (f32.demote_f64 (f64.load offset=8 (local.get $p)))))
  (local.set $heat (f32.max (f32.const 0) (f32.demote_f64 (f64.load offset=16 (local.get $p)))))
  (local.set $end (i32.add (local.get $px) (i32.mul (i32.mul (local.get $w) (local.get $h)) (i32.const 16))))
  (block $done (loop $loop
   (br_if $done (i32.ge_u (local.get $px) (local.get $end)))
   (local.set $a (call $clamp (f32.load offset=12 (local.get $px))))
   (local.set $y (f32.div
    (f32.add (f32.add (f32.mul (f32.load (local.get $px)) (f32.const 0.2126))
                        (f32.mul (f32.load offset=4 (local.get $px)) (f32.const 0.7152)))
             (f32.mul (f32.load offset=8 (local.get $px)) (f32.const 0.0722)))
    (f32.max (local.get $a) (f32.const 0.000001))))
   (local.set $m (call $clamp (f32.div (f32.sub (local.get $y) (local.get $threshold)) (local.get $softness))))
   ;; Smoothstep gives partial coverage without a hard threshold edge.
   (local.set $m (f32.mul (f32.mul (local.get $m) (local.get $m)) (f32.sub (f32.const 3) (f32.mul (f32.const 2) (local.get $m)))))
   (local.set $a (f32.mul (local.get $a) (local.get $m)))
   (local.set $hot (call $clamp (f32.mul (local.get $y) (local.get $heat))))
   (f32.store (local.get $px) (local.get $a))
   (f32.store offset=4 (local.get $px) (f32.mul (local.get $a) (f32.mul (local.get $hot) (local.get $hot))))
   (f32.store offset=8 (local.get $px) (f32.mul (local.get $a) (call $clamp (f32.mul (f32.sub (local.get $hot) (f32.const 0.65)) (f32.const 2.857142857)))))
   (f32.store offset=12 (local.get $px) (local.get $a))
   (local.set $px (i32.add (local.get $px) (i32.const 16)))
   (br $loop)))
  (i32.const 0)))
