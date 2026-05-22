import sys

if len(sys.argv) != 3:
    print("Usage: python make_hex.py <input.bin> <output.mem>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# Read the raw binary
with open(input_file, 'rb') as f:
    bindata = f.read()

# The hardware instruction memory is exactly 1024 words (4096 bytes).
# Truncate the binary if GCC added huge padding for other memory sections.
MAX_BYTES = 4096
if len(bindata) > MAX_BYTES:
    print(f"ERROR: firmware.bin is {len(bindata)} bytes — exceeds 4KB instruction memory!")
    sys.exit(1)

# Pad with NOPs (0x00000013) if the file size isn't a perfect multiple of 4 bytes
remainder = len(bindata) % 4
if remainder != 0:
    pad_bytes = 4 - remainder
    bindata += b'\x13\x00\x00\x00'[:pad_bytes]

# Write out as 32-bit little-endian hex strings
with open(output_file, 'w') as f:
    for i in range(0, len(bindata), 4):
        word = bindata[i:i+4]
        # Format as 8-character hex, reversing the byte order for Little-Endian
        f.write(f"{word[3]:02x}{word[2]:02x}{word[1]:02x}{word[0]:02x}\n")

print("Generated firmware.mem successfully!")