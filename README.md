### Waveshare RP2040-Plus Scaffold

modular starter project for embedded Rust on RP2040

---

### devlog

- `cargo build` appeared successful
- `readelf -h target/.../rp2040-plus | grep Entry` → always `0x0`
- ELF contained vector table, `Reset`, etc.—but no entry point exported
- default linker script override broke implicit symbol definitions
- `__pre_init` missing → linker failure
- `.vector_table` present but stripped or not marked entry
- project was being built but entry point wasnt retained in ELF header

---

### fixes

#### 1. **linker script: `link.x`**

```ld
ENTRY(Reset)

MEMORY
{
FLASH : ORIGIN = 0x10000000, LENGTH = 16M
RAM : ORIGIN = 0x20000000, LENGTH = 256K
}

PROVIDE(__pre_init = 0);

SECTIONS
{
.vector_table ORIGIN(FLASH) :
{
KEEP(*(.vector_table))
} > FLASH

.text :
{
*(.text .text.*)
*(.rodata .rodata.*)
KEEP(*(.text.Reset))
} > FLASH

.data : AT (ADDR(.text) + SIZEOF(.text))
{
__sdata = .;
*(.data .data.*)
__edata = .;
} > RAM

.bss :
{
__sbss = .;
*(.bss .bss.*)
*(COMMON)
__ebss = .;
} > RAM

.stack (COPY):
{
. = ALIGN(8);
. += 0x1000;
PROVIDE(_stack_start = .);
} > RAM

__sidata = LOADADDR(.data);
}
```

---

#### 2. **`Cargo.toml` setup**

```toml
[dependencies]
cortex-m = "0.7.7"
cortex-m-rt = { version = "0.7.3", features = ["device"] }
panic-halt = "0.2.0"

[[bin]]
name = "rp2040-plus"
path = "src/main.rs"

[profile.release]
panic = "abort"
```

---

#### 3. **minimal `main.rs`**

```rust
#![no_std]
#![no_main]

use cortex_m_rt::entry;
use panic_halt as _;

#[entry]
fn main() -> ! {
loop {}
}
```

---

#### 4. **build config: `.cargo/config.toml`**

```toml
[build]
target = "thumbv6m-none-eabi"

[target.thumbv6m-none-eabi]
rustflags = ["-C", "link-arg=-Tlink.x"]
```

---

### result

```sh
cargo build --release
readelf -h target/thumbv6m-none-eabi/release/rp2040-plus | grep Entry
```

output:
```
Entry point address: 0x10000009
```

---
