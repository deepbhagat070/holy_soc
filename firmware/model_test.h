#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_BOOT

// Safe halt -- reuses your already-proven pattern (plain jump loop,
// no ecall/fence.i dependency, nothing new/unverified introduced).
#define RVMODEL_HALT        \
    self_loop:               \
    j self_loop;

// Signature region markers -- actual memory placement is controlled
// by link.ld, not here.
#define RVMODEL_DATA_SECTION   \
    .align 4;                   \
    .global begin_signature;    \
    begin_signature:

#define RVMODEL_DATA_END       \
    .align 4;                   \
    .global end_signature;      \
    end_signature:

// Not needed for signature comparison -- stubbed to no-ops.
#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_SP, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_SP, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

// Not exercised by the base rv32i_m/I suite (no Zicsr/privilege
// tests) -- stubbed to no-ops.
#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif