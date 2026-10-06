$gcc = "C:\xpack\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-gcc.exe"
$objcopy = "C:\xpack\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-objcopy.exe"

& $gcc -march=rv32i_zifencei -mabi=ilp32 -O0 -ffreestanding -nostdlib -T link.ld start.S bootloader.c -o bootloader.elf
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed"
    exit $LASTEXITCODE
}

& $objcopy -O verilog --verilog-data-width=4 bootloader.elf bootloader.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "Objcopy failed"
    exit $LASTEXITCODE
}

Write-Host "Success! Generated bootloader.txt"
