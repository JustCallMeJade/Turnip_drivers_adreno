#!/usr/bin/env python3
"""
Run this next to freedreno_devices.py and it edits it in place, adding
the Adreno 710, 720, and 722 GPU entries right before the FD725 block.

    python3 add_adreno_710_720_722.py
"""

import re
from pathlib import Path

TARGET = Path(__file__).parent / "freedreno_devices.py"
ANCHOR = 'GPUId(chip_id=0x07030002, name="FD725")'
START_MARKER = "# BEGIN FD710_FD720_FD722_CUSTOM"
END_MARKER = "# END FD710_FD720_FD722_CUSTOM"

NEW_BLOCK = START_MARKER + "\n\n" + '''a710_magic_regs = dict(
        RB_DBG_ECO_CNTL = 0x00000000,
        RB_DBG_ECO_CNTL_blit = 0x00000000,
        RB_RBP_CNTL = 0x0,
)

a710_raw_magic_regs = [
        [A6XXRegs.REG_A6XX_UCHE_CACHE_WAYS, 0x00040004],
        [A6XXRegs.REG_A6XX_TPL1_DBG_ECO_CNTL, 0x01000000],
        [A6XXRegs.REG_A6XX_TPL1_DBG_ECO_CNTL1, 0x00000700],

        [A6XXRegs.REG_A6XX_SP_CHICKEN_BITS, 0x00000400],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_1, 0x00400400],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_2, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_3, 0x00000000],

        [A6XXRegs.REG_A7XX_UCHE_UNKNOWN_0E10, 0x00000000],
        [A6XXRegs.REG_A7XX_UCHE_UNKNOWN_0E11, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_SP_DBG_ECO_CNTL, 0x10000000],

        [A6XXRegs.REG_A6XX_PC_MODE_CNTL, 0x00001f1f],
        [A6XXRegs.REG_A6XX_PC_DBG_ECO_CNTL, 0x20100000],
        [A6XXRegs.REG_A7XX_PC_UNKNOWN_9E24, 0x01fc7f00],

        [A6XXRegs.REG_A7XX_VFD_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_ISDB_CNTL, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AE6A, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_TIMEOUT_THRESHOLD_DP, 0x00000080],
        [A6XXRegs.REG_A7XX_SP_HLSQ_DBG_ECO_CNTL_1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_MODE_CNTL, 0x00000000],

        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AB01, 0x00000001],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AB22, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_B310, 0x00000000],

        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE2,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE2+1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE4,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE4+1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE6,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE6+1, 0x00000000],

        [A6XXRegs.REG_A7XX_GRAS_ROTATION_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_GRAS_DBG_ECO_CNTL,  0x00000800],

        [A6XXRegs.REG_A7XX_RB_UNKNOWN_8E79, 0x00000000],
        [A6XXRegs.REG_A7XX_RB_LRZ_CNTL2, 0x00000000],
        [A6XXRegs.REG_A7XX_RB_CCU_DBG_ECO_CNTL, 0x00080000],
        [A6XXRegs.REG_A6XX_VPC_DBG_ECO_CNTL, 0x02000000],
        [A6XXRegs.REG_A6XX_UCHE_UNKNOWN_0E12, 0x03200000],
]

a720_magic_regs = dict(
        RB_DBG_ECO_CNTL = 0x00000000,
        RB_DBG_ECO_CNTL_blit = 0x00000000,
        RB_RBP_CNTL = 0x0,
)

a720_raw_magic_regs = [
        [A6XXRegs.REG_A6XX_UCHE_CACHE_WAYS, 0x00040004],
        [A6XXRegs.REG_A6XX_TPL1_DBG_ECO_CNTL, 0x03000000],
        [A6XXRegs.REG_A6XX_TPL1_DBG_ECO_CNTL1, 0x00000700],

        [A6XXRegs.REG_A6XX_SP_CHICKEN_BITS, 0x00001400],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_1, 0x01400400],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_2, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_3, 0x00000000],

        [A6XXRegs.REG_A7XX_UCHE_UNKNOWN_0E10, 0x00000000],
        [A6XXRegs.REG_A7XX_UCHE_UNKNOWN_0E11, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_SP_DBG_ECO_CNTL, 0x11000000],

        [A6XXRegs.REG_A6XX_PC_MODE_CNTL, 0x00001f1f],
        [A6XXRegs.REG_A6XX_PC_DBG_ECO_CNTL, 0x20100000],
        [A6XXRegs.REG_A7XX_PC_UNKNOWN_9E24, 0x01fc7f00],

        [A6XXRegs.REG_A7XX_VFD_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_ISDB_CNTL, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AE6A, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_TIMEOUT_THRESHOLD_DP, 0x00000080],
        [A6XXRegs.REG_A7XX_SP_HLSQ_DBG_ECO_CNTL_1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_MODE_CNTL, 0x00000000],

        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AB01, 0x00000001],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AB22, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_B310, 0x00000000],

        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE2,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE2+1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE4,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE4+1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE6,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE6+1, 0x00000000],

        [A6XXRegs.REG_A7XX_GRAS_ROTATION_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_GRAS_DBG_ECO_CNTL,  0x00000800],

        [A6XXRegs.REG_A7XX_RB_UNKNOWN_8E79, 0x00000000],
        [A6XXRegs.REG_A7XX_RB_LRZ_CNTL2, 0x00000000],
        [A6XXRegs.REG_A7XX_RB_CCU_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_VPC_DBG_ECO_CNTL, 0x02000000],
        [A6XXRegs.REG_A6XX_UCHE_UNKNOWN_0E12, 0x03200000],
]

a722_magic_regs = dict(
        RB_DBG_ECO_CNTL = 0x00000000,
        RB_DBG_ECO_CNTL_blit = 0x00000000,
        RB_RBP_CNTL = 0x0,
)

a722_raw_magic_regs = [
        [A6XXRegs.REG_A6XX_UCHE_CACHE_WAYS, 0x00000000],
        [A6XXRegs.REG_A6XX_TPL1_DBG_ECO_CNTL, 0x03000000],
        [A6XXRegs.REG_A6XX_TPL1_DBG_ECO_CNTL1, 0x00000700],

        [A6XXRegs.REG_A6XX_SP_CHICKEN_BITS, 0x00000400],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_1, 0x01400400],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_2, 0x00000010],
        [A6XXRegs.REG_A7XX_SP_CHICKEN_BITS_3, 0x00000000],

        [A6XXRegs.REG_A7XX_UCHE_UNKNOWN_0E10, 0x00000000],
        [A6XXRegs.REG_A7XX_UCHE_UNKNOWN_0E11, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_SP_DBG_ECO_CNTL, 0x11000000],

        [A6XXRegs.REG_A6XX_PC_MODE_CNTL, 0x0000003f],
        [A6XXRegs.REG_A6XX_PC_DBG_ECO_CNTL, 0x20100000],
        [A6XXRegs.REG_A7XX_PC_UNKNOWN_9E24, 0x01fc7f00],

        [A6XXRegs.REG_A7XX_VFD_DBG_ECO_CNTL, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_ISDB_CNTL, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AE6A, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_TIMEOUT_THRESHOLD_DP, 0x00000080],
        [A6XXRegs.REG_A7XX_SP_HLSQ_DBG_ECO_CNTL_1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_HLSQ_MODE_CNTL, 0x00000000],

        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AB01, 0x00000001],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_AB22, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_B310, 0x00000000],

        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE2,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE2+1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE4,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE4+1, 0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE6,   0x00000000],
        [A6XXRegs.REG_A7XX_SP_UNKNOWN_0CE6+1, 0x00000000],

        [A6XXRegs.REG_A7XX_GRAS_ROTATION_CNTL, 0x00000000],
        [A6XXRegs.REG_A6XX_GRAS_DBG_ECO_CNTL,  0x00000800],

        [A6XXRegs.REG_A7XX_RB_UNKNOWN_8E79, 0x00000000],
        [A6XXRegs.REG_A7XX_RB_LRZ_CNTL2, 0x00000000],
        [A6XXRegs.REG_A7XX_RB_CCU_DBG_ECO_CNTL, 0x00080000],
        [A6XXRegs.REG_A6XX_VPC_DBG_ECO_CNTL, 0x02000000],
        [A6XXRegs.REG_A6XX_UCHE_UNKNOWN_0E12, 0x03200000],
]

add_gpus([
        GPUId(chip_id=0x07010000, name="FD710"),
        GPUId(chip_id=0xffff07010000, name="FD710"),
    ], A6xxGPUInfo(
        CHIP.A7XX,
        [a7xx_base, a7xx_gen1],
        num_ccu = 3,
        tile_align_w = 64,
        tile_align_h = 32,
        tile_max_w = 1024,
        tile_max_h = 1024,
        num_vsc_pipes = 32,
        cs_shared_mem_size = 32 * 1024,
        wave_granularity = 2,
        fibers_per_sp = 128 * 2 * 16,
        highest_bank_bit = 16,
        magic_regs = a710_magic_regs,
        raw_magic_regs = a710_raw_magic_regs,
    ))

add_gpus([
        GPUId(chip_id=0x43020000, name="FD720"),
        GPUId(chip_id=0xffff43020000, name="FD720"),
    ], A6xxGPUInfo(
        CHIP.A7XX,
        [a7xx_base, a7xx_gen1],
        num_ccu = 3,
        tile_align_w = 64,
        tile_align_h = 32,
        tile_max_w = 1024,
        tile_max_h = 1024,
        num_vsc_pipes = 32,
        cs_shared_mem_size = 32 * 1024,
        wave_granularity = 2,
        fibers_per_sp = 128 * 2 * 16,
        highest_bank_bit = 16,
        magic_regs = a720_magic_regs,
        raw_magic_regs = a720_raw_magic_regs,
    ))

add_gpus([
        GPUId(chip_id=0x43020100, name="FD722"),
        GPUId(chip_id=0xffff43020100, name="FD722"),
    ], A6xxGPUInfo(
        CHIP.A7XX,
        [a7xx_base, a7xx_gen1],
        num_ccu = 3,
        tile_align_w = 64,
        tile_align_h = 32,
        tile_max_w = 1024,
        tile_max_h = 1024,
        num_vsc_pipes = 32,
        cs_shared_mem_size = 32 * 1024,
        wave_granularity = 2,
        fibers_per_sp = 128 * 2 * 16,
        highest_bank_bit = 16,
        magic_regs = a722_magic_regs,
        raw_magic_regs = a722_raw_magic_regs,
    ))

''' + END_MARKER + "\n\n"

text = TARGET.read_text()

if START_MARKER not in text:
    lines = text.splitlines(keepends=True)
    matches = [i for i, line in enumerate(lines) if ANCHOR in line]
    insert_at = None
    for i in range(matches[0], -1, -1):
        if re.match(r"^\s*add_gpus\(\[\s*$", lines[i]):
            insert_at = i
            break
    new_text = "".join(lines[:insert_at]) + NEW_BLOCK + "".join(lines[insert_at:])
    TARGET.write_text(new_text)
    print(f"Inserted FD710, FD720, FD722 into {TARGET}")
else:
    print(f"{TARGET} already has the FD710/FD720/FD722 block -- nothing to do.")
