# Luma Flame Matte — original API v1 example

Original contributor code, MIT OR Apache-2.0. No Adobe or third-party plug-in code/assets.
This is a luminance-to-alpha/colour filter, not a physical fire simulation or a Saber port.

Load `luma-flame-matte.wat` with `effect.plugins.load {"path": ".../luma-flame-matte.wat"}`.
The loader accepts WAT directly; `wat` (MIT OR Apache-2.0) can compile it to an equivalent
`.wasm` without any imports. In a new CLI process load it explicitly before opening the project;
headless CLI does not automatically scan the desktop Plug-ins folder.

Input and output are premultiplied float RGBA. Unassociate the source luminance using alpha,
then calculate `m = smoothstep(Threshold, Threshold + Softness, luminance)` and output
`alpha = sourceAlpha * m`. Red is alpha; green is alpha times clamped heat squared; blue
rises only in the hottest range. RGB is zero at zero alpha. Heat changes colour independently
of coverage; Threshold and Softness change coverage. Values are intended for SDR noise.
The module reads no clock; animate the upstream noise and these ordinary parameters.

Use Fractal Noise on a masked solid, followed by this effect. Keep noise evolution and offset
continuous for flowing motion. A transparent PNG sequence requires Render Queue `channels: rgba`
or CLI transparent rendering after loading the module in the same process. Save Frame As writes
a background-composited image and is useful only as a viewing proof.

Run `cargo test -p effectcraft-plugin --features wasm luma_flame_example` from the repository root.
Tests include known black/transparent/semi-covered pixels, threshold and heat changes, memory
growth to 512² and concurrent repeatability. The bounded allocator returns failure beyond 64 MiB;
malformed calls return an error or sandbox trap and the host preserves the input frame.
