$gcc = "C:\xpack\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-gcc.exe"
$objcopy = "C:\xpack\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-objcopy.exe"

& $gcc -march=rv32i -mabi=ilp32 -O0 -ffreestanding -nostdlib -T link.ld start.S payload.c -o payload.elf
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed"
    exit $LASTEXITCODE
}

& $objcopy -O binary payload.elf payload.bin
if ($LASTEXITCODE -ne 0) {
    Write-Host "Objcopy failed"
    exit $LASTEXITCODE
}

Write-Host "Success! Generated payload.bin"
