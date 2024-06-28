
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	90070713          	addi	a4,a4,-1792 # 80008950 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	32e78793          	addi	a5,a5,814 # 80006390 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc027>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f6478793          	addi	a5,a5,-156 # 80001010 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6ce080e7          	jalr	1742(ra) # 800027f8 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	90650513          	addi	a0,a0,-1786 # 80010a90 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	bdc080e7          	jalr	-1060(ra) # 80000d6e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8f648493          	addi	s1,s1,-1802 # 80010a90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	98690913          	addi	s2,s2,-1658 # 80010b28 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9c6080e7          	jalr	-1594(ra) # 80001b86 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	47a080e7          	jalr	1146(ra) # 80002642 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1b8080e7          	jalr	440(ra) # 8000238e <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	590080e7          	jalr	1424(ra) # 800027a2 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	86a50513          	addi	a0,a0,-1942 # 80010a90 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	bf4080e7          	jalr	-1036(ra) # 80000e22 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	85450513          	addi	a0,a0,-1964 # 80010a90 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bde080e7          	jalr	-1058(ra) # 80000e22 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72b23          	sw	a5,-1866(a4) # 80010b28 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7c450513          	addi	a0,a0,1988 # 80010a90 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a9a080e7          	jalr	-1382(ra) # 80000d6e <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	55c080e7          	jalr	1372(ra) # 8000284e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	79650513          	addi	a0,a0,1942 # 80010a90 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b20080e7          	jalr	-1248(ra) # 80000e22 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	77270713          	addi	a4,a4,1906 # 80010a90 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	74878793          	addi	a5,a5,1864 # 80010a90 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7b27a783          	lw	a5,1970(a5) # 80010b28 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	70670713          	addi	a4,a4,1798 # 80010a90 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6f648493          	addi	s1,s1,1782 # 80010a90 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6ba70713          	addi	a4,a4,1722 # 80010a90 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	74f72223          	sw	a5,1860(a4) # 80010b30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	67e78793          	addi	a5,a5,1662 # 80010a90 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7ab23          	sw	a2,1782(a5) # 80010b2c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ea50513          	addi	a0,a0,1770 # 80010b28 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fac080e7          	jalr	-84(ra) # 800023f2 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	63050513          	addi	a0,a0,1584 # 80010a90 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	876080e7          	jalr	-1930(ra) # 80000cde <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00241797          	auipc	a5,0x241
    8000047c:	1c878793          	addi	a5,a5,456 # 80241640 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6007a223          	sw	zero,1540(a5) # 80010b50 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b7a50513          	addi	a0,a0,-1158 # 800080e8 <digits+0xa8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	38f72823          	sw	a5,912(a4) # 80008910 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	594dad83          	lw	s11,1428(s11) # 80010b50 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	53e50513          	addi	a0,a0,1342 # 80010b38 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	76c080e7          	jalr	1900(ra) # 80000d6e <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3e050513          	addi	a0,a0,992 # 80010b38 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	6c2080e7          	jalr	1730(ra) # 80000e22 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3c448493          	addi	s1,s1,964 # 80010b38 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	558080e7          	jalr	1368(ra) # 80000cde <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	38450513          	addi	a0,a0,900 # 80010b58 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	502080e7          	jalr	1282(ra) # 80000cde <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	52a080e7          	jalr	1322(ra) # 80000d22 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1107a783          	lw	a5,272(a5) # 80008910 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	59c080e7          	jalr	1436(ra) # 80000dc2 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0e07b783          	ld	a5,224(a5) # 80008918 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0e073703          	ld	a4,224(a4) # 80008920 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2f6a0a13          	addi	s4,s4,758 # 80010b58 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ae48493          	addi	s1,s1,174 # 80008918 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ae98993          	addi	s3,s3,174 # 80008920 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b5e080e7          	jalr	-1186(ra) # 800023f2 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	28850513          	addi	a0,a0,648 # 80010b58 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	496080e7          	jalr	1174(ra) # 80000d6e <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0307a783          	lw	a5,48(a5) # 80008910 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	03673703          	ld	a4,54(a4) # 80008920 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0267b783          	ld	a5,38(a5) # 80008918 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	25a98993          	addi	s3,s3,602 # 80010b58 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	01248493          	addi	s1,s1,18 # 80008918 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	01290913          	addi	s2,s2,18 # 80008920 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a70080e7          	jalr	-1424(ra) # 8000238e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	22448493          	addi	s1,s1,548 # 80010b58 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fce7bc23          	sd	a4,-40(a5) # 80008920 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	4c8080e7          	jalr	1224(ra) # 80000e22 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	19e48493          	addi	s1,s1,414 # 80010b58 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	3aa080e7          	jalr	938(ra) # 80000d6e <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	44c080e7          	jalr	1100(ra) # 80000e22 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <initialize>:
} kmem;

struct spinlock lock;
int refs[PGROUNDUP(PHYSTOP) / 4096];
void initialize()
{
    800009e8:	1141                	addi	sp,sp,-16
    800009ea:	e406                	sd	ra,8(sp)
    800009ec:	e022                	sd	s0,0(sp)
    800009ee:	0800                	addi	s0,sp,16
  acquire(&lock);
    800009f0:	00010517          	auipc	a0,0x10
    800009f4:	1a050513          	addi	a0,a0,416 # 80010b90 <lock>
    800009f8:	00000097          	auipc	ra,0x0
    800009fc:	376080e7          	jalr	886(ra) # 80000d6e <acquire>
  for (int i = 0; i < (PGROUNDUP(PHYSTOP) / 4096); ++i)
    80000a00:	00010797          	auipc	a5,0x10
    80000a04:	1c878793          	addi	a5,a5,456 # 80010bc8 <refs>
    80000a08:	00230717          	auipc	a4,0x230
    80000a0c:	1c070713          	addi	a4,a4,448 # 80230bc8 <pid_lock>
    refs[i] = 0;
    80000a10:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < (PGROUNDUP(PHYSTOP) / 4096); ++i)
    80000a14:	0791                	addi	a5,a5,4
    80000a16:	fee79de3          	bne	a5,a4,80000a10 <initialize+0x28>
  release(&lock);
    80000a1a:	00010517          	auipc	a0,0x10
    80000a1e:	17650513          	addi	a0,a0,374 # 80010b90 <lock>
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	400080e7          	jalr	1024(ra) # 80000e22 <release>
}
    80000a2a:	60a2                	ld	ra,8(sp)
    80000a2c:	6402                	ld	s0,0(sp)
    80000a2e:	0141                	addi	sp,sp,16
    80000a30:	8082                	ret

0000000080000a32 <dec_ref>:

void dec_ref(void *pa)
{
    80000a32:	1101                	addi	sp,sp,-32
    80000a34:	ec06                	sd	ra,24(sp)
    80000a36:	e822                	sd	s0,16(sp)
    80000a38:	e426                	sd	s1,8(sp)
    80000a3a:	1000                	addi	s0,sp,32
    80000a3c:	84aa                	mv	s1,a0
  acquire(&lock);
    80000a3e:	00010517          	auipc	a0,0x10
    80000a42:	15250513          	addi	a0,a0,338 # 80010b90 <lock>
    80000a46:	00000097          	auipc	ra,0x0
    80000a4a:	328080e7          	jalr	808(ra) # 80000d6e <acquire>
  if (refs[(uint64)pa / 4096] > 0)
    80000a4e:	00c4d513          	srli	a0,s1,0xc
    80000a52:	00251713          	slli	a4,a0,0x2
    80000a56:	00010797          	auipc	a5,0x10
    80000a5a:	17278793          	addi	a5,a5,370 # 80010bc8 <refs>
    80000a5e:	97ba                	add	a5,a5,a4
    80000a60:	439c                	lw	a5,0(a5)
    80000a62:	02f05763          	blez	a5,80000a90 <dec_ref+0x5e>
  {
    refs[(uint64)pa / 4096] -= 1;
    80000a66:	853a                	mv	a0,a4
    80000a68:	00010717          	auipc	a4,0x10
    80000a6c:	16070713          	addi	a4,a4,352 # 80010bc8 <refs>
    80000a70:	972a                	add	a4,a4,a0
    80000a72:	37fd                	addiw	a5,a5,-1
    80000a74:	c31c                	sw	a5,0(a4)
  }
  else
    panic("dec_ref");
  release(&lock);
    80000a76:	00010517          	auipc	a0,0x10
    80000a7a:	11a50513          	addi	a0,a0,282 # 80010b90 <lock>
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	3a4080e7          	jalr	932(ra) # 80000e22 <release>
}
    80000a86:	60e2                	ld	ra,24(sp)
    80000a88:	6442                	ld	s0,16(sp)
    80000a8a:	64a2                	ld	s1,8(sp)
    80000a8c:	6105                	addi	sp,sp,32
    80000a8e:	8082                	ret
    panic("dec_ref");
    80000a90:	00007517          	auipc	a0,0x7
    80000a94:	5d050513          	addi	a0,a0,1488 # 80008060 <digits+0x20>
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	aa8080e7          	jalr	-1368(ra) # 80000540 <panic>

0000000080000aa0 <add_ref>:

void add_ref(void *pa)
{
    80000aa0:	1101                	addi	sp,sp,-32
    80000aa2:	ec06                	sd	ra,24(sp)
    80000aa4:	e822                	sd	s0,16(sp)
    80000aa6:	e426                	sd	s1,8(sp)
    80000aa8:	1000                	addi	s0,sp,32
    80000aaa:	84aa                	mv	s1,a0
  acquire(&lock);
    80000aac:	00010517          	auipc	a0,0x10
    80000ab0:	0e450513          	addi	a0,a0,228 # 80010b90 <lock>
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	2ba080e7          	jalr	698(ra) # 80000d6e <acquire>
  if (refs[(uint64)pa / 4096] >= 0)
    80000abc:	00c4d513          	srli	a0,s1,0xc
    80000ac0:	00251713          	slli	a4,a0,0x2
    80000ac4:	00010797          	auipc	a5,0x10
    80000ac8:	10478793          	addi	a5,a5,260 # 80010bc8 <refs>
    80000acc:	97ba                	add	a5,a5,a4
    80000ace:	439c                	lw	a5,0(a5)
    80000ad0:	0207c763          	bltz	a5,80000afe <add_ref+0x5e>
  {
    refs[(uint64)pa / 4096] += 1;
    80000ad4:	853a                	mv	a0,a4
    80000ad6:	00010717          	auipc	a4,0x10
    80000ada:	0f270713          	addi	a4,a4,242 # 80010bc8 <refs>
    80000ade:	972a                	add	a4,a4,a0
    80000ae0:	2785                	addiw	a5,a5,1
    80000ae2:	c31c                	sw	a5,0(a4)
  }
  else
    panic("add_ref");
  release(&lock);
    80000ae4:	00010517          	auipc	a0,0x10
    80000ae8:	0ac50513          	addi	a0,a0,172 # 80010b90 <lock>
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	336080e7          	jalr	822(ra) # 80000e22 <release>
}
    80000af4:	60e2                	ld	ra,24(sp)
    80000af6:	6442                	ld	s0,16(sp)
    80000af8:	64a2                	ld	s1,8(sp)
    80000afa:	6105                	addi	sp,sp,32
    80000afc:	8082                	ret
    panic("add_ref");
    80000afe:	00007517          	auipc	a0,0x7
    80000b02:	56a50513          	addi	a0,a0,1386 # 80008068 <digits+0x28>
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	a3a080e7          	jalr	-1478(ra) # 80000540 <panic>

0000000080000b0e <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000b0e:	7179                	addi	sp,sp,-48
    80000b10:	f406                	sd	ra,40(sp)
    80000b12:	f022                	sd	s0,32(sp)
    80000b14:	ec26                	sd	s1,24(sp)
    80000b16:	e84a                	sd	s2,16(sp)
    80000b18:	e44e                	sd	s3,8(sp)
    80000b1a:	1800                	addi	s0,sp,48
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000b1c:	03451793          	slli	a5,a0,0x34
    80000b20:	e3b1                	bnez	a5,80000b64 <kfree+0x56>
    80000b22:	84aa                	mv	s1,a0
    80000b24:	00242797          	auipc	a5,0x242
    80000b28:	cb478793          	addi	a5,a5,-844 # 802427d8 <end>
    80000b2c:	02f56c63          	bltu	a0,a5,80000b64 <kfree+0x56>
    80000b30:	47c5                	li	a5,17
    80000b32:	07ee                	slli	a5,a5,0x1b
    80000b34:	02f57863          	bgeu	a0,a5,80000b64 <kfree+0x56>
    panic("kfree");

  dec_ref(pa);
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	efa080e7          	jalr	-262(ra) # 80000a32 <dec_ref>
  if (refs[(uint64)pa / 4096] > 0)
    80000b40:	00c4d713          	srli	a4,s1,0xc
    80000b44:	070a                	slli	a4,a4,0x2
    80000b46:	00010797          	auipc	a5,0x10
    80000b4a:	08278793          	addi	a5,a5,130 # 80010bc8 <refs>
    80000b4e:	97ba                	add	a5,a5,a4
    80000b50:	439c                	lw	a5,0(a5)
    80000b52:	02f05163          	blez	a5,80000b74 <kfree+0x66>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000b56:	70a2                	ld	ra,40(sp)
    80000b58:	7402                	ld	s0,32(sp)
    80000b5a:	64e2                	ld	s1,24(sp)
    80000b5c:	6942                	ld	s2,16(sp)
    80000b5e:	69a2                	ld	s3,8(sp)
    80000b60:	6145                	addi	sp,sp,48
    80000b62:	8082                	ret
    panic("kfree");
    80000b64:	00007517          	auipc	a0,0x7
    80000b68:	50c50513          	addi	a0,a0,1292 # 80008070 <digits+0x30>
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	9d4080e7          	jalr	-1580(ra) # 80000540 <panic>
  memset(pa, 1, PGSIZE);
    80000b74:	6605                	lui	a2,0x1
    80000b76:	4585                	li	a1,1
    80000b78:	8526                	mv	a0,s1
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	2f0080e7          	jalr	752(ra) # 80000e6a <memset>
  acquire(&kmem.lock);
    80000b82:	00010997          	auipc	s3,0x10
    80000b86:	00e98993          	addi	s3,s3,14 # 80010b90 <lock>
    80000b8a:	00010917          	auipc	s2,0x10
    80000b8e:	01e90913          	addi	s2,s2,30 # 80010ba8 <kmem>
    80000b92:	854a                	mv	a0,s2
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	1da080e7          	jalr	474(ra) # 80000d6e <acquire>
  r->next = kmem.freelist;
    80000b9c:	0309b783          	ld	a5,48(s3)
    80000ba0:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ba2:	0299b823          	sd	s1,48(s3)
  release(&kmem.lock);
    80000ba6:	854a                	mv	a0,s2
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	27a080e7          	jalr	634(ra) # 80000e22 <release>
    80000bb0:	b75d                	j	80000b56 <kfree+0x48>

0000000080000bb2 <freerange>:
{
    80000bb2:	7139                	addi	sp,sp,-64
    80000bb4:	fc06                	sd	ra,56(sp)
    80000bb6:	f822                	sd	s0,48(sp)
    80000bb8:	f426                	sd	s1,40(sp)
    80000bba:	f04a                	sd	s2,32(sp)
    80000bbc:	ec4e                	sd	s3,24(sp)
    80000bbe:	e852                	sd	s4,16(sp)
    80000bc0:	e456                	sd	s5,8(sp)
    80000bc2:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000bc4:	6785                	lui	a5,0x1
    80000bc6:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000bca:	00e504b3          	add	s1,a0,a4
    80000bce:	777d                	lui	a4,0xfffff
    80000bd0:	8cf9                	and	s1,s1,a4
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bd2:	94be                	add	s1,s1,a5
    80000bd4:	0295e463          	bltu	a1,s1,80000bfc <freerange+0x4a>
    80000bd8:	89ae                	mv	s3,a1
    80000bda:	7afd                	lui	s5,0xfffff
    80000bdc:	6a05                	lui	s4,0x1
    80000bde:	01548933          	add	s2,s1,s5
    add_ref(p);
    80000be2:	854a                	mv	a0,s2
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	ebc080e7          	jalr	-324(ra) # 80000aa0 <add_ref>
    kfree(p);
    80000bec:	854a                	mv	a0,s2
    80000bee:	00000097          	auipc	ra,0x0
    80000bf2:	f20080e7          	jalr	-224(ra) # 80000b0e <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bf6:	94d2                	add	s1,s1,s4
    80000bf8:	fe99f3e3          	bgeu	s3,s1,80000bde <freerange+0x2c>
}
    80000bfc:	70e2                	ld	ra,56(sp)
    80000bfe:	7442                	ld	s0,48(sp)
    80000c00:	74a2                	ld	s1,40(sp)
    80000c02:	7902                	ld	s2,32(sp)
    80000c04:	69e2                	ld	s3,24(sp)
    80000c06:	6a42                	ld	s4,16(sp)
    80000c08:	6aa2                	ld	s5,8(sp)
    80000c0a:	6121                	addi	sp,sp,64
    80000c0c:	8082                	ret

0000000080000c0e <kinit>:
{
    80000c0e:	1141                	addi	sp,sp,-16
    80000c10:	e406                	sd	ra,8(sp)
    80000c12:	e022                	sd	s0,0(sp)
    80000c14:	0800                	addi	s0,sp,16
  initlock(&lock, "init_fault");
    80000c16:	00007597          	auipc	a1,0x7
    80000c1a:	46258593          	addi	a1,a1,1122 # 80008078 <digits+0x38>
    80000c1e:	00010517          	auipc	a0,0x10
    80000c22:	f7250513          	addi	a0,a0,-142 # 80010b90 <lock>
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	0b8080e7          	jalr	184(ra) # 80000cde <initlock>
  initialize();
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	dba080e7          	jalr	-582(ra) # 800009e8 <initialize>
  initlock(&kmem.lock, "kmem");
    80000c36:	00007597          	auipc	a1,0x7
    80000c3a:	45258593          	addi	a1,a1,1106 # 80008088 <digits+0x48>
    80000c3e:	00010517          	auipc	a0,0x10
    80000c42:	f6a50513          	addi	a0,a0,-150 # 80010ba8 <kmem>
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	098080e7          	jalr	152(ra) # 80000cde <initlock>
  freerange(end, (void *)PHYSTOP);
    80000c4e:	45c5                	li	a1,17
    80000c50:	05ee                	slli	a1,a1,0x1b
    80000c52:	00242517          	auipc	a0,0x242
    80000c56:	b8650513          	addi	a0,a0,-1146 # 802427d8 <end>
    80000c5a:	00000097          	auipc	ra,0x0
    80000c5e:	f58080e7          	jalr	-168(ra) # 80000bb2 <freerange>
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret

0000000080000c6a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c6a:	1101                	addi	sp,sp,-32
    80000c6c:	ec06                	sd	ra,24(sp)
    80000c6e:	e822                	sd	s0,16(sp)
    80000c70:	e426                	sd	s1,8(sp)
    80000c72:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c74:	00010517          	auipc	a0,0x10
    80000c78:	f3450513          	addi	a0,a0,-204 # 80010ba8 <kmem>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	0f2080e7          	jalr	242(ra) # 80000d6e <acquire>
  r = kmem.freelist;
    80000c84:	00010497          	auipc	s1,0x10
    80000c88:	f3c4b483          	ld	s1,-196(s1) # 80010bc0 <kmem+0x18>
  if (r)
    80000c8c:	c0a1                	beqz	s1,80000ccc <kalloc+0x62>
    kmem.freelist = r->next;
    80000c8e:	609c                	ld	a5,0(s1)
    80000c90:	00010717          	auipc	a4,0x10
    80000c94:	f2f73823          	sd	a5,-208(a4) # 80010bc0 <kmem+0x18>
  release(&kmem.lock);
    80000c98:	00010517          	auipc	a0,0x10
    80000c9c:	f1050513          	addi	a0,a0,-240 # 80010ba8 <kmem>
    80000ca0:	00000097          	auipc	ra,0x0
    80000ca4:	182080e7          	jalr	386(ra) # 80000e22 <release>

  if (r)
  {
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000ca8:	6605                	lui	a2,0x1
    80000caa:	4595                	li	a1,5
    80000cac:	8526                	mv	a0,s1
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	1bc080e7          	jalr	444(ra) # 80000e6a <memset>
    add_ref((void *)r);
    80000cb6:	8526                	mv	a0,s1
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	de8080e7          	jalr	-536(ra) # 80000aa0 <add_ref>
  }
  return (void *)r;
}
    80000cc0:	8526                	mv	a0,s1
    80000cc2:	60e2                	ld	ra,24(sp)
    80000cc4:	6442                	ld	s0,16(sp)
    80000cc6:	64a2                	ld	s1,8(sp)
    80000cc8:	6105                	addi	sp,sp,32
    80000cca:	8082                	ret
  release(&kmem.lock);
    80000ccc:	00010517          	auipc	a0,0x10
    80000cd0:	edc50513          	addi	a0,a0,-292 # 80010ba8 <kmem>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	14e080e7          	jalr	334(ra) # 80000e22 <release>
  if (r)
    80000cdc:	b7d5                	j	80000cc0 <kalloc+0x56>

0000000080000cde <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cde:	1141                	addi	sp,sp,-16
    80000ce0:	e422                	sd	s0,8(sp)
    80000ce2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ce4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ce6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cea:	00053823          	sd	zero,16(a0)
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cf4:	411c                	lw	a5,0(a0)
    80000cf6:	e399                	bnez	a5,80000cfc <holding+0x8>
    80000cf8:	4501                	li	a0,0
  return r;
}
    80000cfa:	8082                	ret
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d06:	6904                	ld	s1,16(a0)
    80000d08:	00001097          	auipc	ra,0x1
    80000d0c:	e62080e7          	jalr	-414(ra) # 80001b6a <mycpu>
    80000d10:	40a48533          	sub	a0,s1,a0
    80000d14:	00153513          	seqz	a0,a0
}
    80000d18:	60e2                	ld	ra,24(sp)
    80000d1a:	6442                	ld	s0,16(sp)
    80000d1c:	64a2                	ld	s1,8(sp)
    80000d1e:	6105                	addi	sp,sp,32
    80000d20:	8082                	ret

0000000080000d22 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d22:	1101                	addi	sp,sp,-32
    80000d24:	ec06                	sd	ra,24(sp)
    80000d26:	e822                	sd	s0,16(sp)
    80000d28:	e426                	sd	s1,8(sp)
    80000d2a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d2c:	100024f3          	csrr	s1,sstatus
    80000d30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d36:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	e30080e7          	jalr	-464(ra) # 80001b6a <mycpu>
    80000d42:	5d3c                	lw	a5,120(a0)
    80000d44:	cf89                	beqz	a5,80000d5e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d46:	00001097          	auipc	ra,0x1
    80000d4a:	e24080e7          	jalr	-476(ra) # 80001b6a <mycpu>
    80000d4e:	5d3c                	lw	a5,120(a0)
    80000d50:	2785                	addiw	a5,a5,1
    80000d52:	dd3c                	sw	a5,120(a0)
}
    80000d54:	60e2                	ld	ra,24(sp)
    80000d56:	6442                	ld	s0,16(sp)
    80000d58:	64a2                	ld	s1,8(sp)
    80000d5a:	6105                	addi	sp,sp,32
    80000d5c:	8082                	ret
    mycpu()->intena = old;
    80000d5e:	00001097          	auipc	ra,0x1
    80000d62:	e0c080e7          	jalr	-500(ra) # 80001b6a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d66:	8085                	srli	s1,s1,0x1
    80000d68:	8885                	andi	s1,s1,1
    80000d6a:	dd64                	sw	s1,124(a0)
    80000d6c:	bfe9                	j	80000d46 <push_off+0x24>

0000000080000d6e <acquire>:
{
    80000d6e:	1101                	addi	sp,sp,-32
    80000d70:	ec06                	sd	ra,24(sp)
    80000d72:	e822                	sd	s0,16(sp)
    80000d74:	e426                	sd	s1,8(sp)
    80000d76:	1000                	addi	s0,sp,32
    80000d78:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d7a:	00000097          	auipc	ra,0x0
    80000d7e:	fa8080e7          	jalr	-88(ra) # 80000d22 <push_off>
  if(holding(lk))
    80000d82:	8526                	mv	a0,s1
    80000d84:	00000097          	auipc	ra,0x0
    80000d88:	f70080e7          	jalr	-144(ra) # 80000cf4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d8c:	4705                	li	a4,1
  if(holding(lk))
    80000d8e:	e115                	bnez	a0,80000db2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d90:	87ba                	mv	a5,a4
    80000d92:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d96:	2781                	sext.w	a5,a5
    80000d98:	ffe5                	bnez	a5,80000d90 <acquire+0x22>
  __sync_synchronize();
    80000d9a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d9e:	00001097          	auipc	ra,0x1
    80000da2:	dcc080e7          	jalr	-564(ra) # 80001b6a <mycpu>
    80000da6:	e888                	sd	a0,16(s1)
}
    80000da8:	60e2                	ld	ra,24(sp)
    80000daa:	6442                	ld	s0,16(sp)
    80000dac:	64a2                	ld	s1,8(sp)
    80000dae:	6105                	addi	sp,sp,32
    80000db0:	8082                	ret
    panic("acquire");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	2de50513          	addi	a0,a0,734 # 80008090 <digits+0x50>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	786080e7          	jalr	1926(ra) # 80000540 <panic>

0000000080000dc2 <pop_off>:

void
pop_off(void)
{
    80000dc2:	1141                	addi	sp,sp,-16
    80000dc4:	e406                	sd	ra,8(sp)
    80000dc6:	e022                	sd	s0,0(sp)
    80000dc8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dca:	00001097          	auipc	ra,0x1
    80000dce:	da0080e7          	jalr	-608(ra) # 80001b6a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dd2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dd6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dd8:	e78d                	bnez	a5,80000e02 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dda:	5d3c                	lw	a5,120(a0)
    80000ddc:	02f05b63          	blez	a5,80000e12 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000de0:	37fd                	addiw	a5,a5,-1
    80000de2:	0007871b          	sext.w	a4,a5
    80000de6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000de8:	eb09                	bnez	a4,80000dfa <pop_off+0x38>
    80000dea:	5d7c                	lw	a5,124(a0)
    80000dec:	c799                	beqz	a5,80000dfa <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000df2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000df6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dfa:	60a2                	ld	ra,8(sp)
    80000dfc:	6402                	ld	s0,0(sp)
    80000dfe:	0141                	addi	sp,sp,16
    80000e00:	8082                	ret
    panic("pop_off - interruptible");
    80000e02:	00007517          	auipc	a0,0x7
    80000e06:	29650513          	addi	a0,a0,662 # 80008098 <digits+0x58>
    80000e0a:	fffff097          	auipc	ra,0xfffff
    80000e0e:	736080e7          	jalr	1846(ra) # 80000540 <panic>
    panic("pop_off");
    80000e12:	00007517          	auipc	a0,0x7
    80000e16:	29e50513          	addi	a0,a0,670 # 800080b0 <digits+0x70>
    80000e1a:	fffff097          	auipc	ra,0xfffff
    80000e1e:	726080e7          	jalr	1830(ra) # 80000540 <panic>

0000000080000e22 <release>:
{
    80000e22:	1101                	addi	sp,sp,-32
    80000e24:	ec06                	sd	ra,24(sp)
    80000e26:	e822                	sd	s0,16(sp)
    80000e28:	e426                	sd	s1,8(sp)
    80000e2a:	1000                	addi	s0,sp,32
    80000e2c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e2e:	00000097          	auipc	ra,0x0
    80000e32:	ec6080e7          	jalr	-314(ra) # 80000cf4 <holding>
    80000e36:	c115                	beqz	a0,80000e5a <release+0x38>
  lk->cpu = 0;
    80000e38:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e3c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e40:	0f50000f          	fence	iorw,ow
    80000e44:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e48:	00000097          	auipc	ra,0x0
    80000e4c:	f7a080e7          	jalr	-134(ra) # 80000dc2 <pop_off>
}
    80000e50:	60e2                	ld	ra,24(sp)
    80000e52:	6442                	ld	s0,16(sp)
    80000e54:	64a2                	ld	s1,8(sp)
    80000e56:	6105                	addi	sp,sp,32
    80000e58:	8082                	ret
    panic("release");
    80000e5a:	00007517          	auipc	a0,0x7
    80000e5e:	25e50513          	addi	a0,a0,606 # 800080b8 <digits+0x78>
    80000e62:	fffff097          	auipc	ra,0xfffff
    80000e66:	6de080e7          	jalr	1758(ra) # 80000540 <panic>

0000000080000e6a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e70:	ca19                	beqz	a2,80000e86 <memset+0x1c>
    80000e72:	87aa                	mv	a5,a0
    80000e74:	1602                	slli	a2,a2,0x20
    80000e76:	9201                	srli	a2,a2,0x20
    80000e78:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e7c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e80:	0785                	addi	a5,a5,1
    80000e82:	fee79de3          	bne	a5,a4,80000e7c <memset+0x12>
  }
  return dst;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e92:	ca05                	beqz	a2,80000ec2 <memcmp+0x36>
    80000e94:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e98:	1682                	slli	a3,a3,0x20
    80000e9a:	9281                	srli	a3,a3,0x20
    80000e9c:	0685                	addi	a3,a3,1
    80000e9e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ea0:	00054783          	lbu	a5,0(a0)
    80000ea4:	0005c703          	lbu	a4,0(a1)
    80000ea8:	00e79863          	bne	a5,a4,80000eb8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000eac:	0505                	addi	a0,a0,1
    80000eae:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000eb0:	fed518e3          	bne	a0,a3,80000ea0 <memcmp+0x14>
  }

  return 0;
    80000eb4:	4501                	li	a0,0
    80000eb6:	a019                	j	80000ebc <memcmp+0x30>
      return *s1 - *s2;
    80000eb8:	40e7853b          	subw	a0,a5,a4
}
    80000ebc:	6422                	ld	s0,8(sp)
    80000ebe:	0141                	addi	sp,sp,16
    80000ec0:	8082                	ret
  return 0;
    80000ec2:	4501                	li	a0,0
    80000ec4:	bfe5                	j	80000ebc <memcmp+0x30>

0000000080000ec6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ec6:	1141                	addi	sp,sp,-16
    80000ec8:	e422                	sd	s0,8(sp)
    80000eca:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ecc:	c205                	beqz	a2,80000eec <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ece:	02a5e263          	bltu	a1,a0,80000ef2 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ed2:	1602                	slli	a2,a2,0x20
    80000ed4:	9201                	srli	a2,a2,0x20
    80000ed6:	00c587b3          	add	a5,a1,a2
{
    80000eda:	872a                	mv	a4,a0
      *d++ = *s++;
    80000edc:	0585                	addi	a1,a1,1
    80000ede:	0705                	addi	a4,a4,1
    80000ee0:	fff5c683          	lbu	a3,-1(a1)
    80000ee4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ee8:	fef59ae3          	bne	a1,a5,80000edc <memmove+0x16>

  return dst;
}
    80000eec:	6422                	ld	s0,8(sp)
    80000eee:	0141                	addi	sp,sp,16
    80000ef0:	8082                	ret
  if(s < d && s + n > d){
    80000ef2:	02061693          	slli	a3,a2,0x20
    80000ef6:	9281                	srli	a3,a3,0x20
    80000ef8:	00d58733          	add	a4,a1,a3
    80000efc:	fce57be3          	bgeu	a0,a4,80000ed2 <memmove+0xc>
    d += n;
    80000f00:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f02:	fff6079b          	addiw	a5,a2,-1
    80000f06:	1782                	slli	a5,a5,0x20
    80000f08:	9381                	srli	a5,a5,0x20
    80000f0a:	fff7c793          	not	a5,a5
    80000f0e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f10:	177d                	addi	a4,a4,-1
    80000f12:	16fd                	addi	a3,a3,-1
    80000f14:	00074603          	lbu	a2,0(a4)
    80000f18:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f1c:	fee79ae3          	bne	a5,a4,80000f10 <memmove+0x4a>
    80000f20:	b7f1                	j	80000eec <memmove+0x26>

0000000080000f22 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e406                	sd	ra,8(sp)
    80000f26:	e022                	sd	s0,0(sp)
    80000f28:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	f9c080e7          	jalr	-100(ra) # 80000ec6 <memmove>
}
    80000f32:	60a2                	ld	ra,8(sp)
    80000f34:	6402                	ld	s0,0(sp)
    80000f36:	0141                	addi	sp,sp,16
    80000f38:	8082                	ret

0000000080000f3a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f3a:	1141                	addi	sp,sp,-16
    80000f3c:	e422                	sd	s0,8(sp)
    80000f3e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f40:	ce11                	beqz	a2,80000f5c <strncmp+0x22>
    80000f42:	00054783          	lbu	a5,0(a0)
    80000f46:	cf89                	beqz	a5,80000f60 <strncmp+0x26>
    80000f48:	0005c703          	lbu	a4,0(a1)
    80000f4c:	00f71a63          	bne	a4,a5,80000f60 <strncmp+0x26>
    n--, p++, q++;
    80000f50:	367d                	addiw	a2,a2,-1
    80000f52:	0505                	addi	a0,a0,1
    80000f54:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f56:	f675                	bnez	a2,80000f42 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f58:	4501                	li	a0,0
    80000f5a:	a809                	j	80000f6c <strncmp+0x32>
    80000f5c:	4501                	li	a0,0
    80000f5e:	a039                	j	80000f6c <strncmp+0x32>
  if(n == 0)
    80000f60:	ca09                	beqz	a2,80000f72 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f62:	00054503          	lbu	a0,0(a0)
    80000f66:	0005c783          	lbu	a5,0(a1)
    80000f6a:	9d1d                	subw	a0,a0,a5
}
    80000f6c:	6422                	ld	s0,8(sp)
    80000f6e:	0141                	addi	sp,sp,16
    80000f70:	8082                	ret
    return 0;
    80000f72:	4501                	li	a0,0
    80000f74:	bfe5                	j	80000f6c <strncmp+0x32>

0000000080000f76 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f76:	1141                	addi	sp,sp,-16
    80000f78:	e422                	sd	s0,8(sp)
    80000f7a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f7c:	872a                	mv	a4,a0
    80000f7e:	8832                	mv	a6,a2
    80000f80:	367d                	addiw	a2,a2,-1
    80000f82:	01005963          	blez	a6,80000f94 <strncpy+0x1e>
    80000f86:	0705                	addi	a4,a4,1
    80000f88:	0005c783          	lbu	a5,0(a1)
    80000f8c:	fef70fa3          	sb	a5,-1(a4)
    80000f90:	0585                	addi	a1,a1,1
    80000f92:	f7f5                	bnez	a5,80000f7e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f94:	86ba                	mv	a3,a4
    80000f96:	00c05c63          	blez	a2,80000fae <strncpy+0x38>
    *s++ = 0;
    80000f9a:	0685                	addi	a3,a3,1
    80000f9c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fa0:	40d707bb          	subw	a5,a4,a3
    80000fa4:	37fd                	addiw	a5,a5,-1
    80000fa6:	010787bb          	addw	a5,a5,a6
    80000faa:	fef048e3          	bgtz	a5,80000f9a <strncpy+0x24>
  return os;
}
    80000fae:	6422                	ld	s0,8(sp)
    80000fb0:	0141                	addi	sp,sp,16
    80000fb2:	8082                	ret

0000000080000fb4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fb4:	1141                	addi	sp,sp,-16
    80000fb6:	e422                	sd	s0,8(sp)
    80000fb8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fba:	02c05363          	blez	a2,80000fe0 <safestrcpy+0x2c>
    80000fbe:	fff6069b          	addiw	a3,a2,-1
    80000fc2:	1682                	slli	a3,a3,0x20
    80000fc4:	9281                	srli	a3,a3,0x20
    80000fc6:	96ae                	add	a3,a3,a1
    80000fc8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fca:	00d58963          	beq	a1,a3,80000fdc <safestrcpy+0x28>
    80000fce:	0585                	addi	a1,a1,1
    80000fd0:	0785                	addi	a5,a5,1
    80000fd2:	fff5c703          	lbu	a4,-1(a1)
    80000fd6:	fee78fa3          	sb	a4,-1(a5)
    80000fda:	fb65                	bnez	a4,80000fca <safestrcpy+0x16>
    ;
  *s = 0;
    80000fdc:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fe0:	6422                	ld	s0,8(sp)
    80000fe2:	0141                	addi	sp,sp,16
    80000fe4:	8082                	ret

0000000080000fe6 <strlen>:

int
strlen(const char *s)
{
    80000fe6:	1141                	addi	sp,sp,-16
    80000fe8:	e422                	sd	s0,8(sp)
    80000fea:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fec:	00054783          	lbu	a5,0(a0)
    80000ff0:	cf91                	beqz	a5,8000100c <strlen+0x26>
    80000ff2:	0505                	addi	a0,a0,1
    80000ff4:	87aa                	mv	a5,a0
    80000ff6:	4685                	li	a3,1
    80000ff8:	9e89                	subw	a3,a3,a0
    80000ffa:	00f6853b          	addw	a0,a3,a5
    80000ffe:	0785                	addi	a5,a5,1
    80001000:	fff7c703          	lbu	a4,-1(a5)
    80001004:	fb7d                	bnez	a4,80000ffa <strlen+0x14>
    ;
  return n;
}
    80001006:	6422                	ld	s0,8(sp)
    80001008:	0141                	addi	sp,sp,16
    8000100a:	8082                	ret
  for(n = 0; s[n]; n++)
    8000100c:	4501                	li	a0,0
    8000100e:	bfe5                	j	80001006 <strlen+0x20>

0000000080001010 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001010:	1141                	addi	sp,sp,-16
    80001012:	e406                	sd	ra,8(sp)
    80001014:	e022                	sd	s0,0(sp)
    80001016:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001018:	00001097          	auipc	ra,0x1
    8000101c:	b42080e7          	jalr	-1214(ra) # 80001b5a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001020:	00008717          	auipc	a4,0x8
    80001024:	90870713          	addi	a4,a4,-1784 # 80008928 <started>
  if(cpuid() == 0){
    80001028:	c139                	beqz	a0,8000106e <main+0x5e>
    while(started == 0)
    8000102a:	431c                	lw	a5,0(a4)
    8000102c:	2781                	sext.w	a5,a5
    8000102e:	dff5                	beqz	a5,8000102a <main+0x1a>
      ;
    __sync_synchronize();
    80001030:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001034:	00001097          	auipc	ra,0x1
    80001038:	b26080e7          	jalr	-1242(ra) # 80001b5a <cpuid>
    8000103c:	85aa                	mv	a1,a0
    8000103e:	00007517          	auipc	a0,0x7
    80001042:	09a50513          	addi	a0,a0,154 # 800080d8 <digits+0x98>
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	544080e7          	jalr	1348(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    8000104e:	00000097          	auipc	ra,0x0
    80001052:	0d8080e7          	jalr	216(ra) # 80001126 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001056:	00002097          	auipc	ra,0x2
    8000105a:	b2c080e7          	jalr	-1236(ra) # 80002b82 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000105e:	00005097          	auipc	ra,0x5
    80001062:	372080e7          	jalr	882(ra) # 800063d0 <plicinithart>
  }

  scheduler();        
    80001066:	00001097          	auipc	ra,0x1
    8000106a:	0aa080e7          	jalr	170(ra) # 80002110 <scheduler>
    consoleinit();
    8000106e:	fffff097          	auipc	ra,0xfffff
    80001072:	3e2080e7          	jalr	994(ra) # 80000450 <consoleinit>
    printfinit();
    80001076:	fffff097          	auipc	ra,0xfffff
    8000107a:	6f4080e7          	jalr	1780(ra) # 8000076a <printfinit>
    printf("\n");
    8000107e:	00007517          	auipc	a0,0x7
    80001082:	06a50513          	addi	a0,a0,106 # 800080e8 <digits+0xa8>
    80001086:	fffff097          	auipc	ra,0xfffff
    8000108a:	504080e7          	jalr	1284(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    8000108e:	00007517          	auipc	a0,0x7
    80001092:	03250513          	addi	a0,a0,50 # 800080c0 <digits+0x80>
    80001096:	fffff097          	auipc	ra,0xfffff
    8000109a:	4f4080e7          	jalr	1268(ra) # 8000058a <printf>
    printf("\n");
    8000109e:	00007517          	auipc	a0,0x7
    800010a2:	04a50513          	addi	a0,a0,74 # 800080e8 <digits+0xa8>
    800010a6:	fffff097          	auipc	ra,0xfffff
    800010aa:	4e4080e7          	jalr	1252(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    800010ae:	00000097          	auipc	ra,0x0
    800010b2:	b60080e7          	jalr	-1184(ra) # 80000c0e <kinit>
    kvminit();       // create kernel page table
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	326080e7          	jalr	806(ra) # 800013dc <kvminit>
    kvminithart();   // turn on paging
    800010be:	00000097          	auipc	ra,0x0
    800010c2:	068080e7          	jalr	104(ra) # 80001126 <kvminithart>
    procinit();      // process table
    800010c6:	00001097          	auipc	ra,0x1
    800010ca:	9e0080e7          	jalr	-1568(ra) # 80001aa6 <procinit>
    trapinit();      // trap vectors
    800010ce:	00002097          	auipc	ra,0x2
    800010d2:	a8c080e7          	jalr	-1396(ra) # 80002b5a <trapinit>
    trapinithart();  // install kernel trap vector
    800010d6:	00002097          	auipc	ra,0x2
    800010da:	aac080e7          	jalr	-1364(ra) # 80002b82 <trapinithart>
    plicinit();      // set up interrupt controller
    800010de:	00005097          	auipc	ra,0x5
    800010e2:	2dc080e7          	jalr	732(ra) # 800063ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010e6:	00005097          	auipc	ra,0x5
    800010ea:	2ea080e7          	jalr	746(ra) # 800063d0 <plicinithart>
    binit();         // buffer cache
    800010ee:	00002097          	auipc	ra,0x2
    800010f2:	45c080e7          	jalr	1116(ra) # 8000354a <binit>
    iinit();         // inode table
    800010f6:	00003097          	auipc	ra,0x3
    800010fa:	afc080e7          	jalr	-1284(ra) # 80003bf2 <iinit>
    fileinit();      // file table
    800010fe:	00004097          	auipc	ra,0x4
    80001102:	aa2080e7          	jalr	-1374(ra) # 80004ba0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001106:	00005097          	auipc	ra,0x5
    8000110a:	3d2080e7          	jalr	978(ra) # 800064d8 <virtio_disk_init>
    userinit();      // first user process
    8000110e:	00001097          	auipc	ra,0x1
    80001112:	d86080e7          	jalr	-634(ra) # 80001e94 <userinit>
    __sync_synchronize();
    80001116:	0ff0000f          	fence
    started = 1;
    8000111a:	4785                	li	a5,1
    8000111c:	00008717          	auipc	a4,0x8
    80001120:	80f72623          	sw	a5,-2036(a4) # 80008928 <started>
    80001124:	b789                	j	80001066 <main+0x56>

0000000080001126 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80001126:	1141                	addi	sp,sp,-16
    80001128:	e422                	sd	s0,8(sp)
    8000112a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000112c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001130:	00008797          	auipc	a5,0x8
    80001134:	8007b783          	ld	a5,-2048(a5) # 80008930 <kernel_pagetable>
    80001138:	83b1                	srli	a5,a5,0xc
    8000113a:	577d                	li	a4,-1
    8000113c:	177e                	slli	a4,a4,0x3f
    8000113e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001140:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001144:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001148:	6422                	ld	s0,8(sp)
    8000114a:	0141                	addi	sp,sp,16
    8000114c:	8082                	ret

000000008000114e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000114e:	7139                	addi	sp,sp,-64
    80001150:	fc06                	sd	ra,56(sp)
    80001152:	f822                	sd	s0,48(sp)
    80001154:	f426                	sd	s1,40(sp)
    80001156:	f04a                	sd	s2,32(sp)
    80001158:	ec4e                	sd	s3,24(sp)
    8000115a:	e852                	sd	s4,16(sp)
    8000115c:	e456                	sd	s5,8(sp)
    8000115e:	e05a                	sd	s6,0(sp)
    80001160:	0080                	addi	s0,sp,64
    80001162:	84aa                	mv	s1,a0
    80001164:	89ae                	mv	s3,a1
    80001166:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80001168:	57fd                	li	a5,-1
    8000116a:	83e9                	srli	a5,a5,0x1a
    8000116c:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    8000116e:	4b31                	li	s6,12
  if (va >= MAXVA)
    80001170:	04b7f263          	bgeu	a5,a1,800011b4 <walk+0x66>
    panic("walk");
    80001174:	00007517          	auipc	a0,0x7
    80001178:	f7c50513          	addi	a0,a0,-132 # 800080f0 <digits+0xb0>
    8000117c:	fffff097          	auipc	ra,0xfffff
    80001180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001184:	060a8663          	beqz	s5,800011f0 <walk+0xa2>
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	ae2080e7          	jalr	-1310(ra) # 80000c6a <kalloc>
    80001190:	84aa                	mv	s1,a0
    80001192:	c529                	beqz	a0,800011dc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001194:	6605                	lui	a2,0x1
    80001196:	4581                	li	a1,0
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	cd2080e7          	jalr	-814(ra) # 80000e6a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011a0:	00c4d793          	srli	a5,s1,0xc
    800011a4:	07aa                	slli	a5,a5,0xa
    800011a6:	0017e793          	ori	a5,a5,1
    800011aa:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    800011ae:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    800011b0:	036a0063          	beq	s4,s6,800011d0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011b4:	0149d933          	srl	s2,s3,s4
    800011b8:	1ff97913          	andi	s2,s2,511
    800011bc:	090e                	slli	s2,s2,0x3
    800011be:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    800011c0:	00093483          	ld	s1,0(s2)
    800011c4:	0014f793          	andi	a5,s1,1
    800011c8:	dfd5                	beqz	a5,80001184 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011ca:	80a9                	srli	s1,s1,0xa
    800011cc:	04b2                	slli	s1,s1,0xc
    800011ce:	b7c5                	j	800011ae <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011d0:	00c9d513          	srli	a0,s3,0xc
    800011d4:	1ff57513          	andi	a0,a0,511
    800011d8:	050e                	slli	a0,a0,0x3
    800011da:	9526                	add	a0,a0,s1
}
    800011dc:	70e2                	ld	ra,56(sp)
    800011de:	7442                	ld	s0,48(sp)
    800011e0:	74a2                	ld	s1,40(sp)
    800011e2:	7902                	ld	s2,32(sp)
    800011e4:	69e2                	ld	s3,24(sp)
    800011e6:	6a42                	ld	s4,16(sp)
    800011e8:	6aa2                	ld	s5,8(sp)
    800011ea:	6b02                	ld	s6,0(sp)
    800011ec:	6121                	addi	sp,sp,64
    800011ee:	8082                	ret
        return 0;
    800011f0:	4501                	li	a0,0
    800011f2:	b7ed                	j	800011dc <walk+0x8e>

00000000800011f4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    800011f4:	57fd                	li	a5,-1
    800011f6:	83e9                	srli	a5,a5,0x1a
    800011f8:	00b7f463          	bgeu	a5,a1,80001200 <walkaddr+0xc>
    return 0;
    800011fc:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011fe:	8082                	ret
{
    80001200:	1141                	addi	sp,sp,-16
    80001202:	e406                	sd	ra,8(sp)
    80001204:	e022                	sd	s0,0(sp)
    80001206:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001208:	4601                	li	a2,0
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f44080e7          	jalr	-188(ra) # 8000114e <walk>
  if (pte == 0)
    80001212:	c105                	beqz	a0,80001232 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    80001214:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    80001216:	0117f693          	andi	a3,a5,17
    8000121a:	4745                	li	a4,17
    return 0;
    8000121c:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    8000121e:	00e68663          	beq	a3,a4,8000122a <walkaddr+0x36>
}
    80001222:	60a2                	ld	ra,8(sp)
    80001224:	6402                	ld	s0,0(sp)
    80001226:	0141                	addi	sp,sp,16
    80001228:	8082                	ret
  pa = PTE2PA(*pte);
    8000122a:	83a9                	srli	a5,a5,0xa
    8000122c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001230:	bfcd                	j	80001222 <walkaddr+0x2e>
    return 0;
    80001232:	4501                	li	a0,0
    80001234:	b7fd                	j	80001222 <walkaddr+0x2e>

0000000080001236 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001236:	715d                	addi	sp,sp,-80
    80001238:	e486                	sd	ra,72(sp)
    8000123a:	e0a2                	sd	s0,64(sp)
    8000123c:	fc26                	sd	s1,56(sp)
    8000123e:	f84a                	sd	s2,48(sp)
    80001240:	f44e                	sd	s3,40(sp)
    80001242:	f052                	sd	s4,32(sp)
    80001244:	ec56                	sd	s5,24(sp)
    80001246:	e85a                	sd	s6,16(sp)
    80001248:	e45e                	sd	s7,8(sp)
    8000124a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    8000124c:	c639                	beqz	a2,8000129a <mappages+0x64>
    8000124e:	8aaa                	mv	s5,a0
    80001250:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001252:	777d                	lui	a4,0xfffff
    80001254:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001258:	fff58993          	addi	s3,a1,-1
    8000125c:	99b2                	add	s3,s3,a2
    8000125e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001262:	893e                	mv	s2,a5
    80001264:	40f68a33          	sub	s4,a3,a5
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    80001268:	6b85                	lui	s7,0x1
    8000126a:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    8000126e:	4605                	li	a2,1
    80001270:	85ca                	mv	a1,s2
    80001272:	8556                	mv	a0,s5
    80001274:	00000097          	auipc	ra,0x0
    80001278:	eda080e7          	jalr	-294(ra) # 8000114e <walk>
    8000127c:	cd1d                	beqz	a0,800012ba <mappages+0x84>
    if (*pte & PTE_V)
    8000127e:	611c                	ld	a5,0(a0)
    80001280:	8b85                	andi	a5,a5,1
    80001282:	e785                	bnez	a5,800012aa <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001284:	80b1                	srli	s1,s1,0xc
    80001286:	04aa                	slli	s1,s1,0xa
    80001288:	0164e4b3          	or	s1,s1,s6
    8000128c:	0014e493          	ori	s1,s1,1
    80001290:	e104                	sd	s1,0(a0)
    if (a == last)
    80001292:	05390063          	beq	s2,s3,800012d2 <mappages+0x9c>
    a += PGSIZE;
    80001296:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001298:	bfc9                	j	8000126a <mappages+0x34>
    panic("mappages: size");
    8000129a:	00007517          	auipc	a0,0x7
    8000129e:	e5e50513          	addi	a0,a0,-418 # 800080f8 <digits+0xb8>
    800012a2:	fffff097          	auipc	ra,0xfffff
    800012a6:	29e080e7          	jalr	670(ra) # 80000540 <panic>
      panic("mappages: remap");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5e50513          	addi	a0,a0,-418 # 80008108 <digits+0xc8>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      return -1;
    800012ba:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012bc:	60a6                	ld	ra,72(sp)
    800012be:	6406                	ld	s0,64(sp)
    800012c0:	74e2                	ld	s1,56(sp)
    800012c2:	7942                	ld	s2,48(sp)
    800012c4:	79a2                	ld	s3,40(sp)
    800012c6:	7a02                	ld	s4,32(sp)
    800012c8:	6ae2                	ld	s5,24(sp)
    800012ca:	6b42                	ld	s6,16(sp)
    800012cc:	6ba2                	ld	s7,8(sp)
    800012ce:	6161                	addi	sp,sp,80
    800012d0:	8082                	ret
  return 0;
    800012d2:	4501                	li	a0,0
    800012d4:	b7e5                	j	800012bc <mappages+0x86>

00000000800012d6 <kvmmap>:
{
    800012d6:	1141                	addi	sp,sp,-16
    800012d8:	e406                	sd	ra,8(sp)
    800012da:	e022                	sd	s0,0(sp)
    800012dc:	0800                	addi	s0,sp,16
    800012de:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012e0:	86b2                	mv	a3,a2
    800012e2:	863e                	mv	a2,a5
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f52080e7          	jalr	-174(ra) # 80001236 <mappages>
    800012ec:	e509                	bnez	a0,800012f6 <kvmmap+0x20>
}
    800012ee:	60a2                	ld	ra,8(sp)
    800012f0:	6402                	ld	s0,0(sp)
    800012f2:	0141                	addi	sp,sp,16
    800012f4:	8082                	ret
    panic("kvmmap");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e2250513          	addi	a0,a0,-478 # 80008118 <digits+0xd8>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	242080e7          	jalr	578(ra) # 80000540 <panic>

0000000080001306 <kvmmake>:
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	e04a                	sd	s2,0(sp)
    80001310:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    80001312:	00000097          	auipc	ra,0x0
    80001316:	958080e7          	jalr	-1704(ra) # 80000c6a <kalloc>
    8000131a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	b4a080e7          	jalr	-1206(ra) # 80000e6a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001328:	4719                	li	a4,6
    8000132a:	6685                	lui	a3,0x1
    8000132c:	10000637          	lui	a2,0x10000
    80001330:	100005b7          	lui	a1,0x10000
    80001334:	8526                	mv	a0,s1
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	fa0080e7          	jalr	-96(ra) # 800012d6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000133e:	4719                	li	a4,6
    80001340:	6685                	lui	a3,0x1
    80001342:	10001637          	lui	a2,0x10001
    80001346:	100015b7          	lui	a1,0x10001
    8000134a:	8526                	mv	a0,s1
    8000134c:	00000097          	auipc	ra,0x0
    80001350:	f8a080e7          	jalr	-118(ra) # 800012d6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001354:	4719                	li	a4,6
    80001356:	004006b7          	lui	a3,0x400
    8000135a:	0c000637          	lui	a2,0xc000
    8000135e:	0c0005b7          	lui	a1,0xc000
    80001362:	8526                	mv	a0,s1
    80001364:	00000097          	auipc	ra,0x0
    80001368:	f72080e7          	jalr	-142(ra) # 800012d6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    8000136c:	00007917          	auipc	s2,0x7
    80001370:	c9490913          	addi	s2,s2,-876 # 80008000 <etext>
    80001374:	4729                	li	a4,10
    80001376:	80007697          	auipc	a3,0x80007
    8000137a:	c8a68693          	addi	a3,a3,-886 # 8000 <_entry-0x7fff8000>
    8000137e:	4605                	li	a2,1
    80001380:	067e                	slli	a2,a2,0x1f
    80001382:	85b2                	mv	a1,a2
    80001384:	8526                	mv	a0,s1
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	f50080e7          	jalr	-176(ra) # 800012d6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    8000138e:	4719                	li	a4,6
    80001390:	46c5                	li	a3,17
    80001392:	06ee                	slli	a3,a3,0x1b
    80001394:	412686b3          	sub	a3,a3,s2
    80001398:	864a                	mv	a2,s2
    8000139a:	85ca                	mv	a1,s2
    8000139c:	8526                	mv	a0,s1
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	f38080e7          	jalr	-200(ra) # 800012d6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013a6:	4729                	li	a4,10
    800013a8:	6685                	lui	a3,0x1
    800013aa:	00006617          	auipc	a2,0x6
    800013ae:	c5660613          	addi	a2,a2,-938 # 80007000 <_trampoline>
    800013b2:	040005b7          	lui	a1,0x4000
    800013b6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013b8:	05b2                	slli	a1,a1,0xc
    800013ba:	8526                	mv	a0,s1
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	f1a080e7          	jalr	-230(ra) # 800012d6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013c4:	8526                	mv	a0,s1
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	64a080e7          	jalr	1610(ra) # 80001a10 <proc_mapstacks>
}
    800013ce:	8526                	mv	a0,s1
    800013d0:	60e2                	ld	ra,24(sp)
    800013d2:	6442                	ld	s0,16(sp)
    800013d4:	64a2                	ld	s1,8(sp)
    800013d6:	6902                	ld	s2,0(sp)
    800013d8:	6105                	addi	sp,sp,32
    800013da:	8082                	ret

00000000800013dc <kvminit>:
{
    800013dc:	1141                	addi	sp,sp,-16
    800013de:	e406                	sd	ra,8(sp)
    800013e0:	e022                	sd	s0,0(sp)
    800013e2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	f22080e7          	jalr	-222(ra) # 80001306 <kvmmake>
    800013ec:	00007797          	auipc	a5,0x7
    800013f0:	54a7b223          	sd	a0,1348(a5) # 80008930 <kernel_pagetable>
}
    800013f4:	60a2                	ld	ra,8(sp)
    800013f6:	6402                	ld	s0,0(sp)
    800013f8:	0141                	addi	sp,sp,16
    800013fa:	8082                	ret

00000000800013fc <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013fc:	715d                	addi	sp,sp,-80
    800013fe:	e486                	sd	ra,72(sp)
    80001400:	e0a2                	sd	s0,64(sp)
    80001402:	fc26                	sd	s1,56(sp)
    80001404:	f84a                	sd	s2,48(sp)
    80001406:	f44e                	sd	s3,40(sp)
    80001408:	f052                	sd	s4,32(sp)
    8000140a:	ec56                	sd	s5,24(sp)
    8000140c:	e85a                	sd	s6,16(sp)
    8000140e:	e45e                	sd	s7,8(sp)
    80001410:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    80001412:	03459793          	slli	a5,a1,0x34
    80001416:	e795                	bnez	a5,80001442 <uvmunmap+0x46>
    80001418:	8a2a                	mv	s4,a0
    8000141a:	892e                	mv	s2,a1
    8000141c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000141e:	0632                	slli	a2,a2,0xc
    80001420:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    80001424:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001426:	6b05                	lui	s6,0x1
    80001428:	0735e263          	bltu	a1,s3,8000148c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    8000142c:	60a6                	ld	ra,72(sp)
    8000142e:	6406                	ld	s0,64(sp)
    80001430:	74e2                	ld	s1,56(sp)
    80001432:	7942                	ld	s2,48(sp)
    80001434:	79a2                	ld	s3,40(sp)
    80001436:	7a02                	ld	s4,32(sp)
    80001438:	6ae2                	ld	s5,24(sp)
    8000143a:	6b42                	ld	s6,16(sp)
    8000143c:	6ba2                	ld	s7,8(sp)
    8000143e:	6161                	addi	sp,sp,80
    80001440:	8082                	ret
    panic("uvmunmap: not aligned");
    80001442:	00007517          	auipc	a0,0x7
    80001446:	cde50513          	addi	a0,a0,-802 # 80008120 <digits+0xe0>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	0f6080e7          	jalr	246(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001452:	00007517          	auipc	a0,0x7
    80001456:	ce650513          	addi	a0,a0,-794 # 80008138 <digits+0xf8>
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	0e6080e7          	jalr	230(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001462:	00007517          	auipc	a0,0x7
    80001466:	ce650513          	addi	a0,a0,-794 # 80008148 <digits+0x108>
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	0d6080e7          	jalr	214(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001472:	00007517          	auipc	a0,0x7
    80001476:	cee50513          	addi	a0,a0,-786 # 80008160 <digits+0x120>
    8000147a:	fffff097          	auipc	ra,0xfffff
    8000147e:	0c6080e7          	jalr	198(ra) # 80000540 <panic>
    *pte = 0;
    80001482:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001486:	995a                	add	s2,s2,s6
    80001488:	fb3972e3          	bgeu	s2,s3,8000142c <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    8000148c:	4601                	li	a2,0
    8000148e:	85ca                	mv	a1,s2
    80001490:	8552                	mv	a0,s4
    80001492:	00000097          	auipc	ra,0x0
    80001496:	cbc080e7          	jalr	-836(ra) # 8000114e <walk>
    8000149a:	84aa                	mv	s1,a0
    8000149c:	d95d                	beqz	a0,80001452 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000149e:	6108                	ld	a0,0(a0)
    800014a0:	00157793          	andi	a5,a0,1
    800014a4:	dfdd                	beqz	a5,80001462 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    800014a6:	3ff57793          	andi	a5,a0,1023
    800014aa:	fd7784e3          	beq	a5,s7,80001472 <uvmunmap+0x76>
    if (do_free)
    800014ae:	fc0a8ae3          	beqz	s5,80001482 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014b2:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    800014b4:	0532                	slli	a0,a0,0xc
    800014b6:	fffff097          	auipc	ra,0xfffff
    800014ba:	658080e7          	jalr	1624(ra) # 80000b0e <kfree>
    800014be:	b7d1                	j	80001482 <uvmunmap+0x86>

00000000800014c0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014c0:	1101                	addi	sp,sp,-32
    800014c2:	ec06                	sd	ra,24(sp)
    800014c4:	e822                	sd	s0,16(sp)
    800014c6:	e426                	sd	s1,8(sp)
    800014c8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	7a0080e7          	jalr	1952(ra) # 80000c6a <kalloc>
    800014d2:	84aa                	mv	s1,a0
  if (pagetable == 0)
    800014d4:	c519                	beqz	a0,800014e2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014d6:	6605                	lui	a2,0x1
    800014d8:	4581                	li	a1,0
    800014da:	00000097          	auipc	ra,0x0
    800014de:	990080e7          	jalr	-1648(ra) # 80000e6a <memset>
  return pagetable;
}
    800014e2:	8526                	mv	a0,s1
    800014e4:	60e2                	ld	ra,24(sp)
    800014e6:	6442                	ld	s0,16(sp)
    800014e8:	64a2                	ld	s1,8(sp)
    800014ea:	6105                	addi	sp,sp,32
    800014ec:	8082                	ret

00000000800014ee <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014ee:	7179                	addi	sp,sp,-48
    800014f0:	f406                	sd	ra,40(sp)
    800014f2:	f022                	sd	s0,32(sp)
    800014f4:	ec26                	sd	s1,24(sp)
    800014f6:	e84a                	sd	s2,16(sp)
    800014f8:	e44e                	sd	s3,8(sp)
    800014fa:	e052                	sd	s4,0(sp)
    800014fc:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    800014fe:	6785                	lui	a5,0x1
    80001500:	04f67863          	bgeu	a2,a5,80001550 <uvmfirst+0x62>
    80001504:	8a2a                	mv	s4,a0
    80001506:	89ae                	mv	s3,a1
    80001508:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	760080e7          	jalr	1888(ra) # 80000c6a <kalloc>
    80001512:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001514:	6605                	lui	a2,0x1
    80001516:	4581                	li	a1,0
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	952080e7          	jalr	-1710(ra) # 80000e6a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001520:	4779                	li	a4,30
    80001522:	86ca                	mv	a3,s2
    80001524:	6605                	lui	a2,0x1
    80001526:	4581                	li	a1,0
    80001528:	8552                	mv	a0,s4
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	d0c080e7          	jalr	-756(ra) # 80001236 <mappages>
  memmove(mem, src, sz);
    80001532:	8626                	mv	a2,s1
    80001534:	85ce                	mv	a1,s3
    80001536:	854a                	mv	a0,s2
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	98e080e7          	jalr	-1650(ra) # 80000ec6 <memmove>
}
    80001540:	70a2                	ld	ra,40(sp)
    80001542:	7402                	ld	s0,32(sp)
    80001544:	64e2                	ld	s1,24(sp)
    80001546:	6942                	ld	s2,16(sp)
    80001548:	69a2                	ld	s3,8(sp)
    8000154a:	6a02                	ld	s4,0(sp)
    8000154c:	6145                	addi	sp,sp,48
    8000154e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001550:	00007517          	auipc	a0,0x7
    80001554:	c2850513          	addi	a0,a0,-984 # 80008178 <digits+0x138>
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	fe8080e7          	jalr	-24(ra) # 80000540 <panic>

0000000080001560 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001560:	1101                	addi	sp,sp,-32
    80001562:	ec06                	sd	ra,24(sp)
    80001564:	e822                	sd	s0,16(sp)
    80001566:	e426                	sd	s1,8(sp)
    80001568:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    8000156a:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    8000156c:	00b67d63          	bgeu	a2,a1,80001586 <uvmdealloc+0x26>
    80001570:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001572:	6785                	lui	a5,0x1
    80001574:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001576:	00f60733          	add	a4,a2,a5
    8000157a:	76fd                	lui	a3,0xfffff
    8000157c:	8f75                	and	a4,a4,a3
    8000157e:	97ae                	add	a5,a5,a1
    80001580:	8ff5                	and	a5,a5,a3
    80001582:	00f76863          	bltu	a4,a5,80001592 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001586:	8526                	mv	a0,s1
    80001588:	60e2                	ld	ra,24(sp)
    8000158a:	6442                	ld	s0,16(sp)
    8000158c:	64a2                	ld	s1,8(sp)
    8000158e:	6105                	addi	sp,sp,32
    80001590:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001592:	8f99                	sub	a5,a5,a4
    80001594:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001596:	4685                	li	a3,1
    80001598:	0007861b          	sext.w	a2,a5
    8000159c:	85ba                	mv	a1,a4
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	e5e080e7          	jalr	-418(ra) # 800013fc <uvmunmap>
    800015a6:	b7c5                	j	80001586 <uvmdealloc+0x26>

00000000800015a8 <uvmalloc>:
  if (newsz < oldsz)
    800015a8:	0ab66563          	bltu	a2,a1,80001652 <uvmalloc+0xaa>
{
    800015ac:	7139                	addi	sp,sp,-64
    800015ae:	fc06                	sd	ra,56(sp)
    800015b0:	f822                	sd	s0,48(sp)
    800015b2:	f426                	sd	s1,40(sp)
    800015b4:	f04a                	sd	s2,32(sp)
    800015b6:	ec4e                	sd	s3,24(sp)
    800015b8:	e852                	sd	s4,16(sp)
    800015ba:	e456                	sd	s5,8(sp)
    800015bc:	e05a                	sd	s6,0(sp)
    800015be:	0080                	addi	s0,sp,64
    800015c0:	8aaa                	mv	s5,a0
    800015c2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015c4:	6785                	lui	a5,0x1
    800015c6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015c8:	95be                	add	a1,a1,a5
    800015ca:	77fd                	lui	a5,0xfffff
    800015cc:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    800015d0:	08c9f363          	bgeu	s3,a2,80001656 <uvmalloc+0xae>
    800015d4:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015d6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	690080e7          	jalr	1680(ra) # 80000c6a <kalloc>
    800015e2:	84aa                	mv	s1,a0
    if (mem == 0)
    800015e4:	c51d                	beqz	a0,80001612 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015e6:	6605                	lui	a2,0x1
    800015e8:	4581                	li	a1,0
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	880080e7          	jalr	-1920(ra) # 80000e6a <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015f2:	875a                	mv	a4,s6
    800015f4:	86a6                	mv	a3,s1
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85ca                	mv	a1,s2
    800015fa:	8556                	mv	a0,s5
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	c3a080e7          	jalr	-966(ra) # 80001236 <mappages>
    80001604:	e90d                	bnez	a0,80001636 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001606:	6785                	lui	a5,0x1
    80001608:	993e                	add	s2,s2,a5
    8000160a:	fd4968e3          	bltu	s2,s4,800015da <uvmalloc+0x32>
  return newsz;
    8000160e:	8552                	mv	a0,s4
    80001610:	a809                	j	80001622 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001612:	864e                	mv	a2,s3
    80001614:	85ca                	mv	a1,s2
    80001616:	8556                	mv	a0,s5
    80001618:	00000097          	auipc	ra,0x0
    8000161c:	f48080e7          	jalr	-184(ra) # 80001560 <uvmdealloc>
      return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	70e2                	ld	ra,56(sp)
    80001624:	7442                	ld	s0,48(sp)
    80001626:	74a2                	ld	s1,40(sp)
    80001628:	7902                	ld	s2,32(sp)
    8000162a:	69e2                	ld	s3,24(sp)
    8000162c:	6a42                	ld	s4,16(sp)
    8000162e:	6aa2                	ld	s5,8(sp)
    80001630:	6b02                	ld	s6,0(sp)
    80001632:	6121                	addi	sp,sp,64
    80001634:	8082                	ret
      kfree(mem);
    80001636:	8526                	mv	a0,s1
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	4d6080e7          	jalr	1238(ra) # 80000b0e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001640:	864e                	mv	a2,s3
    80001642:	85ca                	mv	a1,s2
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	f1a080e7          	jalr	-230(ra) # 80001560 <uvmdealloc>
      return 0;
    8000164e:	4501                	li	a0,0
    80001650:	bfc9                	j	80001622 <uvmalloc+0x7a>
    return oldsz;
    80001652:	852e                	mv	a0,a1
}
    80001654:	8082                	ret
  return newsz;
    80001656:	8532                	mv	a0,a2
    80001658:	b7e9                	j	80001622 <uvmalloc+0x7a>

000000008000165a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    8000165a:	7179                	addi	sp,sp,-48
    8000165c:	f406                	sd	ra,40(sp)
    8000165e:	f022                	sd	s0,32(sp)
    80001660:	ec26                	sd	s1,24(sp)
    80001662:	e84a                	sd	s2,16(sp)
    80001664:	e44e                	sd	s3,8(sp)
    80001666:	e052                	sd	s4,0(sp)
    80001668:	1800                	addi	s0,sp,48
    8000166a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    8000166c:	84aa                	mv	s1,a0
    8000166e:	6905                	lui	s2,0x1
    80001670:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001672:	4985                	li	s3,1
    80001674:	a829                	j	8000168e <freewalk+0x34>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001676:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001678:	00c79513          	slli	a0,a5,0xc
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	fde080e7          	jalr	-34(ra) # 8000165a <freewalk>
      pagetable[i] = 0;
    80001684:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    80001688:	04a1                	addi	s1,s1,8
    8000168a:	03248163          	beq	s1,s2,800016ac <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000168e:	609c                	ld	a5,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001690:	00f7f713          	andi	a4,a5,15
    80001694:	ff3701e3          	beq	a4,s3,80001676 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001698:	8b85                	andi	a5,a5,1
    8000169a:	d7fd                	beqz	a5,80001688 <freewalk+0x2e>
    {
      panic("freewalk: leaf");
    8000169c:	00007517          	auipc	a0,0x7
    800016a0:	afc50513          	addi	a0,a0,-1284 # 80008198 <digits+0x158>
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	e9c080e7          	jalr	-356(ra) # 80000540 <panic>
    }
  }
  kfree((void *)pagetable);
    800016ac:	8552                	mv	a0,s4
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	460080e7          	jalr	1120(ra) # 80000b0e <kfree>
}
    800016b6:	70a2                	ld	ra,40(sp)
    800016b8:	7402                	ld	s0,32(sp)
    800016ba:	64e2                	ld	s1,24(sp)
    800016bc:	6942                	ld	s2,16(sp)
    800016be:	69a2                	ld	s3,8(sp)
    800016c0:	6a02                	ld	s4,0(sp)
    800016c2:	6145                	addi	sp,sp,48
    800016c4:	8082                	ret

00000000800016c6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016c6:	1101                	addi	sp,sp,-32
    800016c8:	ec06                	sd	ra,24(sp)
    800016ca:	e822                	sd	s0,16(sp)
    800016cc:	e426                	sd	s1,8(sp)
    800016ce:	1000                	addi	s0,sp,32
    800016d0:	84aa                	mv	s1,a0
  if (sz > 0)
    800016d2:	e999                	bnez	a1,800016e8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    800016d4:	8526                	mv	a0,s1
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	f84080e7          	jalr	-124(ra) # 8000165a <freewalk>
}
    800016de:	60e2                	ld	ra,24(sp)
    800016e0:	6442                	ld	s0,16(sp)
    800016e2:	64a2                	ld	s1,8(sp)
    800016e4:	6105                	addi	sp,sp,32
    800016e6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800016e8:	6785                	lui	a5,0x1
    800016ea:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016ec:	95be                	add	a1,a1,a5
    800016ee:	4685                	li	a3,1
    800016f0:	00c5d613          	srli	a2,a1,0xc
    800016f4:	4581                	li	a1,0
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	d06080e7          	jalr	-762(ra) # 800013fc <uvmunmap>
    800016fe:	bfd9                	j	800016d4 <uvmfree+0xe>

0000000080001700 <uvmcopy>:
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa;
  uint64 i;

  for (i = 0; i < sz; i += PGSIZE)
    80001716:	c269                	beqz	a2,800017d8 <uvmcopy+0xd8>
    80001718:	8aaa                	mv	s5,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	89b2                	mv	s3,a2
    8000171e:	4481                	li	s1,0

        if ((flags & PTE_W) > 0)
        {
          flags &= (~PTE_W);
          flags |= PTE_COW;
          *pte = PA2PTE(pa) | flags;
    80001720:	7b7d                	lui	s6,0xfffff
    80001722:	002b5b13          	srli	s6,s6,0x2
    80001726:	a825                	j	8000175e <uvmcopy+0x5e>
          flags &= (~PTE_W);
    80001728:	3fb77693          	andi	a3,a4,1019
          flags |= PTE_COW;
    8000172c:	0206e713          	ori	a4,a3,32
          *pte = PA2PTE(pa) | flags;
    80001730:	0167f7b3          	and	a5,a5,s6
    80001734:	8fd9                	or	a5,a5,a4
    80001736:	e11c                	sd	a5,0(a0)
        }

        if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80001738:	86ca                	mv	a3,s2
    8000173a:	6605                	lui	a2,0x1
    8000173c:	85a6                	mv	a1,s1
    8000173e:	8552                	mv	a0,s4
    80001740:	00000097          	auipc	ra,0x0
    80001744:	af6080e7          	jalr	-1290(ra) # 80001236 <mappages>
    80001748:	8baa                	mv	s7,a0
    8000174a:	e129                	bnez	a0,8000178c <uvmcopy+0x8c>
        {
          goto err;
        }
        add_ref((void *)pa);
    8000174c:	854a                	mv	a0,s2
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	352080e7          	jalr	850(ra) # 80000aa0 <add_ref>
  for (i = 0; i < sz; i += PGSIZE)
    80001756:	6785                	lui	a5,0x1
    80001758:	94be                	add	s1,s1,a5
    8000175a:	0534f363          	bgeu	s1,s3,800017a0 <uvmcopy+0xa0>
    pte = walk(old, i, 0);
    8000175e:	4601                	li	a2,0
    80001760:	85a6                	mv	a1,s1
    80001762:	8556                	mv	a0,s5
    80001764:	00000097          	auipc	ra,0x0
    80001768:	9ea080e7          	jalr	-1558(ra) # 8000114e <walk>
    if (pte != 0)
    8000176c:	cd31                	beqz	a0,800017c8 <uvmcopy+0xc8>
      if ((*pte & PTE_V) != 0)
    8000176e:	611c                	ld	a5,0(a0)
    80001770:	0017f713          	andi	a4,a5,1
    80001774:	c331                	beqz	a4,800017b8 <uvmcopy+0xb8>
        pa = PTE2PA(*pte);
    80001776:	00a7d913          	srli	s2,a5,0xa
    8000177a:	0932                	slli	s2,s2,0xc
        flags = PTE_FLAGS(*pte);
    8000177c:	0007871b          	sext.w	a4,a5
        if ((flags & PTE_W) > 0)
    80001780:	0047f693          	andi	a3,a5,4
    80001784:	f2d5                	bnez	a3,80001728 <uvmcopy+0x28>
        flags = PTE_FLAGS(*pte);
    80001786:	3ff77713          	andi	a4,a4,1023
    8000178a:	b77d                	j	80001738 <uvmcopy+0x38>
      panic("uvmcopy: pte doesn't exists");
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000178c:	4685                	li	a3,1
    8000178e:	00c4d613          	srli	a2,s1,0xc
    80001792:	4581                	li	a1,0
    80001794:	8552                	mv	a0,s4
    80001796:	00000097          	auipc	ra,0x0
    8000179a:	c66080e7          	jalr	-922(ra) # 800013fc <uvmunmap>
  return -1;
    8000179e:	5bfd                	li	s7,-1
}
    800017a0:	855e                	mv	a0,s7
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret
        panic("uvmcopy: page is not present");
    800017b8:	00007517          	auipc	a0,0x7
    800017bc:	9f050513          	addi	a0,a0,-1552 # 800081a8 <digits+0x168>
    800017c0:	fffff097          	auipc	ra,0xfffff
    800017c4:	d80080e7          	jalr	-640(ra) # 80000540 <panic>
      panic("uvmcopy: pte doesn't exists");
    800017c8:	00007517          	auipc	a0,0x7
    800017cc:	a0050513          	addi	a0,a0,-1536 # 800081c8 <digits+0x188>
    800017d0:	fffff097          	auipc	ra,0xfffff
    800017d4:	d70080e7          	jalr	-656(ra) # 80000540 <panic>
  return 0;
    800017d8:	4b81                	li	s7,0
    800017da:	b7d9                	j	800017a0 <uvmcopy+0xa0>

00000000800017dc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    800017dc:	1141                	addi	sp,sp,-16
    800017de:	e406                	sd	ra,8(sp)
    800017e0:	e022                	sd	s0,0(sp)
    800017e2:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    800017e4:	4601                	li	a2,0
    800017e6:	00000097          	auipc	ra,0x0
    800017ea:	968080e7          	jalr	-1688(ra) # 8000114e <walk>
  if (pte == 0)
    800017ee:	c901                	beqz	a0,800017fe <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017f0:	611c                	ld	a5,0(a0)
    800017f2:	9bbd                	andi	a5,a5,-17
    800017f4:	e11c                	sd	a5,0(a0)
}
    800017f6:	60a2                	ld	ra,8(sp)
    800017f8:	6402                	ld	s0,0(sp)
    800017fa:	0141                	addi	sp,sp,16
    800017fc:	8082                	ret
    panic("uvmclear");
    800017fe:	00007517          	auipc	a0,0x7
    80001802:	9ea50513          	addi	a0,a0,-1558 # 800081e8 <digits+0x1a8>
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	d3a080e7          	jalr	-710(ra) # 80000540 <panic>

000000008000180e <copyout>:
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va, pa, flags;
  pte_t *pte;

  while (len > 0)
    8000180e:	c2d5                	beqz	a3,800018b2 <copyout+0xa4>
{
    80001810:	711d                	addi	sp,sp,-96
    80001812:	ec86                	sd	ra,88(sp)
    80001814:	e8a2                	sd	s0,80(sp)
    80001816:	e4a6                	sd	s1,72(sp)
    80001818:	e0ca                	sd	s2,64(sp)
    8000181a:	fc4e                	sd	s3,56(sp)
    8000181c:	f852                	sd	s4,48(sp)
    8000181e:	f456                	sd	s5,40(sp)
    80001820:	f05a                	sd	s6,32(sp)
    80001822:	ec5e                	sd	s7,24(sp)
    80001824:	e862                	sd	s8,16(sp)
    80001826:	e466                	sd	s9,8(sp)
    80001828:	1080                	addi	s0,sp,96
    8000182a:	8baa                	mv	s7,a0
    8000182c:	89ae                	mv	s3,a1
    8000182e:	8b32                	mv	s6,a2
    80001830:	8ab6                	mv	s5,a3
  {
    va = PGROUNDDOWN(dstva);
    80001832:	7cfd                	lui	s9,0xfffff
    {
      write_trap((void *)va, pagetable);
      pa = walkaddr(pagetable, va);
    }

    n = PGSIZE - (dstva - va);
    80001834:	6c05                	lui	s8,0x1
    80001836:	a081                	j	80001876 <copyout+0x68>
      write_trap((void *)va, pagetable);
    80001838:	85de                	mv	a1,s7
    8000183a:	854a                	mv	a0,s2
    8000183c:	00001097          	auipc	ra,0x1
    80001840:	35e080e7          	jalr	862(ra) # 80002b9a <write_trap>
      pa = walkaddr(pagetable, va);
    80001844:	85ca                	mv	a1,s2
    80001846:	855e                	mv	a0,s7
    80001848:	00000097          	auipc	ra,0x0
    8000184c:	9ac080e7          	jalr	-1620(ra) # 800011f4 <walkaddr>
    80001850:	8a2a                	mv	s4,a0
    80001852:	a0b9                	j	800018a0 <copyout+0x92>
    if (n > len)
      n = len;
    memmove((void *)(pa + (dstva - va)), src, n);
    80001854:	41298533          	sub	a0,s3,s2
    80001858:	0004861b          	sext.w	a2,s1
    8000185c:	85da                	mv	a1,s6
    8000185e:	9552                	add	a0,a0,s4
    80001860:	fffff097          	auipc	ra,0xfffff
    80001864:	666080e7          	jalr	1638(ra) # 80000ec6 <memmove>

    len -= n;
    80001868:	409a8ab3          	sub	s5,s5,s1
    src += n;
    8000186c:	9b26                	add	s6,s6,s1
    dstva = va + PGSIZE;
    8000186e:	018909b3          	add	s3,s2,s8
  while (len > 0)
    80001872:	020a8e63          	beqz	s5,800018ae <copyout+0xa0>
    va = PGROUNDDOWN(dstva);
    80001876:	0199f933          	and	s2,s3,s9
    pa = walkaddr(pagetable, va);
    8000187a:	85ca                	mv	a1,s2
    8000187c:	855e                	mv	a0,s7
    8000187e:	00000097          	auipc	ra,0x0
    80001882:	976080e7          	jalr	-1674(ra) # 800011f4 <walkaddr>
    80001886:	8a2a                	mv	s4,a0
    if (pa == 0)
    80001888:	c51d                	beqz	a0,800018b6 <copyout+0xa8>
    pte = walk(pagetable, va, 0);
    8000188a:	4601                	li	a2,0
    8000188c:	85ca                	mv	a1,s2
    8000188e:	855e                	mv	a0,s7
    80001890:	00000097          	auipc	ra,0x0
    80001894:	8be080e7          	jalr	-1858(ra) # 8000114e <walk>
    if (flags & PTE_COW)
    80001898:	611c                	ld	a5,0(a0)
    8000189a:	0207f793          	andi	a5,a5,32
    8000189e:	ffc9                	bnez	a5,80001838 <copyout+0x2a>
    n = PGSIZE - (dstva - va);
    800018a0:	413904b3          	sub	s1,s2,s3
    800018a4:	94e2                	add	s1,s1,s8
    800018a6:	fa9af7e3          	bgeu	s5,s1,80001854 <copyout+0x46>
    800018aa:	84d6                	mv	s1,s5
    800018ac:	b765                	j	80001854 <copyout+0x46>
  }
  return 0;
    800018ae:	4501                	li	a0,0
    800018b0:	a021                	j	800018b8 <copyout+0xaa>
    800018b2:	4501                	li	a0,0
}
    800018b4:	8082                	ret
      return -1;
    800018b6:	557d                	li	a0,-1
}
    800018b8:	60e6                	ld	ra,88(sp)
    800018ba:	6446                	ld	s0,80(sp)
    800018bc:	64a6                	ld	s1,72(sp)
    800018be:	6906                	ld	s2,64(sp)
    800018c0:	79e2                	ld	s3,56(sp)
    800018c2:	7a42                	ld	s4,48(sp)
    800018c4:	7aa2                	ld	s5,40(sp)
    800018c6:	7b02                	ld	s6,32(sp)
    800018c8:	6be2                	ld	s7,24(sp)
    800018ca:	6c42                	ld	s8,16(sp)
    800018cc:	6ca2                	ld	s9,8(sp)
    800018ce:	6125                	addi	sp,sp,96
    800018d0:	8082                	ret

00000000800018d2 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    800018d2:	caa5                	beqz	a3,80001942 <copyin+0x70>
{
    800018d4:	715d                	addi	sp,sp,-80
    800018d6:	e486                	sd	ra,72(sp)
    800018d8:	e0a2                	sd	s0,64(sp)
    800018da:	fc26                	sd	s1,56(sp)
    800018dc:	f84a                	sd	s2,48(sp)
    800018de:	f44e                	sd	s3,40(sp)
    800018e0:	f052                	sd	s4,32(sp)
    800018e2:	ec56                	sd	s5,24(sp)
    800018e4:	e85a                	sd	s6,16(sp)
    800018e6:	e45e                	sd	s7,8(sp)
    800018e8:	e062                	sd	s8,0(sp)
    800018ea:	0880                	addi	s0,sp,80
    800018ec:	8b2a                	mv	s6,a0
    800018ee:	8a2e                	mv	s4,a1
    800018f0:	8c32                	mv	s8,a2
    800018f2:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800018f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f6:	6a85                	lui	s5,0x1
    800018f8:	a01d                	j	8000191e <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018fa:	018505b3          	add	a1,a0,s8
    800018fe:	0004861b          	sext.w	a2,s1
    80001902:	412585b3          	sub	a1,a1,s2
    80001906:	8552                	mv	a0,s4
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	5be080e7          	jalr	1470(ra) # 80000ec6 <memmove>

    len -= n;
    80001910:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001914:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001916:	01590c33          	add	s8,s2,s5
  while (len > 0)
    8000191a:	02098263          	beqz	s3,8000193e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000191e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001922:	85ca                	mv	a1,s2
    80001924:	855a                	mv	a0,s6
    80001926:	00000097          	auipc	ra,0x0
    8000192a:	8ce080e7          	jalr	-1842(ra) # 800011f4 <walkaddr>
    if (pa0 == 0)
    8000192e:	cd01                	beqz	a0,80001946 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001930:	418904b3          	sub	s1,s2,s8
    80001934:	94d6                	add	s1,s1,s5
    80001936:	fc99f2e3          	bgeu	s3,s1,800018fa <copyin+0x28>
    8000193a:	84ce                	mv	s1,s3
    8000193c:	bf7d                	j	800018fa <copyin+0x28>
  }
  return 0;
    8000193e:	4501                	li	a0,0
    80001940:	a021                	j	80001948 <copyin+0x76>
    80001942:	4501                	li	a0,0
}
    80001944:	8082                	ret
      return -1;
    80001946:	557d                	li	a0,-1
}
    80001948:	60a6                	ld	ra,72(sp)
    8000194a:	6406                	ld	s0,64(sp)
    8000194c:	74e2                	ld	s1,56(sp)
    8000194e:	7942                	ld	s2,48(sp)
    80001950:	79a2                	ld	s3,40(sp)
    80001952:	7a02                	ld	s4,32(sp)
    80001954:	6ae2                	ld	s5,24(sp)
    80001956:	6b42                	ld	s6,16(sp)
    80001958:	6ba2                	ld	s7,8(sp)
    8000195a:	6c02                	ld	s8,0(sp)
    8000195c:	6161                	addi	sp,sp,80
    8000195e:	8082                	ret

0000000080001960 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80001960:	c2dd                	beqz	a3,80001a06 <copyinstr+0xa6>
{
    80001962:	715d                	addi	sp,sp,-80
    80001964:	e486                	sd	ra,72(sp)
    80001966:	e0a2                	sd	s0,64(sp)
    80001968:	fc26                	sd	s1,56(sp)
    8000196a:	f84a                	sd	s2,48(sp)
    8000196c:	f44e                	sd	s3,40(sp)
    8000196e:	f052                	sd	s4,32(sp)
    80001970:	ec56                	sd	s5,24(sp)
    80001972:	e85a                	sd	s6,16(sp)
    80001974:	e45e                	sd	s7,8(sp)
    80001976:	0880                	addi	s0,sp,80
    80001978:	8a2a                	mv	s4,a0
    8000197a:	8b2e                	mv	s6,a1
    8000197c:	8bb2                	mv	s7,a2
    8000197e:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001980:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001982:	6985                	lui	s3,0x1
    80001984:	a02d                	j	800019ae <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001986:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000198a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    8000198c:	37fd                	addiw	a5,a5,-1
    8000198e:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001992:	60a6                	ld	ra,72(sp)
    80001994:	6406                	ld	s0,64(sp)
    80001996:	74e2                	ld	s1,56(sp)
    80001998:	7942                	ld	s2,48(sp)
    8000199a:	79a2                	ld	s3,40(sp)
    8000199c:	7a02                	ld	s4,32(sp)
    8000199e:	6ae2                	ld	s5,24(sp)
    800019a0:	6b42                	ld	s6,16(sp)
    800019a2:	6ba2                	ld	s7,8(sp)
    800019a4:	6161                	addi	sp,sp,80
    800019a6:	8082                	ret
    srcva = va0 + PGSIZE;
    800019a8:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    800019ac:	c8a9                	beqz	s1,800019fe <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800019ae:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019b2:	85ca                	mv	a1,s2
    800019b4:	8552                	mv	a0,s4
    800019b6:	00000097          	auipc	ra,0x0
    800019ba:	83e080e7          	jalr	-1986(ra) # 800011f4 <walkaddr>
    if (pa0 == 0)
    800019be:	c131                	beqz	a0,80001a02 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800019c0:	417906b3          	sub	a3,s2,s7
    800019c4:	96ce                	add	a3,a3,s3
    800019c6:	00d4f363          	bgeu	s1,a3,800019cc <copyinstr+0x6c>
    800019ca:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    800019cc:	955e                	add	a0,a0,s7
    800019ce:	41250533          	sub	a0,a0,s2
    while (n > 0)
    800019d2:	daf9                	beqz	a3,800019a8 <copyinstr+0x48>
    800019d4:	87da                	mv	a5,s6
      if (*p == '\0')
    800019d6:	41650633          	sub	a2,a0,s6
    800019da:	fff48593          	addi	a1,s1,-1
    800019de:	95da                	add	a1,a1,s6
    while (n > 0)
    800019e0:	96da                	add	a3,a3,s6
      if (*p == '\0')
    800019e2:	00f60733          	add	a4,a2,a5
    800019e6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbc828>
    800019ea:	df51                	beqz	a4,80001986 <copyinstr+0x26>
        *dst = *p;
    800019ec:	00e78023          	sb	a4,0(a5)
      --max;
    800019f0:	40f584b3          	sub	s1,a1,a5
      dst++;
    800019f4:	0785                	addi	a5,a5,1
    while (n > 0)
    800019f6:	fed796e3          	bne	a5,a3,800019e2 <copyinstr+0x82>
      dst++;
    800019fa:	8b3e                	mv	s6,a5
    800019fc:	b775                	j	800019a8 <copyinstr+0x48>
    800019fe:	4781                	li	a5,0
    80001a00:	b771                	j	8000198c <copyinstr+0x2c>
      return -1;
    80001a02:	557d                	li	a0,-1
    80001a04:	b779                	j	80001992 <copyinstr+0x32>
  int got_null = 0;
    80001a06:	4781                	li	a5,0
  if (got_null)
    80001a08:	37fd                	addiw	a5,a5,-1
    80001a0a:	0007851b          	sext.w	a0,a5
}
    80001a0e:	8082                	ret

0000000080001a10 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a10:	7139                	addi	sp,sp,-64
    80001a12:	fc06                	sd	ra,56(sp)
    80001a14:	f822                	sd	s0,48(sp)
    80001a16:	f426                	sd	s1,40(sp)
    80001a18:	f04a                	sd	s2,32(sp)
    80001a1a:	ec4e                	sd	s3,24(sp)
    80001a1c:	e852                	sd	s4,16(sp)
    80001a1e:	e456                	sd	s5,8(sp)
    80001a20:	e05a                	sd	s6,0(sp)
    80001a22:	0080                	addi	s0,sp,64
    80001a24:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a26:	0022f497          	auipc	s1,0x22f
    80001a2a:	5d248493          	addi	s1,s1,1490 # 80230ff8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a2e:	8b26                	mv	s6,s1
    80001a30:	00006a97          	auipc	s5,0x6
    80001a34:	5d0a8a93          	addi	s5,s5,1488 # 80008000 <etext>
    80001a38:	04000937          	lui	s2,0x4000
    80001a3c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a3e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a40:	00236a17          	auipc	s4,0x236
    80001a44:	9b8a0a13          	addi	s4,s4,-1608 # 802373f8 <tickslock>
    char *pa = kalloc();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	222080e7          	jalr	546(ra) # 80000c6a <kalloc>
    80001a50:	862a                	mv	a2,a0
    if (pa == 0)
    80001a52:	c131                	beqz	a0,80001a96 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a54:	416485b3          	sub	a1,s1,s6
    80001a58:	8591                	srai	a1,a1,0x4
    80001a5a:	000ab783          	ld	a5,0(s5)
    80001a5e:	02f585b3          	mul	a1,a1,a5
    80001a62:	2585                	addiw	a1,a1,1
    80001a64:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a68:	4719                	li	a4,6
    80001a6a:	6685                	lui	a3,0x1
    80001a6c:	40b905b3          	sub	a1,s2,a1
    80001a70:	854e                	mv	a0,s3
    80001a72:	00000097          	auipc	ra,0x0
    80001a76:	864080e7          	jalr	-1948(ra) # 800012d6 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a7a:	19048493          	addi	s1,s1,400
    80001a7e:	fd4495e3          	bne	s1,s4,80001a48 <proc_mapstacks+0x38>
  }
}
    80001a82:	70e2                	ld	ra,56(sp)
    80001a84:	7442                	ld	s0,48(sp)
    80001a86:	74a2                	ld	s1,40(sp)
    80001a88:	7902                	ld	s2,32(sp)
    80001a8a:	69e2                	ld	s3,24(sp)
    80001a8c:	6a42                	ld	s4,16(sp)
    80001a8e:	6aa2                	ld	s5,8(sp)
    80001a90:	6b02                	ld	s6,0(sp)
    80001a92:	6121                	addi	sp,sp,64
    80001a94:	8082                	ret
      panic("kalloc");
    80001a96:	00006517          	auipc	a0,0x6
    80001a9a:	76250513          	addi	a0,a0,1890 # 800081f8 <digits+0x1b8>
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	aa2080e7          	jalr	-1374(ra) # 80000540 <panic>

0000000080001aa6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001aa6:	7139                	addi	sp,sp,-64
    80001aa8:	fc06                	sd	ra,56(sp)
    80001aaa:	f822                	sd	s0,48(sp)
    80001aac:	f426                	sd	s1,40(sp)
    80001aae:	f04a                	sd	s2,32(sp)
    80001ab0:	ec4e                	sd	s3,24(sp)
    80001ab2:	e852                	sd	s4,16(sp)
    80001ab4:	e456                	sd	s5,8(sp)
    80001ab6:	e05a                	sd	s6,0(sp)
    80001ab8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001aba:	00006597          	auipc	a1,0x6
    80001abe:	74658593          	addi	a1,a1,1862 # 80008200 <digits+0x1c0>
    80001ac2:	0022f517          	auipc	a0,0x22f
    80001ac6:	10650513          	addi	a0,a0,262 # 80230bc8 <pid_lock>
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	214080e7          	jalr	532(ra) # 80000cde <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ad2:	00006597          	auipc	a1,0x6
    80001ad6:	73658593          	addi	a1,a1,1846 # 80008208 <digits+0x1c8>
    80001ada:	0022f517          	auipc	a0,0x22f
    80001ade:	10650513          	addi	a0,a0,262 # 80230be0 <wait_lock>
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	1fc080e7          	jalr	508(ra) # 80000cde <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001aea:	0022f497          	auipc	s1,0x22f
    80001aee:	50e48493          	addi	s1,s1,1294 # 80230ff8 <proc>
  {
    initlock(&p->lock, "proc");
    80001af2:	00006b17          	auipc	s6,0x6
    80001af6:	726b0b13          	addi	s6,s6,1830 # 80008218 <digits+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001afa:	8aa6                	mv	s5,s1
    80001afc:	00006a17          	auipc	s4,0x6
    80001b00:	504a0a13          	addi	s4,s4,1284 # 80008000 <etext>
    80001b04:	04000937          	lui	s2,0x4000
    80001b08:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b0a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b0c:	00236997          	auipc	s3,0x236
    80001b10:	8ec98993          	addi	s3,s3,-1812 # 802373f8 <tickslock>
    initlock(&p->lock, "proc");
    80001b14:	85da                	mv	a1,s6
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	1c6080e7          	jalr	454(ra) # 80000cde <initlock>
    p->state = UNUSED;
    80001b20:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b24:	415487b3          	sub	a5,s1,s5
    80001b28:	8791                	srai	a5,a5,0x4
    80001b2a:	000a3703          	ld	a4,0(s4)
    80001b2e:	02e787b3          	mul	a5,a5,a4
    80001b32:	2785                	addiw	a5,a5,1
    80001b34:	00d7979b          	slliw	a5,a5,0xd
    80001b38:	40f907b3          	sub	a5,s2,a5
    80001b3c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b3e:	19048493          	addi	s1,s1,400
    80001b42:	fd3499e3          	bne	s1,s3,80001b14 <procinit+0x6e>
  }
}
    80001b46:	70e2                	ld	ra,56(sp)
    80001b48:	7442                	ld	s0,48(sp)
    80001b4a:	74a2                	ld	s1,40(sp)
    80001b4c:	7902                	ld	s2,32(sp)
    80001b4e:	69e2                	ld	s3,24(sp)
    80001b50:	6a42                	ld	s4,16(sp)
    80001b52:	6aa2                	ld	s5,8(sp)
    80001b54:	6b02                	ld	s6,0(sp)
    80001b56:	6121                	addi	sp,sp,64
    80001b58:	8082                	ret

0000000080001b5a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b5a:	1141                	addi	sp,sp,-16
    80001b5c:	e422                	sd	s0,8(sp)
    80001b5e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b60:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b62:	2501                	sext.w	a0,a0
    80001b64:	6422                	ld	s0,8(sp)
    80001b66:	0141                	addi	sp,sp,16
    80001b68:	8082                	ret

0000000080001b6a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b6a:	1141                	addi	sp,sp,-16
    80001b6c:	e422                	sd	s0,8(sp)
    80001b6e:	0800                	addi	s0,sp,16
    80001b70:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b72:	2781                	sext.w	a5,a5
    80001b74:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b76:	0022f517          	auipc	a0,0x22f
    80001b7a:	08250513          	addi	a0,a0,130 # 80230bf8 <cpus>
    80001b7e:	953e                	add	a0,a0,a5
    80001b80:	6422                	ld	s0,8(sp)
    80001b82:	0141                	addi	sp,sp,16
    80001b84:	8082                	ret

0000000080001b86 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	1000                	addi	s0,sp,32
  push_off();
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	192080e7          	jalr	402(ra) # 80000d22 <push_off>
    80001b98:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b9a:	2781                	sext.w	a5,a5
    80001b9c:	079e                	slli	a5,a5,0x7
    80001b9e:	0022f717          	auipc	a4,0x22f
    80001ba2:	02a70713          	addi	a4,a4,42 # 80230bc8 <pid_lock>
    80001ba6:	97ba                	add	a5,a5,a4
    80001ba8:	7b84                	ld	s1,48(a5)
  pop_off();
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	218080e7          	jalr	536(ra) # 80000dc2 <pop_off>
  return p;
}
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6105                	addi	sp,sp,32
    80001bbc:	8082                	ret

0000000080001bbe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bbe:	1141                	addi	sp,sp,-16
    80001bc0:	e406                	sd	ra,8(sp)
    80001bc2:	e022                	sd	s0,0(sp)
    80001bc4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	fc0080e7          	jalr	-64(ra) # 80001b86 <myproc>
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	254080e7          	jalr	596(ra) # 80000e22 <release>

  if (first)
    80001bd6:	00007797          	auipc	a5,0x7
    80001bda:	cca7a783          	lw	a5,-822(a5) # 800088a0 <first.1>
    80001bde:	eb89                	bnez	a5,80001bf0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001be0:	00001097          	auipc	ra,0x1
    80001be4:	07c080e7          	jalr	124(ra) # 80002c5c <usertrapret>
}
    80001be8:	60a2                	ld	ra,8(sp)
    80001bea:	6402                	ld	s0,0(sp)
    80001bec:	0141                	addi	sp,sp,16
    80001bee:	8082                	ret
    first = 0;
    80001bf0:	00007797          	auipc	a5,0x7
    80001bf4:	ca07a823          	sw	zero,-848(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001bf8:	4505                	li	a0,1
    80001bfa:	00002097          	auipc	ra,0x2
    80001bfe:	f78080e7          	jalr	-136(ra) # 80003b72 <fsinit>
    80001c02:	bff9                	j	80001be0 <forkret+0x22>

0000000080001c04 <allocpid>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c10:	0022f917          	auipc	s2,0x22f
    80001c14:	fb890913          	addi	s2,s2,-72 # 80230bc8 <pid_lock>
    80001c18:	854a                	mv	a0,s2
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	154080e7          	jalr	340(ra) # 80000d6e <acquire>
  pid = nextpid;
    80001c22:	00007797          	auipc	a5,0x7
    80001c26:	c8278793          	addi	a5,a5,-894 # 800088a4 <nextpid>
    80001c2a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c2c:	0014871b          	addiw	a4,s1,1
    80001c30:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c32:	854a                	mv	a0,s2
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	1ee080e7          	jalr	494(ra) # 80000e22 <release>
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <proc_pagetable>:
{
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	e04a                	sd	s2,0(sp)
    80001c54:	1000                	addi	s0,sp,32
    80001c56:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	868080e7          	jalr	-1944(ra) # 800014c0 <uvmcreate>
    80001c60:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c62:	c121                	beqz	a0,80001ca2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c64:	4729                	li	a4,10
    80001c66:	00005697          	auipc	a3,0x5
    80001c6a:	39a68693          	addi	a3,a3,922 # 80007000 <_trampoline>
    80001c6e:	6605                	lui	a2,0x1
    80001c70:	040005b7          	lui	a1,0x4000
    80001c74:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c76:	05b2                	slli	a1,a1,0xc
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	5be080e7          	jalr	1470(ra) # 80001236 <mappages>
    80001c80:	02054863          	bltz	a0,80001cb0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c84:	4719                	li	a4,6
    80001c86:	05893683          	ld	a3,88(s2)
    80001c8a:	6605                	lui	a2,0x1
    80001c8c:	020005b7          	lui	a1,0x2000
    80001c90:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c92:	05b6                	slli	a1,a1,0xd
    80001c94:	8526                	mv	a0,s1
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	5a0080e7          	jalr	1440(ra) # 80001236 <mappages>
    80001c9e:	02054163          	bltz	a0,80001cc0 <proc_pagetable+0x76>
}
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6902                	ld	s2,0(sp)
    80001cac:	6105                	addi	sp,sp,32
    80001cae:	8082                	ret
    uvmfree(pagetable, 0);
    80001cb0:	4581                	li	a1,0
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	a12080e7          	jalr	-1518(ra) # 800016c6 <uvmfree>
    return 0;
    80001cbc:	4481                	li	s1,0
    80001cbe:	b7d5                	j	80001ca2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc0:	4681                	li	a3,0
    80001cc2:	4605                	li	a2,1
    80001cc4:	040005b7          	lui	a1,0x4000
    80001cc8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cca:	05b2                	slli	a1,a1,0xc
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	72e080e7          	jalr	1838(ra) # 800013fc <uvmunmap>
    uvmfree(pagetable, 0);
    80001cd6:	4581                	li	a1,0
    80001cd8:	8526                	mv	a0,s1
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	9ec080e7          	jalr	-1556(ra) # 800016c6 <uvmfree>
    return 0;
    80001ce2:	4481                	li	s1,0
    80001ce4:	bf7d                	j	80001ca2 <proc_pagetable+0x58>

0000000080001ce6 <proc_freepagetable>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	e04a                	sd	s2,0(sp)
    80001cf0:	1000                	addi	s0,sp,32
    80001cf2:	84aa                	mv	s1,a0
    80001cf4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf6:	4681                	li	a3,0
    80001cf8:	4605                	li	a2,1
    80001cfa:	040005b7          	lui	a1,0x4000
    80001cfe:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d00:	05b2                	slli	a1,a1,0xc
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	6fa080e7          	jalr	1786(ra) # 800013fc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d0a:	4681                	li	a3,0
    80001d0c:	4605                	li	a2,1
    80001d0e:	020005b7          	lui	a1,0x2000
    80001d12:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d14:	05b6                	slli	a1,a1,0xd
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	6e4080e7          	jalr	1764(ra) # 800013fc <uvmunmap>
  uvmfree(pagetable, sz);
    80001d20:	85ca                	mv	a1,s2
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	9a2080e7          	jalr	-1630(ra) # 800016c6 <uvmfree>
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <freeproc>:
{
    80001d38:	1101                	addi	sp,sp,-32
    80001d3a:	ec06                	sd	ra,24(sp)
    80001d3c:	e822                	sd	s0,16(sp)
    80001d3e:	e426                	sd	s1,8(sp)
    80001d40:	1000                	addi	s0,sp,32
    80001d42:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d44:	6d28                	ld	a0,88(a0)
    80001d46:	c509                	beqz	a0,80001d50 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	dc6080e7          	jalr	-570(ra) # 80000b0e <kfree>
  p->trapframe = 0;
    80001d50:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d54:	68a8                	ld	a0,80(s1)
    80001d56:	c511                	beqz	a0,80001d62 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d58:	64ac                	ld	a1,72(s1)
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	f8c080e7          	jalr	-116(ra) # 80001ce6 <proc_freepagetable>
  p->pagetable = 0;
    80001d62:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d66:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d6a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d6e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d72:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d76:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d7a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d7e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d82:	0004ac23          	sw	zero,24(s1)
}
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret

0000000080001d90 <allocproc>:
{
    80001d90:	1101                	addi	sp,sp,-32
    80001d92:	ec06                	sd	ra,24(sp)
    80001d94:	e822                	sd	s0,16(sp)
    80001d96:	e426                	sd	s1,8(sp)
    80001d98:	e04a                	sd	s2,0(sp)
    80001d9a:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d9c:	0022f497          	auipc	s1,0x22f
    80001da0:	25c48493          	addi	s1,s1,604 # 80230ff8 <proc>
    80001da4:	00235917          	auipc	s2,0x235
    80001da8:	65490913          	addi	s2,s2,1620 # 802373f8 <tickslock>
    acquire(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	fc0080e7          	jalr	-64(ra) # 80000d6e <acquire>
    if (p->state == UNUSED)
    80001db6:	4c9c                	lw	a5,24(s1)
    80001db8:	cf81                	beqz	a5,80001dd0 <allocproc+0x40>
      release(&p->lock);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	066080e7          	jalr	102(ra) # 80000e22 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dc4:	19048493          	addi	s1,s1,400
    80001dc8:	ff2492e3          	bne	s1,s2,80001dac <allocproc+0x1c>
  return 0;
    80001dcc:	4481                	li	s1,0
    80001dce:	a061                	j	80001e56 <allocproc+0xc6>
  p->pid = allocpid();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e34080e7          	jalr	-460(ra) # 80001c04 <allocpid>
    80001dd8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dda:	4785                	li	a5,1
    80001ddc:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	e8c080e7          	jalr	-372(ra) # 80000c6a <kalloc>
    80001de6:	892a                	mv	s2,a0
    80001de8:	eca8                	sd	a0,88(s1)
    80001dea:	cd2d                	beqz	a0,80001e64 <allocproc+0xd4>
  p->pagetable = proc_pagetable(p);
    80001dec:	8526                	mv	a0,s1
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e5c080e7          	jalr	-420(ra) # 80001c4a <proc_pagetable>
    80001df6:	892a                	mv	s2,a0
    80001df8:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001dfa:	c149                	beqz	a0,80001e7c <allocproc+0xec>
  memset(&p->context, 0, sizeof(p->context));
    80001dfc:	07000613          	li	a2,112
    80001e00:	4581                	li	a1,0
    80001e02:	06048513          	addi	a0,s1,96
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	064080e7          	jalr	100(ra) # 80000e6a <memset>
  p->context.ra = (uint64)forkret;
    80001e0e:	00000797          	auipc	a5,0x0
    80001e12:	db078793          	addi	a5,a5,-592 # 80001bbe <forkret>
    80001e16:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e18:	60bc                	ld	a5,64(s1)
    80001e1a:	6705                	lui	a4,0x1
    80001e1c:	97ba                	add	a5,a5,a4
    80001e1e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e20:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e24:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e28:	00007797          	auipc	a5,0x7
    80001e2c:	b187a783          	lw	a5,-1256(a5) # 80008940 <ticks>
    80001e30:	16f4a623          	sw	a5,364(s1)
  p->static_priority = 50;
    80001e34:	03200793          	li	a5,50
    80001e38:	16f4aa23          	sw	a5,372(s1)
  p->rbi = 25;
    80001e3c:	47e5                	li	a5,25
    80001e3e:	16f4ae23          	sw	a5,380(s1)
  p->dynamic_priority = 75;
    80001e42:	04b00793          	li	a5,75
    80001e46:	16f4ac23          	sw	a5,376(s1)
  p->sleep_time = 0;
    80001e4a:	1804a023          	sw	zero,384(s1)
  p->wait_time = 0;
    80001e4e:	1804a423          	sw	zero,392(s1)
  p->no_of_times_scheduled = 0;
    80001e52:	1804a623          	sw	zero,396(s1)
}
    80001e56:	8526                	mv	a0,s1
    80001e58:	60e2                	ld	ra,24(sp)
    80001e5a:	6442                	ld	s0,16(sp)
    80001e5c:	64a2                	ld	s1,8(sp)
    80001e5e:	6902                	ld	s2,0(sp)
    80001e60:	6105                	addi	sp,sp,32
    80001e62:	8082                	ret
    freeproc(p);
    80001e64:	8526                	mv	a0,s1
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	ed2080e7          	jalr	-302(ra) # 80001d38 <freeproc>
    release(&p->lock);
    80001e6e:	8526                	mv	a0,s1
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	fb2080e7          	jalr	-78(ra) # 80000e22 <release>
    return 0;
    80001e78:	84ca                	mv	s1,s2
    80001e7a:	bff1                	j	80001e56 <allocproc+0xc6>
    freeproc(p);
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	00000097          	auipc	ra,0x0
    80001e82:	eba080e7          	jalr	-326(ra) # 80001d38 <freeproc>
    release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	f9a080e7          	jalr	-102(ra) # 80000e22 <release>
    return 0;
    80001e90:	84ca                	mv	s1,s2
    80001e92:	b7d1                	j	80001e56 <allocproc+0xc6>

0000000080001e94 <userinit>:
{
    80001e94:	1101                	addi	sp,sp,-32
    80001e96:	ec06                	sd	ra,24(sp)
    80001e98:	e822                	sd	s0,16(sp)
    80001e9a:	e426                	sd	s1,8(sp)
    80001e9c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	ef2080e7          	jalr	-270(ra) # 80001d90 <allocproc>
    80001ea6:	84aa                	mv	s1,a0
  initproc = p;
    80001ea8:	00007797          	auipc	a5,0x7
    80001eac:	a8a7b823          	sd	a0,-1392(a5) # 80008938 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eb0:	03400613          	li	a2,52
    80001eb4:	00007597          	auipc	a1,0x7
    80001eb8:	9fc58593          	addi	a1,a1,-1540 # 800088b0 <initcode>
    80001ebc:	6928                	ld	a0,80(a0)
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	630080e7          	jalr	1584(ra) # 800014ee <uvmfirst>
  p->sz = PGSIZE;
    80001ec6:	6785                	lui	a5,0x1
    80001ec8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001eca:	6cb8                	ld	a4,88(s1)
    80001ecc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ed0:	6cb8                	ld	a4,88(s1)
    80001ed2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ed4:	4641                	li	a2,16
    80001ed6:	00006597          	auipc	a1,0x6
    80001eda:	34a58593          	addi	a1,a1,842 # 80008220 <digits+0x1e0>
    80001ede:	15848513          	addi	a0,s1,344
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	0d2080e7          	jalr	210(ra) # 80000fb4 <safestrcpy>
  p->cwd = namei("/");
    80001eea:	00006517          	auipc	a0,0x6
    80001eee:	34650513          	addi	a0,a0,838 # 80008230 <digits+0x1f0>
    80001ef2:	00002097          	auipc	ra,0x2
    80001ef6:	6aa080e7          	jalr	1706(ra) # 8000459c <namei>
    80001efa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001efe:	478d                	li	a5,3
    80001f00:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	f1e080e7          	jalr	-226(ra) # 80000e22 <release>
}
    80001f0c:	60e2                	ld	ra,24(sp)
    80001f0e:	6442                	ld	s0,16(sp)
    80001f10:	64a2                	ld	s1,8(sp)
    80001f12:	6105                	addi	sp,sp,32
    80001f14:	8082                	ret

0000000080001f16 <growproc>:
{
    80001f16:	1101                	addi	sp,sp,-32
    80001f18:	ec06                	sd	ra,24(sp)
    80001f1a:	e822                	sd	s0,16(sp)
    80001f1c:	e426                	sd	s1,8(sp)
    80001f1e:	e04a                	sd	s2,0(sp)
    80001f20:	1000                	addi	s0,sp,32
    80001f22:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f24:	00000097          	auipc	ra,0x0
    80001f28:	c62080e7          	jalr	-926(ra) # 80001b86 <myproc>
    80001f2c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f2e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f30:	01204c63          	bgtz	s2,80001f48 <growproc+0x32>
  else if (n < 0)
    80001f34:	02094663          	bltz	s2,80001f60 <growproc+0x4a>
  p->sz = sz;
    80001f38:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f3a:	4501                	li	a0,0
}
    80001f3c:	60e2                	ld	ra,24(sp)
    80001f3e:	6442                	ld	s0,16(sp)
    80001f40:	64a2                	ld	s1,8(sp)
    80001f42:	6902                	ld	s2,0(sp)
    80001f44:	6105                	addi	sp,sp,32
    80001f46:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f48:	4691                	li	a3,4
    80001f4a:	00b90633          	add	a2,s2,a1
    80001f4e:	6928                	ld	a0,80(a0)
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	658080e7          	jalr	1624(ra) # 800015a8 <uvmalloc>
    80001f58:	85aa                	mv	a1,a0
    80001f5a:	fd79                	bnez	a0,80001f38 <growproc+0x22>
      return -1;
    80001f5c:	557d                	li	a0,-1
    80001f5e:	bff9                	j	80001f3c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f60:	00b90633          	add	a2,s2,a1
    80001f64:	6928                	ld	a0,80(a0)
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	5fa080e7          	jalr	1530(ra) # 80001560 <uvmdealloc>
    80001f6e:	85aa                	mv	a1,a0
    80001f70:	b7e1                	j	80001f38 <growproc+0x22>

0000000080001f72 <fork>:
{
    80001f72:	7139                	addi	sp,sp,-64
    80001f74:	fc06                	sd	ra,56(sp)
    80001f76:	f822                	sd	s0,48(sp)
    80001f78:	f426                	sd	s1,40(sp)
    80001f7a:	f04a                	sd	s2,32(sp)
    80001f7c:	ec4e                	sd	s3,24(sp)
    80001f7e:	e852                	sd	s4,16(sp)
    80001f80:	e456                	sd	s5,8(sp)
    80001f82:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	c02080e7          	jalr	-1022(ra) # 80001b86 <myproc>
    80001f8c:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	e02080e7          	jalr	-510(ra) # 80001d90 <allocproc>
    80001f96:	10050c63          	beqz	a0,800020ae <fork+0x13c>
    80001f9a:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f9c:	048ab603          	ld	a2,72(s5)
    80001fa0:	692c                	ld	a1,80(a0)
    80001fa2:	050ab503          	ld	a0,80(s5)
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	75a080e7          	jalr	1882(ra) # 80001700 <uvmcopy>
    80001fae:	04054863          	bltz	a0,80001ffe <fork+0x8c>
  np->sz = p->sz;
    80001fb2:	048ab783          	ld	a5,72(s5)
    80001fb6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001fba:	058ab683          	ld	a3,88(s5)
    80001fbe:	87b6                	mv	a5,a3
    80001fc0:	058a3703          	ld	a4,88(s4)
    80001fc4:	12068693          	addi	a3,a3,288
    80001fc8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fcc:	6788                	ld	a0,8(a5)
    80001fce:	6b8c                	ld	a1,16(a5)
    80001fd0:	6f90                	ld	a2,24(a5)
    80001fd2:	01073023          	sd	a6,0(a4)
    80001fd6:	e708                	sd	a0,8(a4)
    80001fd8:	eb0c                	sd	a1,16(a4)
    80001fda:	ef10                	sd	a2,24(a4)
    80001fdc:	02078793          	addi	a5,a5,32
    80001fe0:	02070713          	addi	a4,a4,32
    80001fe4:	fed792e3          	bne	a5,a3,80001fc8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fe8:	058a3783          	ld	a5,88(s4)
    80001fec:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001ff0:	0d0a8493          	addi	s1,s5,208
    80001ff4:	0d0a0913          	addi	s2,s4,208
    80001ff8:	150a8993          	addi	s3,s5,336
    80001ffc:	a00d                	j	8000201e <fork+0xac>
    freeproc(np);
    80001ffe:	8552                	mv	a0,s4
    80002000:	00000097          	auipc	ra,0x0
    80002004:	d38080e7          	jalr	-712(ra) # 80001d38 <freeproc>
    release(&np->lock);
    80002008:	8552                	mv	a0,s4
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	e18080e7          	jalr	-488(ra) # 80000e22 <release>
    return -1;
    80002012:	597d                	li	s2,-1
    80002014:	a059                	j	8000209a <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80002016:	04a1                	addi	s1,s1,8
    80002018:	0921                	addi	s2,s2,8
    8000201a:	01348b63          	beq	s1,s3,80002030 <fork+0xbe>
    if (p->ofile[i])
    8000201e:	6088                	ld	a0,0(s1)
    80002020:	d97d                	beqz	a0,80002016 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002022:	00003097          	auipc	ra,0x3
    80002026:	c10080e7          	jalr	-1008(ra) # 80004c32 <filedup>
    8000202a:	00a93023          	sd	a0,0(s2)
    8000202e:	b7e5                	j	80002016 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002030:	150ab503          	ld	a0,336(s5)
    80002034:	00002097          	auipc	ra,0x2
    80002038:	d7e080e7          	jalr	-642(ra) # 80003db2 <idup>
    8000203c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002040:	4641                	li	a2,16
    80002042:	158a8593          	addi	a1,s5,344
    80002046:	158a0513          	addi	a0,s4,344
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	f6a080e7          	jalr	-150(ra) # 80000fb4 <safestrcpy>
  pid = np->pid;
    80002052:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002056:	8552                	mv	a0,s4
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	dca080e7          	jalr	-566(ra) # 80000e22 <release>
  acquire(&wait_lock);
    80002060:	0022f497          	auipc	s1,0x22f
    80002064:	b8048493          	addi	s1,s1,-1152 # 80230be0 <wait_lock>
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	d04080e7          	jalr	-764(ra) # 80000d6e <acquire>
  np->parent = p;
    80002072:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	daa080e7          	jalr	-598(ra) # 80000e22 <release>
  acquire(&np->lock);
    80002080:	8552                	mv	a0,s4
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	cec080e7          	jalr	-788(ra) # 80000d6e <acquire>
  np->state = RUNNABLE;
    8000208a:	478d                	li	a5,3
    8000208c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002090:	8552                	mv	a0,s4
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	d90080e7          	jalr	-624(ra) # 80000e22 <release>
}
    8000209a:	854a                	mv	a0,s2
    8000209c:	70e2                	ld	ra,56(sp)
    8000209e:	7442                	ld	s0,48(sp)
    800020a0:	74a2                	ld	s1,40(sp)
    800020a2:	7902                	ld	s2,32(sp)
    800020a4:	69e2                	ld	s3,24(sp)
    800020a6:	6a42                	ld	s4,16(sp)
    800020a8:	6aa2                	ld	s5,8(sp)
    800020aa:	6121                	addi	sp,sp,64
    800020ac:	8082                	ret
    return -1;
    800020ae:	597d                	li	s2,-1
    800020b0:	b7ed                	j	8000209a <fork+0x128>

00000000800020b2 <calculate_dp>:
{
    800020b2:	1141                	addi	sp,sp,-16
    800020b4:	e422                	sd	s0,8(sp)
    800020b6:	0800                	addi	s0,sp,16
  int a = 3 * p->run_time - p->sleep_time - p->wait_time;
    800020b8:	18452703          	lw	a4,388(a0)
    800020bc:	18052683          	lw	a3,384(a0)
    800020c0:	18852603          	lw	a2,392(a0)
    800020c4:	0017179b          	slliw	a5,a4,0x1
    800020c8:	9fb9                	addw	a5,a5,a4
    800020ca:	9f95                	subw	a5,a5,a3
    800020cc:	9f91                	subw	a5,a5,a2
  int c = (int)((a * 50) / b);
    800020ce:	03200593          	li	a1,50
    800020d2:	02b787bb          	mulw	a5,a5,a1
  int b = p->run_time + p->wait_time + p->sleep_time + 1;
    800020d6:	9f31                	addw	a4,a4,a2
    800020d8:	9f35                	addw	a4,a4,a3
    800020da:	2705                	addiw	a4,a4,1
  int c = (int)((a * 50) / b);
    800020dc:	02e7c7bb          	divw	a5,a5,a4
    800020e0:	0007871b          	sext.w	a4,a5
    800020e4:	fff74713          	not	a4,a4
    800020e8:	977d                	srai	a4,a4,0x3f
    800020ea:	8ff9                	and	a5,a5,a4
  p->rbi = rbi;
    800020ec:	16f52e23          	sw	a5,380(a0)
  if (p->static_priority + rbi <= 100)
    800020f0:	17452703          	lw	a4,372(a0)
    800020f4:	00e7853b          	addw	a0,a5,a4
  return dp;
    800020f8:	0005071b          	sext.w	a4,a0
    800020fc:	06400793          	li	a5,100
    80002100:	00e7d463          	bge	a5,a4,80002108 <calculate_dp+0x56>
    80002104:	06400513          	li	a0,100
}
    80002108:	2501                	sext.w	a0,a0
    8000210a:	6422                	ld	s0,8(sp)
    8000210c:	0141                	addi	sp,sp,16
    8000210e:	8082                	ret

0000000080002110 <scheduler>:
{
    80002110:	711d                	addi	sp,sp,-96
    80002112:	ec86                	sd	ra,88(sp)
    80002114:	e8a2                	sd	s0,80(sp)
    80002116:	e4a6                	sd	s1,72(sp)
    80002118:	e0ca                	sd	s2,64(sp)
    8000211a:	fc4e                	sd	s3,56(sp)
    8000211c:	f852                	sd	s4,48(sp)
    8000211e:	f456                	sd	s5,40(sp)
    80002120:	f05a                	sd	s6,32(sp)
    80002122:	ec5e                	sd	s7,24(sp)
    80002124:	e862                	sd	s8,16(sp)
    80002126:	e466                	sd	s9,8(sp)
    80002128:	e06a                	sd	s10,0(sp)
    8000212a:	1080                	addi	s0,sp,96
    8000212c:	8792                	mv	a5,tp
  int id = r_tp();
    8000212e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002130:	00779693          	slli	a3,a5,0x7
    80002134:	0022f717          	auipc	a4,0x22f
    80002138:	a9470713          	addi	a4,a4,-1388 # 80230bc8 <pid_lock>
    8000213c:	9736                	add	a4,a4,a3
    8000213e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &chosen->context);
    80002142:	0022f717          	auipc	a4,0x22f
    80002146:	abe70713          	addi	a4,a4,-1346 # 80230c00 <cpus+0x8>
    8000214a:	00e68d33          	add	s10,a3,a4
    struct proc *chosen = 0;
    8000214e:	4c01                	li	s8,0
      if (p->state == RUNNABLE)
    80002150:	4b0d                	li	s6,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002152:	00235b97          	auipc	s7,0x235
    80002156:	2a6b8b93          	addi	s7,s7,678 # 802373f8 <tickslock>
        c->proc = chosen;
    8000215a:	0022fc97          	auipc	s9,0x22f
    8000215e:	a6ec8c93          	addi	s9,s9,-1426 # 80230bc8 <pid_lock>
    80002162:	9cb6                	add	s9,s9,a3
    80002164:	a8c5                	j	80002254 <scheduler+0x144>
        if (chosen == 0)
    80002166:	0a0a8763          	beqz	s5,80002214 <scheduler+0x104>
          acquire(&chosen->lock);
    8000216a:	8556                	mv	a0,s5
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	c02080e7          	jalr	-1022(ra) # 80000d6e <acquire>
          int dp_of_chosen = calculate_dp(chosen);
    80002174:	8556                	mv	a0,s5
    80002176:	00000097          	auipc	ra,0x0
    8000217a:	f3c080e7          	jalr	-196(ra) # 800020b2 <calculate_dp>
          chosen->dynamic_priority = dp_of_chosen;
    8000217e:	16aaac23          	sw	a0,376(s5)
          release(&chosen->lock);
    80002182:	8556                	mv	a0,s5
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	c9e080e7          	jalr	-866(ra) # 80000e22 <release>
          int dp_of_p = calculate_dp(p);
    8000218c:	8526                	mv	a0,s1
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	f24080e7          	jalr	-220(ra) # 800020b2 <calculate_dp>
          p->dynamic_priority = dp_of_p;
    80002196:	fea92423          	sw	a0,-24(s2)
          if (chosen->dynamic_priority > p->dynamic_priority)
    8000219a:	178aa783          	lw	a5,376(s5)
    8000219e:	0cf54b63          	blt	a0,a5,80002274 <scheduler+0x164>
          else if (chosen->dynamic_priority == p->dynamic_priority)
    800021a2:	06a79a63          	bne	a5,a0,80002216 <scheduler+0x106>
            if (chosen->no_of_times_scheduled > p->no_of_times_scheduled)
    800021a6:	18caa703          	lw	a4,396(s5)
    800021aa:	ffc92783          	lw	a5,-4(s2)
    800021ae:	0ce7c563          	blt	a5,a4,80002278 <scheduler+0x168>
            else if (chosen->no_of_times_scheduled == p->no_of_times_scheduled)
    800021b2:	06f71263          	bne	a4,a5,80002216 <scheduler+0x106>
              if (chosen->ctime > p->ctime)
    800021b6:	16caa703          	lw	a4,364(s5)
    800021ba:	fdc92783          	lw	a5,-36(s2)
    800021be:	04e7fc63          	bgeu	a5,a4,80002216 <scheduler+0x106>
    800021c2:	8aa6                	mv	s5,s1
    800021c4:	a889                	j	80002216 <scheduler+0x106>
      acquire(&chosen->lock);
    800021c6:	84d6                	mv	s1,s5
    800021c8:	8556                	mv	a0,s5
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ba4080e7          	jalr	-1116(ra) # 80000d6e <acquire>
      if (chosen->state == RUNNABLE)
    800021d2:	018aa783          	lw	a5,24(s5)
    800021d6:	03679963          	bne	a5,s6,80002208 <scheduler+0xf8>
        chosen->state = RUNNING;
    800021da:	4791                	li	a5,4
    800021dc:	00faac23          	sw	a5,24(s5)
        chosen->no_of_times_scheduled++;
    800021e0:	18caa783          	lw	a5,396(s5)
    800021e4:	2785                	addiw	a5,a5,1
    800021e6:	18faa623          	sw	a5,396(s5)
        chosen->run_time = 0;
    800021ea:	180aa223          	sw	zero,388(s5)
        chosen->sleep_time = 0;
    800021ee:	180aa023          	sw	zero,384(s5)
        c->proc = chosen;
    800021f2:	035cb823          	sd	s5,48(s9)
        swtch(&c->context, &chosen->context);
    800021f6:	060a8593          	addi	a1,s5,96
    800021fa:	856a                	mv	a0,s10
    800021fc:	00001097          	auipc	ra,0x1
    80002200:	8f4080e7          	jalr	-1804(ra) # 80002af0 <swtch>
        c->proc = 0;
    80002204:	020cb823          	sd	zero,48(s9)
      release(&chosen->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	c18080e7          	jalr	-1000(ra) # 80000e22 <release>
    80002212:	a089                	j	80002254 <scheduler+0x144>
    80002214:	8aa6                	mv	s5,s1
      release(&p->lock);
    80002216:	8552                	mv	a0,s4
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	c0a080e7          	jalr	-1014(ra) # 80000e22 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002220:	fb79f3e3          	bgeu	s3,s7,800021c6 <scheduler+0xb6>
    80002224:	19048493          	addi	s1,s1,400
    80002228:	19090913          	addi	s2,s2,400
    8000222c:	8a26                	mv	s4,s1
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	b3e080e7          	jalr	-1218(ra) # 80000d6e <acquire>
      if (p->state == RUNNABLE)
    80002238:	89ca                	mv	s3,s2
    8000223a:	e8892783          	lw	a5,-376(s2)
    8000223e:	f36784e3          	beq	a5,s6,80002166 <scheduler+0x56>
      release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	bde080e7          	jalr	-1058(ra) # 80000e22 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000224c:	fd796ce3          	bltu	s2,s7,80002224 <scheduler+0x114>
    if (chosen != 0)
    80002250:	f60a9be3          	bnez	s5,800021c6 <scheduler+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002254:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002258:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000225c:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002260:	0022f497          	auipc	s1,0x22f
    80002264:	d9848493          	addi	s1,s1,-616 # 80230ff8 <proc>
    80002268:	0022f917          	auipc	s2,0x22f
    8000226c:	f2090913          	addi	s2,s2,-224 # 80231188 <proc+0x190>
    struct proc *chosen = 0;
    80002270:	8ae2                	mv	s5,s8
    80002272:	bf6d                	j	8000222c <scheduler+0x11c>
    80002274:	8aa6                	mv	s5,s1
    80002276:	b745                	j	80002216 <scheduler+0x106>
    80002278:	8aa6                	mv	s5,s1
    8000227a:	bf71                	j	80002216 <scheduler+0x106>

000000008000227c <sched>:
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000228a:	00000097          	auipc	ra,0x0
    8000228e:	8fc080e7          	jalr	-1796(ra) # 80001b86 <myproc>
    80002292:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	a60080e7          	jalr	-1440(ra) # 80000cf4 <holding>
    8000229c:	c93d                	beqz	a0,80002312 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022a0:	2781                	sext.w	a5,a5
    800022a2:	079e                	slli	a5,a5,0x7
    800022a4:	0022f717          	auipc	a4,0x22f
    800022a8:	92470713          	addi	a4,a4,-1756 # 80230bc8 <pid_lock>
    800022ac:	97ba                	add	a5,a5,a4
    800022ae:	0a87a703          	lw	a4,168(a5)
    800022b2:	4785                	li	a5,1
    800022b4:	06f71763          	bne	a4,a5,80002322 <sched+0xa6>
  if (p->state == RUNNING)
    800022b8:	4c98                	lw	a4,24(s1)
    800022ba:	4791                	li	a5,4
    800022bc:	06f70b63          	beq	a4,a5,80002332 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022c4:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022c6:	efb5                	bnez	a5,80002342 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022ca:	0022f917          	auipc	s2,0x22f
    800022ce:	8fe90913          	addi	s2,s2,-1794 # 80230bc8 <pid_lock>
    800022d2:	2781                	sext.w	a5,a5
    800022d4:	079e                	slli	a5,a5,0x7
    800022d6:	97ca                	add	a5,a5,s2
    800022d8:	0ac7a983          	lw	s3,172(a5)
    800022dc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022de:	2781                	sext.w	a5,a5
    800022e0:	079e                	slli	a5,a5,0x7
    800022e2:	0022f597          	auipc	a1,0x22f
    800022e6:	91e58593          	addi	a1,a1,-1762 # 80230c00 <cpus+0x8>
    800022ea:	95be                	add	a1,a1,a5
    800022ec:	06048513          	addi	a0,s1,96
    800022f0:	00001097          	auipc	ra,0x1
    800022f4:	800080e7          	jalr	-2048(ra) # 80002af0 <swtch>
    800022f8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022fa:	2781                	sext.w	a5,a5
    800022fc:	079e                	slli	a5,a5,0x7
    800022fe:	993e                	add	s2,s2,a5
    80002300:	0b392623          	sw	s3,172(s2)
}
    80002304:	70a2                	ld	ra,40(sp)
    80002306:	7402                	ld	s0,32(sp)
    80002308:	64e2                	ld	s1,24(sp)
    8000230a:	6942                	ld	s2,16(sp)
    8000230c:	69a2                	ld	s3,8(sp)
    8000230e:	6145                	addi	sp,sp,48
    80002310:	8082                	ret
    panic("sched p->lock");
    80002312:	00006517          	auipc	a0,0x6
    80002316:	f2650513          	addi	a0,a0,-218 # 80008238 <digits+0x1f8>
    8000231a:	ffffe097          	auipc	ra,0xffffe
    8000231e:	226080e7          	jalr	550(ra) # 80000540 <panic>
    panic("sched locks");
    80002322:	00006517          	auipc	a0,0x6
    80002326:	f2650513          	addi	a0,a0,-218 # 80008248 <digits+0x208>
    8000232a:	ffffe097          	auipc	ra,0xffffe
    8000232e:	216080e7          	jalr	534(ra) # 80000540 <panic>
    panic("sched running");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f2650513          	addi	a0,a0,-218 # 80008258 <digits+0x218>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	206080e7          	jalr	518(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002342:	00006517          	auipc	a0,0x6
    80002346:	f2650513          	addi	a0,a0,-218 # 80008268 <digits+0x228>
    8000234a:	ffffe097          	auipc	ra,0xffffe
    8000234e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>

0000000080002352 <yield>:
{
    80002352:	1101                	addi	sp,sp,-32
    80002354:	ec06                	sd	ra,24(sp)
    80002356:	e822                	sd	s0,16(sp)
    80002358:	e426                	sd	s1,8(sp)
    8000235a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	82a080e7          	jalr	-2006(ra) # 80001b86 <myproc>
    80002364:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	a08080e7          	jalr	-1528(ra) # 80000d6e <acquire>
  p->state = RUNNABLE;
    8000236e:	478d                	li	a5,3
    80002370:	cc9c                	sw	a5,24(s1)
  sched();
    80002372:	00000097          	auipc	ra,0x0
    80002376:	f0a080e7          	jalr	-246(ra) # 8000227c <sched>
  release(&p->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	aa6080e7          	jalr	-1370(ra) # 80000e22 <release>
}
    80002384:	60e2                	ld	ra,24(sp)
    80002386:	6442                	ld	s0,16(sp)
    80002388:	64a2                	ld	s1,8(sp)
    8000238a:	6105                	addi	sp,sp,32
    8000238c:	8082                	ret

000000008000238e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000238e:	7179                	addi	sp,sp,-48
    80002390:	f406                	sd	ra,40(sp)
    80002392:	f022                	sd	s0,32(sp)
    80002394:	ec26                	sd	s1,24(sp)
    80002396:	e84a                	sd	s2,16(sp)
    80002398:	e44e                	sd	s3,8(sp)
    8000239a:	1800                	addi	s0,sp,48
    8000239c:	89aa                	mv	s3,a0
    8000239e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	7e6080e7          	jalr	2022(ra) # 80001b86 <myproc>
    800023a8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	9c4080e7          	jalr	-1596(ra) # 80000d6e <acquire>
  release(lk);
    800023b2:	854a                	mv	a0,s2
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	a6e080e7          	jalr	-1426(ra) # 80000e22 <release>

  // Go to sleep.
  p->chan = chan;
    800023bc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023c0:	4789                	li	a5,2
    800023c2:	cc9c                	sw	a5,24(s1)

  sched();
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	eb8080e7          	jalr	-328(ra) # 8000227c <sched>

  // Tidy up.
  p->chan = 0;
    800023cc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	a50080e7          	jalr	-1456(ra) # 80000e22 <release>
  acquire(lk);
    800023da:	854a                	mv	a0,s2
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	992080e7          	jalr	-1646(ra) # 80000d6e <acquire>
}
    800023e4:	70a2                	ld	ra,40(sp)
    800023e6:	7402                	ld	s0,32(sp)
    800023e8:	64e2                	ld	s1,24(sp)
    800023ea:	6942                	ld	s2,16(sp)
    800023ec:	69a2                	ld	s3,8(sp)
    800023ee:	6145                	addi	sp,sp,48
    800023f0:	8082                	ret

00000000800023f2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023f2:	7139                	addi	sp,sp,-64
    800023f4:	fc06                	sd	ra,56(sp)
    800023f6:	f822                	sd	s0,48(sp)
    800023f8:	f426                	sd	s1,40(sp)
    800023fa:	f04a                	sd	s2,32(sp)
    800023fc:	ec4e                	sd	s3,24(sp)
    800023fe:	e852                	sd	s4,16(sp)
    80002400:	e456                	sd	s5,8(sp)
    80002402:	0080                	addi	s0,sp,64
    80002404:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002406:	0022f497          	auipc	s1,0x22f
    8000240a:	bf248493          	addi	s1,s1,-1038 # 80230ff8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000240e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002410:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002412:	00235917          	auipc	s2,0x235
    80002416:	fe690913          	addi	s2,s2,-26 # 802373f8 <tickslock>
    8000241a:	a811                	j	8000242e <wakeup+0x3c>
      }
      release(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	a04080e7          	jalr	-1532(ra) # 80000e22 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002426:	19048493          	addi	s1,s1,400
    8000242a:	03248663          	beq	s1,s2,80002456 <wakeup+0x64>
    if (p != myproc())
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	758080e7          	jalr	1880(ra) # 80001b86 <myproc>
    80002436:	fea488e3          	beq	s1,a0,80002426 <wakeup+0x34>
      acquire(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	932080e7          	jalr	-1742(ra) # 80000d6e <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002444:	4c9c                	lw	a5,24(s1)
    80002446:	fd379be3          	bne	a5,s3,8000241c <wakeup+0x2a>
    8000244a:	709c                	ld	a5,32(s1)
    8000244c:	fd4798e3          	bne	a5,s4,8000241c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002450:	0154ac23          	sw	s5,24(s1)
    80002454:	b7e1                	j	8000241c <wakeup+0x2a>
    }
  }
}
    80002456:	70e2                	ld	ra,56(sp)
    80002458:	7442                	ld	s0,48(sp)
    8000245a:	74a2                	ld	s1,40(sp)
    8000245c:	7902                	ld	s2,32(sp)
    8000245e:	69e2                	ld	s3,24(sp)
    80002460:	6a42                	ld	s4,16(sp)
    80002462:	6aa2                	ld	s5,8(sp)
    80002464:	6121                	addi	sp,sp,64
    80002466:	8082                	ret

0000000080002468 <reparent>:
{
    80002468:	7179                	addi	sp,sp,-48
    8000246a:	f406                	sd	ra,40(sp)
    8000246c:	f022                	sd	s0,32(sp)
    8000246e:	ec26                	sd	s1,24(sp)
    80002470:	e84a                	sd	s2,16(sp)
    80002472:	e44e                	sd	s3,8(sp)
    80002474:	e052                	sd	s4,0(sp)
    80002476:	1800                	addi	s0,sp,48
    80002478:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000247a:	0022f497          	auipc	s1,0x22f
    8000247e:	b7e48493          	addi	s1,s1,-1154 # 80230ff8 <proc>
      pp->parent = initproc;
    80002482:	00006a17          	auipc	s4,0x6
    80002486:	4b6a0a13          	addi	s4,s4,1206 # 80008938 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000248a:	00235997          	auipc	s3,0x235
    8000248e:	f6e98993          	addi	s3,s3,-146 # 802373f8 <tickslock>
    80002492:	a029                	j	8000249c <reparent+0x34>
    80002494:	19048493          	addi	s1,s1,400
    80002498:	01348d63          	beq	s1,s3,800024b2 <reparent+0x4a>
    if (pp->parent == p)
    8000249c:	7c9c                	ld	a5,56(s1)
    8000249e:	ff279be3          	bne	a5,s2,80002494 <reparent+0x2c>
      pp->parent = initproc;
    800024a2:	000a3503          	ld	a0,0(s4)
    800024a6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024a8:	00000097          	auipc	ra,0x0
    800024ac:	f4a080e7          	jalr	-182(ra) # 800023f2 <wakeup>
    800024b0:	b7d5                	j	80002494 <reparent+0x2c>
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6a02                	ld	s4,0(sp)
    800024be:	6145                	addi	sp,sp,48
    800024c0:	8082                	ret

00000000800024c2 <exit>:
{
    800024c2:	7179                	addi	sp,sp,-48
    800024c4:	f406                	sd	ra,40(sp)
    800024c6:	f022                	sd	s0,32(sp)
    800024c8:	ec26                	sd	s1,24(sp)
    800024ca:	e84a                	sd	s2,16(sp)
    800024cc:	e44e                	sd	s3,8(sp)
    800024ce:	e052                	sd	s4,0(sp)
    800024d0:	1800                	addi	s0,sp,48
    800024d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	6b2080e7          	jalr	1714(ra) # 80001b86 <myproc>
    800024dc:	89aa                	mv	s3,a0
  if (p == initproc)
    800024de:	00006797          	auipc	a5,0x6
    800024e2:	45a7b783          	ld	a5,1114(a5) # 80008938 <initproc>
    800024e6:	0d050493          	addi	s1,a0,208
    800024ea:	15050913          	addi	s2,a0,336
    800024ee:	02a79363          	bne	a5,a0,80002514 <exit+0x52>
    panic("init exiting");
    800024f2:	00006517          	auipc	a0,0x6
    800024f6:	d8e50513          	addi	a0,a0,-626 # 80008280 <digits+0x240>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	046080e7          	jalr	70(ra) # 80000540 <panic>
      fileclose(f);
    80002502:	00002097          	auipc	ra,0x2
    80002506:	782080e7          	jalr	1922(ra) # 80004c84 <fileclose>
      p->ofile[fd] = 0;
    8000250a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000250e:	04a1                	addi	s1,s1,8
    80002510:	01248563          	beq	s1,s2,8000251a <exit+0x58>
    if (p->ofile[fd])
    80002514:	6088                	ld	a0,0(s1)
    80002516:	f575                	bnez	a0,80002502 <exit+0x40>
    80002518:	bfdd                	j	8000250e <exit+0x4c>
  begin_op();
    8000251a:	00002097          	auipc	ra,0x2
    8000251e:	2a2080e7          	jalr	674(ra) # 800047bc <begin_op>
  iput(p->cwd);
    80002522:	1509b503          	ld	a0,336(s3)
    80002526:	00002097          	auipc	ra,0x2
    8000252a:	a84080e7          	jalr	-1404(ra) # 80003faa <iput>
  end_op();
    8000252e:	00002097          	auipc	ra,0x2
    80002532:	30c080e7          	jalr	780(ra) # 8000483a <end_op>
  p->cwd = 0;
    80002536:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000253a:	0022e497          	auipc	s1,0x22e
    8000253e:	6a648493          	addi	s1,s1,1702 # 80230be0 <wait_lock>
    80002542:	8526                	mv	a0,s1
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	82a080e7          	jalr	-2006(ra) # 80000d6e <acquire>
  reparent(p);
    8000254c:	854e                	mv	a0,s3
    8000254e:	00000097          	auipc	ra,0x0
    80002552:	f1a080e7          	jalr	-230(ra) # 80002468 <reparent>
  wakeup(p->parent);
    80002556:	0389b503          	ld	a0,56(s3)
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	e98080e7          	jalr	-360(ra) # 800023f2 <wakeup>
  acquire(&p->lock);
    80002562:	854e                	mv	a0,s3
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	80a080e7          	jalr	-2038(ra) # 80000d6e <acquire>
  p->xstate = status;
    8000256c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002570:	4795                	li	a5,5
    80002572:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002576:	00006797          	auipc	a5,0x6
    8000257a:	3ca7a783          	lw	a5,970(a5) # 80008940 <ticks>
    8000257e:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002582:	8526                	mv	a0,s1
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	89e080e7          	jalr	-1890(ra) # 80000e22 <release>
  sched();
    8000258c:	00000097          	auipc	ra,0x0
    80002590:	cf0080e7          	jalr	-784(ra) # 8000227c <sched>
  panic("zombie exit");
    80002594:	00006517          	auipc	a0,0x6
    80002598:	cfc50513          	addi	a0,a0,-772 # 80008290 <digits+0x250>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fa4080e7          	jalr	-92(ra) # 80000540 <panic>

00000000800025a4 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025a4:	7179                	addi	sp,sp,-48
    800025a6:	f406                	sd	ra,40(sp)
    800025a8:	f022                	sd	s0,32(sp)
    800025aa:	ec26                	sd	s1,24(sp)
    800025ac:	e84a                	sd	s2,16(sp)
    800025ae:	e44e                	sd	s3,8(sp)
    800025b0:	1800                	addi	s0,sp,48
    800025b2:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025b4:	0022f497          	auipc	s1,0x22f
    800025b8:	a4448493          	addi	s1,s1,-1468 # 80230ff8 <proc>
    800025bc:	00235997          	auipc	s3,0x235
    800025c0:	e3c98993          	addi	s3,s3,-452 # 802373f8 <tickslock>
  {
    acquire(&p->lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	7a8080e7          	jalr	1960(ra) # 80000d6e <acquire>
    if (p->pid == pid)
    800025ce:	589c                	lw	a5,48(s1)
    800025d0:	01278d63          	beq	a5,s2,800025ea <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	84c080e7          	jalr	-1972(ra) # 80000e22 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025de:	19048493          	addi	s1,s1,400
    800025e2:	ff3491e3          	bne	s1,s3,800025c4 <kill+0x20>
  }
  return -1;
    800025e6:	557d                	li	a0,-1
    800025e8:	a829                	j	80002602 <kill+0x5e>
      p->killed = 1;
    800025ea:	4785                	li	a5,1
    800025ec:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025ee:	4c98                	lw	a4,24(s1)
    800025f0:	4789                	li	a5,2
    800025f2:	00f70f63          	beq	a4,a5,80002610 <kill+0x6c>
      release(&p->lock);
    800025f6:	8526                	mv	a0,s1
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	82a080e7          	jalr	-2006(ra) # 80000e22 <release>
      return 0;
    80002600:	4501                	li	a0,0
}
    80002602:	70a2                	ld	ra,40(sp)
    80002604:	7402                	ld	s0,32(sp)
    80002606:	64e2                	ld	s1,24(sp)
    80002608:	6942                	ld	s2,16(sp)
    8000260a:	69a2                	ld	s3,8(sp)
    8000260c:	6145                	addi	sp,sp,48
    8000260e:	8082                	ret
        p->state = RUNNABLE;
    80002610:	478d                	li	a5,3
    80002612:	cc9c                	sw	a5,24(s1)
    80002614:	b7cd                	j	800025f6 <kill+0x52>

0000000080002616 <setkilled>:

void setkilled(struct proc *p)
{
    80002616:	1101                	addi	sp,sp,-32
    80002618:	ec06                	sd	ra,24(sp)
    8000261a:	e822                	sd	s0,16(sp)
    8000261c:	e426                	sd	s1,8(sp)
    8000261e:	1000                	addi	s0,sp,32
    80002620:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	74c080e7          	jalr	1868(ra) # 80000d6e <acquire>
  p->killed = 1;
    8000262a:	4785                	li	a5,1
    8000262c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	7f2080e7          	jalr	2034(ra) # 80000e22 <release>
}
    80002638:	60e2                	ld	ra,24(sp)
    8000263a:	6442                	ld	s0,16(sp)
    8000263c:	64a2                	ld	s1,8(sp)
    8000263e:	6105                	addi	sp,sp,32
    80002640:	8082                	ret

0000000080002642 <killed>:

int killed(struct proc *p)
{
    80002642:	1101                	addi	sp,sp,-32
    80002644:	ec06                	sd	ra,24(sp)
    80002646:	e822                	sd	s0,16(sp)
    80002648:	e426                	sd	s1,8(sp)
    8000264a:	e04a                	sd	s2,0(sp)
    8000264c:	1000                	addi	s0,sp,32
    8000264e:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	71e080e7          	jalr	1822(ra) # 80000d6e <acquire>
  k = p->killed;
    80002658:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000265c:	8526                	mv	a0,s1
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	7c4080e7          	jalr	1988(ra) # 80000e22 <release>
  return k;
}
    80002666:	854a                	mv	a0,s2
    80002668:	60e2                	ld	ra,24(sp)
    8000266a:	6442                	ld	s0,16(sp)
    8000266c:	64a2                	ld	s1,8(sp)
    8000266e:	6902                	ld	s2,0(sp)
    80002670:	6105                	addi	sp,sp,32
    80002672:	8082                	ret

0000000080002674 <wait>:
{
    80002674:	715d                	addi	sp,sp,-80
    80002676:	e486                	sd	ra,72(sp)
    80002678:	e0a2                	sd	s0,64(sp)
    8000267a:	fc26                	sd	s1,56(sp)
    8000267c:	f84a                	sd	s2,48(sp)
    8000267e:	f44e                	sd	s3,40(sp)
    80002680:	f052                	sd	s4,32(sp)
    80002682:	ec56                	sd	s5,24(sp)
    80002684:	e85a                	sd	s6,16(sp)
    80002686:	e45e                	sd	s7,8(sp)
    80002688:	e062                	sd	s8,0(sp)
    8000268a:	0880                	addi	s0,sp,80
    8000268c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000268e:	fffff097          	auipc	ra,0xfffff
    80002692:	4f8080e7          	jalr	1272(ra) # 80001b86 <myproc>
    80002696:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002698:	0022e517          	auipc	a0,0x22e
    8000269c:	54850513          	addi	a0,a0,1352 # 80230be0 <wait_lock>
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	6ce080e7          	jalr	1742(ra) # 80000d6e <acquire>
    havekids = 0;
    800026a8:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026aa:	4a15                	li	s4,5
        havekids = 1;
    800026ac:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026ae:	00235997          	auipc	s3,0x235
    800026b2:	d4a98993          	addi	s3,s3,-694 # 802373f8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026b6:	0022ec17          	auipc	s8,0x22e
    800026ba:	52ac0c13          	addi	s8,s8,1322 # 80230be0 <wait_lock>
    havekids = 0;
    800026be:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026c0:	0022f497          	auipc	s1,0x22f
    800026c4:	93848493          	addi	s1,s1,-1736 # 80230ff8 <proc>
    800026c8:	a0bd                	j	80002736 <wait+0xc2>
          pid = pp->pid;
    800026ca:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026ce:	000b0e63          	beqz	s6,800026ea <wait+0x76>
    800026d2:	4691                	li	a3,4
    800026d4:	02c48613          	addi	a2,s1,44
    800026d8:	85da                	mv	a1,s6
    800026da:	05093503          	ld	a0,80(s2)
    800026de:	fffff097          	auipc	ra,0xfffff
    800026e2:	130080e7          	jalr	304(ra) # 8000180e <copyout>
    800026e6:	02054563          	bltz	a0,80002710 <wait+0x9c>
          freeproc(pp);
    800026ea:	8526                	mv	a0,s1
    800026ec:	fffff097          	auipc	ra,0xfffff
    800026f0:	64c080e7          	jalr	1612(ra) # 80001d38 <freeproc>
          release(&pp->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	72c080e7          	jalr	1836(ra) # 80000e22 <release>
          release(&wait_lock);
    800026fe:	0022e517          	auipc	a0,0x22e
    80002702:	4e250513          	addi	a0,a0,1250 # 80230be0 <wait_lock>
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	71c080e7          	jalr	1820(ra) # 80000e22 <release>
          return pid;
    8000270e:	a0b5                	j	8000277a <wait+0x106>
            release(&pp->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	710080e7          	jalr	1808(ra) # 80000e22 <release>
            release(&wait_lock);
    8000271a:	0022e517          	auipc	a0,0x22e
    8000271e:	4c650513          	addi	a0,a0,1222 # 80230be0 <wait_lock>
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	700080e7          	jalr	1792(ra) # 80000e22 <release>
            return -1;
    8000272a:	59fd                	li	s3,-1
    8000272c:	a0b9                	j	8000277a <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000272e:	19048493          	addi	s1,s1,400
    80002732:	03348463          	beq	s1,s3,8000275a <wait+0xe6>
      if (pp->parent == p)
    80002736:	7c9c                	ld	a5,56(s1)
    80002738:	ff279be3          	bne	a5,s2,8000272e <wait+0xba>
        acquire(&pp->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	630080e7          	jalr	1584(ra) # 80000d6e <acquire>
        if (pp->state == ZOMBIE)
    80002746:	4c9c                	lw	a5,24(s1)
    80002748:	f94781e3          	beq	a5,s4,800026ca <wait+0x56>
        release(&pp->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	6d4080e7          	jalr	1748(ra) # 80000e22 <release>
        havekids = 1;
    80002756:	8756                	mv	a4,s5
    80002758:	bfd9                	j	8000272e <wait+0xba>
    if (!havekids || killed(p))
    8000275a:	c719                	beqz	a4,80002768 <wait+0xf4>
    8000275c:	854a                	mv	a0,s2
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	ee4080e7          	jalr	-284(ra) # 80002642 <killed>
    80002766:	c51d                	beqz	a0,80002794 <wait+0x120>
      release(&wait_lock);
    80002768:	0022e517          	auipc	a0,0x22e
    8000276c:	47850513          	addi	a0,a0,1144 # 80230be0 <wait_lock>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	6b2080e7          	jalr	1714(ra) # 80000e22 <release>
      return -1;
    80002778:	59fd                	li	s3,-1
}
    8000277a:	854e                	mv	a0,s3
    8000277c:	60a6                	ld	ra,72(sp)
    8000277e:	6406                	ld	s0,64(sp)
    80002780:	74e2                	ld	s1,56(sp)
    80002782:	7942                	ld	s2,48(sp)
    80002784:	79a2                	ld	s3,40(sp)
    80002786:	7a02                	ld	s4,32(sp)
    80002788:	6ae2                	ld	s5,24(sp)
    8000278a:	6b42                	ld	s6,16(sp)
    8000278c:	6ba2                	ld	s7,8(sp)
    8000278e:	6c02                	ld	s8,0(sp)
    80002790:	6161                	addi	sp,sp,80
    80002792:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002794:	85e2                	mv	a1,s8
    80002796:	854a                	mv	a0,s2
    80002798:	00000097          	auipc	ra,0x0
    8000279c:	bf6080e7          	jalr	-1034(ra) # 8000238e <sleep>
    havekids = 0;
    800027a0:	bf39                	j	800026be <wait+0x4a>

00000000800027a2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027a2:	7179                	addi	sp,sp,-48
    800027a4:	f406                	sd	ra,40(sp)
    800027a6:	f022                	sd	s0,32(sp)
    800027a8:	ec26                	sd	s1,24(sp)
    800027aa:	e84a                	sd	s2,16(sp)
    800027ac:	e44e                	sd	s3,8(sp)
    800027ae:	e052                	sd	s4,0(sp)
    800027b0:	1800                	addi	s0,sp,48
    800027b2:	84aa                	mv	s1,a0
    800027b4:	892e                	mv	s2,a1
    800027b6:	89b2                	mv	s3,a2
    800027b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	3cc080e7          	jalr	972(ra) # 80001b86 <myproc>
  if (user_dst)
    800027c2:	c08d                	beqz	s1,800027e4 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027c4:	86d2                	mv	a3,s4
    800027c6:	864e                	mv	a2,s3
    800027c8:	85ca                	mv	a1,s2
    800027ca:	6928                	ld	a0,80(a0)
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	042080e7          	jalr	66(ra) # 8000180e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027d4:	70a2                	ld	ra,40(sp)
    800027d6:	7402                	ld	s0,32(sp)
    800027d8:	64e2                	ld	s1,24(sp)
    800027da:	6942                	ld	s2,16(sp)
    800027dc:	69a2                	ld	s3,8(sp)
    800027de:	6a02                	ld	s4,0(sp)
    800027e0:	6145                	addi	sp,sp,48
    800027e2:	8082                	ret
    memmove((char *)dst, src, len);
    800027e4:	000a061b          	sext.w	a2,s4
    800027e8:	85ce                	mv	a1,s3
    800027ea:	854a                	mv	a0,s2
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	6da080e7          	jalr	1754(ra) # 80000ec6 <memmove>
    return 0;
    800027f4:	8526                	mv	a0,s1
    800027f6:	bff9                	j	800027d4 <either_copyout+0x32>

00000000800027f8 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f8:	7179                	addi	sp,sp,-48
    800027fa:	f406                	sd	ra,40(sp)
    800027fc:	f022                	sd	s0,32(sp)
    800027fe:	ec26                	sd	s1,24(sp)
    80002800:	e84a                	sd	s2,16(sp)
    80002802:	e44e                	sd	s3,8(sp)
    80002804:	e052                	sd	s4,0(sp)
    80002806:	1800                	addi	s0,sp,48
    80002808:	892a                	mv	s2,a0
    8000280a:	84ae                	mv	s1,a1
    8000280c:	89b2                	mv	s3,a2
    8000280e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	376080e7          	jalr	886(ra) # 80001b86 <myproc>
  if (user_src)
    80002818:	c08d                	beqz	s1,8000283a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000281a:	86d2                	mv	a3,s4
    8000281c:	864e                	mv	a2,s3
    8000281e:	85ca                	mv	a1,s2
    80002820:	6928                	ld	a0,80(a0)
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	0b0080e7          	jalr	176(ra) # 800018d2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000282a:	70a2                	ld	ra,40(sp)
    8000282c:	7402                	ld	s0,32(sp)
    8000282e:	64e2                	ld	s1,24(sp)
    80002830:	6942                	ld	s2,16(sp)
    80002832:	69a2                	ld	s3,8(sp)
    80002834:	6a02                	ld	s4,0(sp)
    80002836:	6145                	addi	sp,sp,48
    80002838:	8082                	ret
    memmove(dst, (char *)src, len);
    8000283a:	000a061b          	sext.w	a2,s4
    8000283e:	85ce                	mv	a1,s3
    80002840:	854a                	mv	a0,s2
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	684080e7          	jalr	1668(ra) # 80000ec6 <memmove>
    return 0;
    8000284a:	8526                	mv	a0,s1
    8000284c:	bff9                	j	8000282a <either_copyin+0x32>

000000008000284e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000284e:	715d                	addi	sp,sp,-80
    80002850:	e486                	sd	ra,72(sp)
    80002852:	e0a2                	sd	s0,64(sp)
    80002854:	fc26                	sd	s1,56(sp)
    80002856:	f84a                	sd	s2,48(sp)
    80002858:	f44e                	sd	s3,40(sp)
    8000285a:	f052                	sd	s4,32(sp)
    8000285c:	ec56                	sd	s5,24(sp)
    8000285e:	e85a                	sd	s6,16(sp)
    80002860:	e45e                	sd	s7,8(sp)
    80002862:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002864:	00006517          	auipc	a0,0x6
    80002868:	88450513          	addi	a0,a0,-1916 # 800080e8 <digits+0xa8>
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	d1e080e7          	jalr	-738(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002874:	0022f497          	auipc	s1,0x22f
    80002878:	8dc48493          	addi	s1,s1,-1828 # 80231150 <proc+0x158>
    8000287c:	00235917          	auipc	s2,0x235
    80002880:	cd490913          	addi	s2,s2,-812 # 80237550 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002884:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002886:	00006997          	auipc	s3,0x6
    8000288a:	a1a98993          	addi	s3,s3,-1510 # 800082a0 <digits+0x260>

    // printf("%d %d %d %d %s %s %d", p->pid, p->run_time, p->sleep_time, p->wait_time, state, p->name, calculate_dp(p));
    printf("%d %d %d %d %s %s", p->pid, p->run_time, p->sleep_time, p->wait_time, state, p->name);
    8000288e:	00006a97          	auipc	s5,0x6
    80002892:	a1aa8a93          	addi	s5,s5,-1510 # 800082a8 <digits+0x268>
    printf("\n");
    80002896:	00006a17          	auipc	s4,0x6
    8000289a:	852a0a13          	addi	s4,s4,-1966 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289e:	00006b97          	auipc	s7,0x6
    800028a2:	a52b8b93          	addi	s7,s7,-1454 # 800082f0 <states.0>
    800028a6:	a03d                	j	800028d4 <procdump+0x86>
    printf("%d %d %d %d %s %s", p->pid, p->run_time, p->sleep_time, p->wait_time, state, p->name);
    800028a8:	03082703          	lw	a4,48(a6)
    800028ac:	02882683          	lw	a3,40(a6)
    800028b0:	02c82603          	lw	a2,44(a6)
    800028b4:	ed882583          	lw	a1,-296(a6)
    800028b8:	8556                	mv	a0,s5
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	cd0080e7          	jalr	-816(ra) # 8000058a <printf>
    printf("\n");
    800028c2:	8552                	mv	a0,s4
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	cc6080e7          	jalr	-826(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028cc:	19048493          	addi	s1,s1,400
    800028d0:	03248263          	beq	s1,s2,800028f4 <procdump+0xa6>
    if (p->state == UNUSED)
    800028d4:	8826                	mv	a6,s1
    800028d6:	ec04a703          	lw	a4,-320(s1)
    800028da:	db6d                	beqz	a4,800028cc <procdump+0x7e>
      state = "???";
    800028dc:	87ce                	mv	a5,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028de:	fceb65e3          	bltu	s6,a4,800028a8 <procdump+0x5a>
    800028e2:	02071793          	slli	a5,a4,0x20
    800028e6:	01d7d713          	srli	a4,a5,0x1d
    800028ea:	975e                	add	a4,a4,s7
    800028ec:	631c                	ld	a5,0(a4)
    800028ee:	ffcd                	bnez	a5,800028a8 <procdump+0x5a>
      state = "???";
    800028f0:	87ce                	mv	a5,s3
    800028f2:	bf5d                	j	800028a8 <procdump+0x5a>
  }
}
    800028f4:	60a6                	ld	ra,72(sp)
    800028f6:	6406                	ld	s0,64(sp)
    800028f8:	74e2                	ld	s1,56(sp)
    800028fa:	7942                	ld	s2,48(sp)
    800028fc:	79a2                	ld	s3,40(sp)
    800028fe:	7a02                	ld	s4,32(sp)
    80002900:	6ae2                	ld	s5,24(sp)
    80002902:	6b42                	ld	s6,16(sp)
    80002904:	6ba2                	ld	s7,8(sp)
    80002906:	6161                	addi	sp,sp,80
    80002908:	8082                	ret

000000008000290a <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000290a:	711d                	addi	sp,sp,-96
    8000290c:	ec86                	sd	ra,88(sp)
    8000290e:	e8a2                	sd	s0,80(sp)
    80002910:	e4a6                	sd	s1,72(sp)
    80002912:	e0ca                	sd	s2,64(sp)
    80002914:	fc4e                	sd	s3,56(sp)
    80002916:	f852                	sd	s4,48(sp)
    80002918:	f456                	sd	s5,40(sp)
    8000291a:	f05a                	sd	s6,32(sp)
    8000291c:	ec5e                	sd	s7,24(sp)
    8000291e:	e862                	sd	s8,16(sp)
    80002920:	e466                	sd	s9,8(sp)
    80002922:	e06a                	sd	s10,0(sp)
    80002924:	1080                	addi	s0,sp,96
    80002926:	8b2a                	mv	s6,a0
    80002928:	8bae                	mv	s7,a1
    8000292a:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	25a080e7          	jalr	602(ra) # 80001b86 <myproc>
    80002934:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002936:	0022e517          	auipc	a0,0x22e
    8000293a:	2aa50513          	addi	a0,a0,682 # 80230be0 <wait_lock>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	430080e7          	jalr	1072(ra) # 80000d6e <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002946:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002948:	4a15                	li	s4,5
        havekids = 1;
    8000294a:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000294c:	00235997          	auipc	s3,0x235
    80002950:	aac98993          	addi	s3,s3,-1364 # 802373f8 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002954:	0022ed17          	auipc	s10,0x22e
    80002958:	28cd0d13          	addi	s10,s10,652 # 80230be0 <wait_lock>
    havekids = 0;
    8000295c:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000295e:	0022e497          	auipc	s1,0x22e
    80002962:	69a48493          	addi	s1,s1,1690 # 80230ff8 <proc>
    80002966:	a059                	j	800029ec <waitx+0xe2>
          pid = np->pid;
    80002968:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000296c:	1684a783          	lw	a5,360(s1)
    80002970:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002974:	16c4a703          	lw	a4,364(s1)
    80002978:	9f3d                	addw	a4,a4,a5
    8000297a:	1704a783          	lw	a5,368(s1)
    8000297e:	9f99                	subw	a5,a5,a4
    80002980:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002984:	000b0e63          	beqz	s6,800029a0 <waitx+0x96>
    80002988:	4691                	li	a3,4
    8000298a:	02c48613          	addi	a2,s1,44
    8000298e:	85da                	mv	a1,s6
    80002990:	05093503          	ld	a0,80(s2)
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	e7a080e7          	jalr	-390(ra) # 8000180e <copyout>
    8000299c:	02054563          	bltz	a0,800029c6 <waitx+0xbc>
          freeproc(np);
    800029a0:	8526                	mv	a0,s1
    800029a2:	fffff097          	auipc	ra,0xfffff
    800029a6:	396080e7          	jalr	918(ra) # 80001d38 <freeproc>
          release(&np->lock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	476080e7          	jalr	1142(ra) # 80000e22 <release>
          release(&wait_lock);
    800029b4:	0022e517          	auipc	a0,0x22e
    800029b8:	22c50513          	addi	a0,a0,556 # 80230be0 <wait_lock>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	466080e7          	jalr	1126(ra) # 80000e22 <release>
          return pid;
    800029c4:	a09d                	j	80002a2a <waitx+0x120>
            release(&np->lock);
    800029c6:	8526                	mv	a0,s1
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	45a080e7          	jalr	1114(ra) # 80000e22 <release>
            release(&wait_lock);
    800029d0:	0022e517          	auipc	a0,0x22e
    800029d4:	21050513          	addi	a0,a0,528 # 80230be0 <wait_lock>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	44a080e7          	jalr	1098(ra) # 80000e22 <release>
            return -1;
    800029e0:	59fd                	li	s3,-1
    800029e2:	a0a1                	j	80002a2a <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800029e4:	19048493          	addi	s1,s1,400
    800029e8:	03348463          	beq	s1,s3,80002a10 <waitx+0x106>
      if (np->parent == p)
    800029ec:	7c9c                	ld	a5,56(s1)
    800029ee:	ff279be3          	bne	a5,s2,800029e4 <waitx+0xda>
        acquire(&np->lock);
    800029f2:	8526                	mv	a0,s1
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	37a080e7          	jalr	890(ra) # 80000d6e <acquire>
        if (np->state == ZOMBIE)
    800029fc:	4c9c                	lw	a5,24(s1)
    800029fe:	f74785e3          	beq	a5,s4,80002968 <waitx+0x5e>
        release(&np->lock);
    80002a02:	8526                	mv	a0,s1
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	41e080e7          	jalr	1054(ra) # 80000e22 <release>
        havekids = 1;
    80002a0c:	8756                	mv	a4,s5
    80002a0e:	bfd9                	j	800029e4 <waitx+0xda>
    if (!havekids || p->killed)
    80002a10:	c701                	beqz	a4,80002a18 <waitx+0x10e>
    80002a12:	02892783          	lw	a5,40(s2)
    80002a16:	cb8d                	beqz	a5,80002a48 <waitx+0x13e>
      release(&wait_lock);
    80002a18:	0022e517          	auipc	a0,0x22e
    80002a1c:	1c850513          	addi	a0,a0,456 # 80230be0 <wait_lock>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	402080e7          	jalr	1026(ra) # 80000e22 <release>
      return -1;
    80002a28:	59fd                	li	s3,-1
  }
}
    80002a2a:	854e                	mv	a0,s3
    80002a2c:	60e6                	ld	ra,88(sp)
    80002a2e:	6446                	ld	s0,80(sp)
    80002a30:	64a6                	ld	s1,72(sp)
    80002a32:	6906                	ld	s2,64(sp)
    80002a34:	79e2                	ld	s3,56(sp)
    80002a36:	7a42                	ld	s4,48(sp)
    80002a38:	7aa2                	ld	s5,40(sp)
    80002a3a:	7b02                	ld	s6,32(sp)
    80002a3c:	6be2                	ld	s7,24(sp)
    80002a3e:	6c42                	ld	s8,16(sp)
    80002a40:	6ca2                	ld	s9,8(sp)
    80002a42:	6d02                	ld	s10,0(sp)
    80002a44:	6125                	addi	sp,sp,96
    80002a46:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a48:	85ea                	mv	a1,s10
    80002a4a:	854a                	mv	a0,s2
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	942080e7          	jalr	-1726(ra) # 8000238e <sleep>
    havekids = 0;
    80002a54:	b721                	j	8000295c <waitx+0x52>

0000000080002a56 <update_time>:

void update_time()
{
    80002a56:	7139                	addi	sp,sp,-64
    80002a58:	fc06                	sd	ra,56(sp)
    80002a5a:	f822                	sd	s0,48(sp)
    80002a5c:	f426                	sd	s1,40(sp)
    80002a5e:	f04a                	sd	s2,32(sp)
    80002a60:	ec4e                	sd	s3,24(sp)
    80002a62:	e852                	sd	s4,16(sp)
    80002a64:	e456                	sd	s5,8(sp)
    80002a66:	0080                	addi	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a68:	0022e497          	auipc	s1,0x22e
    80002a6c:	59048493          	addi	s1,s1,1424 # 80230ff8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a70:	4991                	li	s3,4
    {
      p->rtime++;
      p->run_time++;
      p->sleep_time = 0;
    }
    else if (p->state == SLEEPING)
    80002a72:	4a09                	li	s4,2
    {
      p->sleep_time++;
      p->run_time = 0;
    }
    else if (p->state == RUNNABLE)
    80002a74:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002a76:	00235917          	auipc	s2,0x235
    80002a7a:	98290913          	addi	s2,s2,-1662 # 802373f8 <tickslock>
    80002a7e:	a035                	j	80002aaa <update_time+0x54>
      p->rtime++;
    80002a80:	1684a783          	lw	a5,360(s1)
    80002a84:	2785                	addiw	a5,a5,1
    80002a86:	16f4a423          	sw	a5,360(s1)
      p->run_time++;
    80002a8a:	1844a783          	lw	a5,388(s1)
    80002a8e:	2785                	addiw	a5,a5,1
    80002a90:	18f4a223          	sw	a5,388(s1)
      p->sleep_time = 0;
    80002a94:	1804a023          	sw	zero,384(s1)
      p->wait_time++;
    release(&p->lock);
    80002a98:	8526                	mv	a0,s1
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	388080e7          	jalr	904(ra) # 80000e22 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002aa2:	19048493          	addi	s1,s1,400
    80002aa6:	03248c63          	beq	s1,s2,80002ade <update_time+0x88>
    acquire(&p->lock);
    80002aaa:	8526                	mv	a0,s1
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	2c2080e7          	jalr	706(ra) # 80000d6e <acquire>
    if (p->state == RUNNING)
    80002ab4:	4c9c                	lw	a5,24(s1)
    80002ab6:	fd3785e3          	beq	a5,s3,80002a80 <update_time+0x2a>
    else if (p->state == SLEEPING)
    80002aba:	01478a63          	beq	a5,s4,80002ace <update_time+0x78>
    else if (p->state == RUNNABLE)
    80002abe:	fd579de3          	bne	a5,s5,80002a98 <update_time+0x42>
      p->wait_time++;
    80002ac2:	1884a783          	lw	a5,392(s1)
    80002ac6:	2785                	addiw	a5,a5,1
    80002ac8:	18f4a423          	sw	a5,392(s1)
    80002acc:	b7f1                	j	80002a98 <update_time+0x42>
      p->sleep_time++;
    80002ace:	1804a783          	lw	a5,384(s1)
    80002ad2:	2785                	addiw	a5,a5,1
    80002ad4:	18f4a023          	sw	a5,384(s1)
      p->run_time = 0;
    80002ad8:	1804a223          	sw	zero,388(s1)
    80002adc:	bf75                	j	80002a98 <update_time+0x42>
  }
    80002ade:	70e2                	ld	ra,56(sp)
    80002ae0:	7442                	ld	s0,48(sp)
    80002ae2:	74a2                	ld	s1,40(sp)
    80002ae4:	7902                	ld	s2,32(sp)
    80002ae6:	69e2                	ld	s3,24(sp)
    80002ae8:	6a42                	ld	s4,16(sp)
    80002aea:	6aa2                	ld	s5,8(sp)
    80002aec:	6121                	addi	sp,sp,64
    80002aee:	8082                	ret

0000000080002af0 <swtch>:
    80002af0:	00153023          	sd	ra,0(a0)
    80002af4:	00253423          	sd	sp,8(a0)
    80002af8:	e900                	sd	s0,16(a0)
    80002afa:	ed04                	sd	s1,24(a0)
    80002afc:	03253023          	sd	s2,32(a0)
    80002b00:	03353423          	sd	s3,40(a0)
    80002b04:	03453823          	sd	s4,48(a0)
    80002b08:	03553c23          	sd	s5,56(a0)
    80002b0c:	05653023          	sd	s6,64(a0)
    80002b10:	05753423          	sd	s7,72(a0)
    80002b14:	05853823          	sd	s8,80(a0)
    80002b18:	05953c23          	sd	s9,88(a0)
    80002b1c:	07a53023          	sd	s10,96(a0)
    80002b20:	07b53423          	sd	s11,104(a0)
    80002b24:	0005b083          	ld	ra,0(a1)
    80002b28:	0085b103          	ld	sp,8(a1)
    80002b2c:	6980                	ld	s0,16(a1)
    80002b2e:	6d84                	ld	s1,24(a1)
    80002b30:	0205b903          	ld	s2,32(a1)
    80002b34:	0285b983          	ld	s3,40(a1)
    80002b38:	0305ba03          	ld	s4,48(a1)
    80002b3c:	0385ba83          	ld	s5,56(a1)
    80002b40:	0405bb03          	ld	s6,64(a1)
    80002b44:	0485bb83          	ld	s7,72(a1)
    80002b48:	0505bc03          	ld	s8,80(a1)
    80002b4c:	0585bc83          	ld	s9,88(a1)
    80002b50:	0605bd03          	ld	s10,96(a1)
    80002b54:	0685bd83          	ld	s11,104(a1)
    80002b58:	8082                	ret

0000000080002b5a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b5a:	1141                	addi	sp,sp,-16
    80002b5c:	e406                	sd	ra,8(sp)
    80002b5e:	e022                	sd	s0,0(sp)
    80002b60:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b62:	00005597          	auipc	a1,0x5
    80002b66:	7be58593          	addi	a1,a1,1982 # 80008320 <states.0+0x30>
    80002b6a:	00235517          	auipc	a0,0x235
    80002b6e:	88e50513          	addi	a0,a0,-1906 # 802373f8 <tickslock>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	16c080e7          	jalr	364(ra) # 80000cde <initlock>
}
    80002b7a:	60a2                	ld	ra,8(sp)
    80002b7c:	6402                	ld	s0,0(sp)
    80002b7e:	0141                	addi	sp,sp,16
    80002b80:	8082                	ret

0000000080002b82 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b82:	1141                	addi	sp,sp,-16
    80002b84:	e422                	sd	s0,8(sp)
    80002b86:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b88:	00003797          	auipc	a5,0x3
    80002b8c:	77878793          	addi	a5,a5,1912 # 80006300 <kernelvec>
    80002b90:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b94:	6422                	ld	s0,8(sp)
    80002b96:	0141                	addi	sp,sp,16
    80002b98:	8082                	ret

0000000080002b9a <write_trap>:
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//

int write_trap(void *va, pagetable_t pagetable)
{
    80002b9a:	7179                	addi	sp,sp,-48
    80002b9c:	f406                	sd	ra,40(sp)
    80002b9e:	f022                	sd	s0,32(sp)
    80002ba0:	ec26                	sd	s1,24(sp)
    80002ba2:	e84a                	sd	s2,16(sp)
    80002ba4:	e44e                	sd	s3,8(sp)
    80002ba6:	e052                	sd	s4,0(sp)
    80002ba8:	1800                	addi	s0,sp,48
    80002baa:	84aa                	mv	s1,a0
    80002bac:	892e                	mv	s2,a1
  struct proc *p;
  p = myproc();
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	fd8080e7          	jalr	-40(ra) # 80001b86 <myproc>
  if ((uint64)va < MAXVA)
    80002bb6:	57fd                	li	a5,-1
    80002bb8:	83e9                	srli	a5,a5,0x1a
    80002bba:	0897e763          	bltu	a5,s1,80002c48 <write_trap+0xae>
  {
    uint64 temp = PGROUNDDOWN(p->trapframe->sp);
    80002bbe:	6d3c                	ld	a5,88(a0)
    80002bc0:	7b94                	ld	a3,48(a5)
    80002bc2:	77fd                	lui	a5,0xfffff
    80002bc4:	8ff5                	and	a5,a5,a3
    if ((uint64)va > temp || (uint64)va < temp - PGSIZE)
    80002bc6:	0097e663          	bltu	a5,s1,80002bd2 <write_trap+0x38>
    80002bca:	76fd                	lui	a3,0xfffff
    80002bcc:	97b6                	add	a5,a5,a3
    80002bce:	06f4ff63          	bgeu	s1,a5,80002c4c <write_trap+0xb2>
    {
      uint64 pa;
      pte_t *pte = 0;
      va = (void *)PGROUNDDOWN((uint64)va);
      pte = walk(pagetable, (uint64)va, 0);
    80002bd2:	4601                	li	a2,0
    80002bd4:	75fd                	lui	a1,0xfffff
    80002bd6:	8de5                	and	a1,a1,s1
    80002bd8:	854a                	mv	a0,s2
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	574080e7          	jalr	1396(ra) # 8000114e <walk>
    80002be2:	892a                	mv	s2,a0
      if (!pte)
    80002be4:	c535                	beqz	a0,80002c50 <write_trap+0xb6>
      {
        return -1;
      }
      else
      {
        pa = PTE2PA(*pte);
    80002be6:	611c                	ld	a5,0(a0)
    80002be8:	00a7d993          	srli	s3,a5,0xa
    80002bec:	09b2                	slli	s3,s3,0xc
        if (!pa)
    80002bee:	06098363          	beqz	s3,80002c54 <write_trap+0xba>
          return -1;
      }
      
      uint flags;
      flags = PTE_FLAGS(*pte);
    80002bf2:	00078a1b          	sext.w	s4,a5
      if (flags & PTE_COW)
    80002bf6:	0207f793          	andi	a5,a5,32
        flags |= (PTE_W);
        flags &= (~PTE_COW);
        *pte = PA2PTE(mem) | flags;
        kfree((void *)pa);
      }
      return 0;
    80002bfa:	4501                	li	a0,0
      if (flags & PTE_COW)
    80002bfc:	eb89                	bnez	a5,80002c0e <write_trap+0x74>
    else
      return -1;
  }
  else
    return -1;
}
    80002bfe:	70a2                	ld	ra,40(sp)
    80002c00:	7402                	ld	s0,32(sp)
    80002c02:	64e2                	ld	s1,24(sp)
    80002c04:	6942                	ld	s2,16(sp)
    80002c06:	69a2                	ld	s3,8(sp)
    80002c08:	6a02                	ld	s4,0(sp)
    80002c0a:	6145                	addi	sp,sp,48
    80002c0c:	8082                	ret
        mem = kalloc();
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	05c080e7          	jalr	92(ra) # 80000c6a <kalloc>
    80002c16:	84aa                	mv	s1,a0
        if (!mem)
    80002c18:	c121                	beqz	a0,80002c58 <write_trap+0xbe>
        memmove(mem, (void *)pa, PGSIZE);
    80002c1a:	6605                	lui	a2,0x1
    80002c1c:	85ce                	mv	a1,s3
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	2a8080e7          	jalr	680(ra) # 80000ec6 <memmove>
        *pte = PA2PTE(mem) | flags;
    80002c26:	80b1                	srli	s1,s1,0xc
    80002c28:	04aa                	slli	s1,s1,0xa
        flags &= (~PTE_COW);
    80002c2a:	3dfa7a13          	andi	s4,s4,991
        *pte = PA2PTE(mem) | flags;
    80002c2e:	004a6a13          	ori	s4,s4,4
    80002c32:	0144e4b3          	or	s1,s1,s4
    80002c36:	00993023          	sd	s1,0(s2)
        kfree((void *)pa);
    80002c3a:	854e                	mv	a0,s3
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	ed2080e7          	jalr	-302(ra) # 80000b0e <kfree>
      return 0;
    80002c44:	4501                	li	a0,0
    80002c46:	bf65                	j	80002bfe <write_trap+0x64>
    return -1;
    80002c48:	557d                	li	a0,-1
    80002c4a:	bf55                	j	80002bfe <write_trap+0x64>
      return -1;
    80002c4c:	557d                	li	a0,-1
    80002c4e:	bf45                	j	80002bfe <write_trap+0x64>
        return -1;
    80002c50:	557d                	li	a0,-1
    80002c52:	b775                	j	80002bfe <write_trap+0x64>
          return -1;
    80002c54:	557d                	li	a0,-1
    80002c56:	b765                	j	80002bfe <write_trap+0x64>
          return -1;
    80002c58:	557d                	li	a0,-1
    80002c5a:	b755                	j	80002bfe <write_trap+0x64>

0000000080002c5c <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c5c:	1141                	addi	sp,sp,-16
    80002c5e:	e406                	sd	ra,8(sp)
    80002c60:	e022                	sd	s0,0(sp)
    80002c62:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	f22080e7          	jalr	-222(ra) # 80001b86 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c70:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c72:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c76:	00004697          	auipc	a3,0x4
    80002c7a:	38a68693          	addi	a3,a3,906 # 80007000 <_trampoline>
    80002c7e:	00004717          	auipc	a4,0x4
    80002c82:	38270713          	addi	a4,a4,898 # 80007000 <_trampoline>
    80002c86:	8f15                	sub	a4,a4,a3
    80002c88:	040007b7          	lui	a5,0x4000
    80002c8c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c8e:	07b2                	slli	a5,a5,0xc
    80002c90:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c92:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c96:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c98:	18002673          	csrr	a2,satp
    80002c9c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c9e:	6d30                	ld	a2,88(a0)
    80002ca0:	6138                	ld	a4,64(a0)
    80002ca2:	6585                	lui	a1,0x1
    80002ca4:	972e                	add	a4,a4,a1
    80002ca6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ca8:	6d38                	ld	a4,88(a0)
    80002caa:	00000617          	auipc	a2,0x0
    80002cae:	13e60613          	addi	a2,a2,318 # 80002de8 <usertrap>
    80002cb2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002cb4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cb6:	8612                	mv	a2,tp
    80002cb8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cba:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cbe:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cc2:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cca:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ccc:	6f18                	ld	a4,24(a4)
    80002cce:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cd2:	6928                	ld	a0,80(a0)
    80002cd4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cd6:	00004717          	auipc	a4,0x4
    80002cda:	3c670713          	addi	a4,a4,966 # 8000709c <userret>
    80002cde:	8f15                	sub	a4,a4,a3
    80002ce0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ce2:	577d                	li	a4,-1
    80002ce4:	177e                	slli	a4,a4,0x3f
    80002ce6:	8d59                	or	a0,a0,a4
    80002ce8:	9782                	jalr	a5
}
    80002cea:	60a2                	ld	ra,8(sp)
    80002cec:	6402                	ld	s0,0(sp)
    80002cee:	0141                	addi	sp,sp,16
    80002cf0:	8082                	ret

0000000080002cf2 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	e04a                	sd	s2,0(sp)
    80002cfc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cfe:	00234917          	auipc	s2,0x234
    80002d02:	6fa90913          	addi	s2,s2,1786 # 802373f8 <tickslock>
    80002d06:	854a                	mv	a0,s2
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	066080e7          	jalr	102(ra) # 80000d6e <acquire>
  ticks++;
    80002d10:	00006497          	auipc	s1,0x6
    80002d14:	c3048493          	addi	s1,s1,-976 # 80008940 <ticks>
    80002d18:	409c                	lw	a5,0(s1)
    80002d1a:	2785                	addiw	a5,a5,1
    80002d1c:	c09c                	sw	a5,0(s1)
  update_time();
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	d38080e7          	jalr	-712(ra) # 80002a56 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002d26:	8526                	mv	a0,s1
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	6ca080e7          	jalr	1738(ra) # 800023f2 <wakeup>
  release(&tickslock);
    80002d30:	854a                	mv	a0,s2
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	0f0080e7          	jalr	240(ra) # 80000e22 <release>
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	64a2                	ld	s1,8(sp)
    80002d40:	6902                	ld	s2,0(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret

0000000080002d46 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	e426                	sd	s1,8(sp)
    80002d4e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d50:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002d54:	00074d63          	bltz	a4,80002d6e <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002d58:	57fd                	li	a5,-1
    80002d5a:	17fe                	slli	a5,a5,0x3f
    80002d5c:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002d5e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002d60:	06f70363          	beq	a4,a5,80002dc6 <devintr+0x80>
  }
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	64a2                	ld	s1,8(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret
      (scause & 0xff) == 9)
    80002d6e:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002d72:	46a5                	li	a3,9
    80002d74:	fed792e3          	bne	a5,a3,80002d58 <devintr+0x12>
    int irq = plic_claim();
    80002d78:	00003097          	auipc	ra,0x3
    80002d7c:	690080e7          	jalr	1680(ra) # 80006408 <plic_claim>
    80002d80:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002d82:	47a9                	li	a5,10
    80002d84:	02f50763          	beq	a0,a5,80002db2 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002d88:	4785                	li	a5,1
    80002d8a:	02f50963          	beq	a0,a5,80002dbc <devintr+0x76>
    return 1;
    80002d8e:	4505                	li	a0,1
    else if (irq)
    80002d90:	d8f1                	beqz	s1,80002d64 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d92:	85a6                	mv	a1,s1
    80002d94:	00005517          	auipc	a0,0x5
    80002d98:	59450513          	addi	a0,a0,1428 # 80008328 <states.0+0x38>
    80002d9c:	ffffd097          	auipc	ra,0xffffd
    80002da0:	7ee080e7          	jalr	2030(ra) # 8000058a <printf>
      plic_complete(irq);
    80002da4:	8526                	mv	a0,s1
    80002da6:	00003097          	auipc	ra,0x3
    80002daa:	686080e7          	jalr	1670(ra) # 8000642c <plic_complete>
    return 1;
    80002dae:	4505                	li	a0,1
    80002db0:	bf55                	j	80002d64 <devintr+0x1e>
      uartintr();
    80002db2:	ffffe097          	auipc	ra,0xffffe
    80002db6:	be6080e7          	jalr	-1050(ra) # 80000998 <uartintr>
    80002dba:	b7ed                	j	80002da4 <devintr+0x5e>
      virtio_disk_intr();
    80002dbc:	00004097          	auipc	ra,0x4
    80002dc0:	b38080e7          	jalr	-1224(ra) # 800068f4 <virtio_disk_intr>
    80002dc4:	b7c5                	j	80002da4 <devintr+0x5e>
    if (cpuid() == 0)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	d94080e7          	jalr	-620(ra) # 80001b5a <cpuid>
    80002dce:	c901                	beqz	a0,80002dde <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dd0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dd6:	14479073          	csrw	sip,a5
    return 2;
    80002dda:	4509                	li	a0,2
    80002ddc:	b761                	j	80002d64 <devintr+0x1e>
      clockintr();
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	f14080e7          	jalr	-236(ra) # 80002cf2 <clockintr>
    80002de6:	b7ed                	j	80002dd0 <devintr+0x8a>

0000000080002de8 <usertrap>:
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	e426                	sd	s1,8(sp)
    80002df0:	e04a                	sd	s2,0(sp)
    80002df2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df4:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002df8:	1007f793          	andi	a5,a5,256
    80002dfc:	e7b1                	bnez	a5,80002e48 <usertrap+0x60>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dfe:	00003797          	auipc	a5,0x3
    80002e02:	50278793          	addi	a5,a5,1282 # 80006300 <kernelvec>
    80002e06:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	d7c080e7          	jalr	-644(ra) # 80001b86 <myproc>
    80002e12:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e14:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e16:	14102773          	csrr	a4,sepc
    80002e1a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e20:	47a1                	li	a5,8
    80002e22:	02f70b63          	beq	a4,a5,80002e58 <usertrap+0x70>
  else if ((which_dev = devintr()) != 0)
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	f20080e7          	jalr	-224(ra) # 80002d46 <devintr>
    80002e2e:	892a                	mv	s2,a0
    80002e30:	e579                	bnez	a0,80002efe <usertrap+0x116>
    80002e32:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002e36:	47bd                	li	a5,15
    80002e38:	08f71663          	bne	a4,a5,80002ec4 <usertrap+0xdc>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e3c:	143027f3          	csrr	a5,stval
    if (r_stval() != 0)
    80002e40:	e7ad                	bnez	a5,80002eaa <usertrap+0xc2>
      p->killed = 1;
    80002e42:	4785                	li	a5,1
    80002e44:	d49c                	sw	a5,40(s1)
    80002e46:	a825                	j	80002e7e <usertrap+0x96>
    panic("usertrap: not from user mode");
    80002e48:	00005517          	auipc	a0,0x5
    80002e4c:	50050513          	addi	a0,a0,1280 # 80008348 <states.0+0x58>
    80002e50:	ffffd097          	auipc	ra,0xffffd
    80002e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>
    if (killed(p))
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	7ea080e7          	jalr	2026(ra) # 80002642 <killed>
    80002e60:	ed1d                	bnez	a0,80002e9e <usertrap+0xb6>
    p->trapframe->epc += 4;
    80002e62:	6cb8                	ld	a4,88(s1)
    80002e64:	6f1c                	ld	a5,24(a4)
    80002e66:	0791                	addi	a5,a5,4
    80002e68:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e72:	10079073          	csrw	sstatus,a5
    syscall();
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	2fc080e7          	jalr	764(ra) # 80003172 <syscall>
  if (killed(p))
    80002e7e:	8526                	mv	a0,s1
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	7c2080e7          	jalr	1986(ra) # 80002642 <killed>
    80002e88:	e151                	bnez	a0,80002f0c <usertrap+0x124>
  usertrapret();
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	dd2080e7          	jalr	-558(ra) # 80002c5c <usertrapret>
}
    80002e92:	60e2                	ld	ra,24(sp)
    80002e94:	6442                	ld	s0,16(sp)
    80002e96:	64a2                	ld	s1,8(sp)
    80002e98:	6902                	ld	s2,0(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret
      exit(-1);
    80002e9e:	557d                	li	a0,-1
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	622080e7          	jalr	1570(ra) # 800024c2 <exit>
    80002ea8:	bf6d                	j	80002e62 <usertrap+0x7a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eaa:	14302573          	csrr	a0,stval
      if (write_trap((void *)r_stval(), p->pagetable) == -1)
    80002eae:	68ac                	ld	a1,80(s1)
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	cea080e7          	jalr	-790(ra) # 80002b9a <write_trap>
    80002eb8:	57fd                	li	a5,-1
    80002eba:	fcf512e3          	bne	a0,a5,80002e7e <usertrap+0x96>
        p->killed = 1;
    80002ebe:	4785                	li	a5,1
    80002ec0:	d49c                	sw	a5,40(s1)
    80002ec2:	bf75                	j	80002e7e <usertrap+0x96>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ec8:	5890                	lw	a2,48(s1)
    80002eca:	00005517          	auipc	a0,0x5
    80002ece:	49e50513          	addi	a0,a0,1182 # 80008368 <states.0+0x78>
    80002ed2:	ffffd097          	auipc	ra,0xffffd
    80002ed6:	6b8080e7          	jalr	1720(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eda:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ede:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	4b650513          	addi	a0,a0,1206 # 80008398 <states.0+0xa8>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	6a0080e7          	jalr	1696(ra) # 8000058a <printf>
    setkilled(p);
    80002ef2:	8526                	mv	a0,s1
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	722080e7          	jalr	1826(ra) # 80002616 <setkilled>
    80002efc:	b749                	j	80002e7e <usertrap+0x96>
  if (killed(p))
    80002efe:	8526                	mv	a0,s1
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	742080e7          	jalr	1858(ra) # 80002642 <killed>
    80002f08:	c901                	beqz	a0,80002f18 <usertrap+0x130>
    80002f0a:	a011                	j	80002f0e <usertrap+0x126>
    80002f0c:	4901                	li	s2,0
    exit(-1);
    80002f0e:	557d                	li	a0,-1
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	5b2080e7          	jalr	1458(ra) # 800024c2 <exit>
  if (which_dev == 2)
    80002f18:	4789                	li	a5,2
    80002f1a:	f6f918e3          	bne	s2,a5,80002e8a <usertrap+0xa2>
    yield();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	434080e7          	jalr	1076(ra) # 80002352 <yield>
    80002f26:	b795                	j	80002e8a <usertrap+0xa2>

0000000080002f28 <kerneltrap>:
{
    80002f28:	7179                	addi	sp,sp,-48
    80002f2a:	f406                	sd	ra,40(sp)
    80002f2c:	f022                	sd	s0,32(sp)
    80002f2e:	ec26                	sd	s1,24(sp)
    80002f30:	e84a                	sd	s2,16(sp)
    80002f32:	e44e                	sd	s3,8(sp)
    80002f34:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f36:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f3a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f3e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f42:	1004f793          	andi	a5,s1,256
    80002f46:	cb85                	beqz	a5,80002f76 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f4c:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002f4e:	ef85                	bnez	a5,80002f86 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	df6080e7          	jalr	-522(ra) # 80002d46 <devintr>
    80002f58:	cd1d                	beqz	a0,80002f96 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f5a:	4789                	li	a5,2
    80002f5c:	06f50a63          	beq	a0,a5,80002fd0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f60:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f64:	10049073          	csrw	sstatus,s1
}
    80002f68:	70a2                	ld	ra,40(sp)
    80002f6a:	7402                	ld	s0,32(sp)
    80002f6c:	64e2                	ld	s1,24(sp)
    80002f6e:	6942                	ld	s2,16(sp)
    80002f70:	69a2                	ld	s3,8(sp)
    80002f72:	6145                	addi	sp,sp,48
    80002f74:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f76:	00005517          	auipc	a0,0x5
    80002f7a:	44250513          	addi	a0,a0,1090 # 800083b8 <states.0+0xc8>
    80002f7e:	ffffd097          	auipc	ra,0xffffd
    80002f82:	5c2080e7          	jalr	1474(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f86:	00005517          	auipc	a0,0x5
    80002f8a:	45a50513          	addi	a0,a0,1114 # 800083e0 <states.0+0xf0>
    80002f8e:	ffffd097          	auipc	ra,0xffffd
    80002f92:	5b2080e7          	jalr	1458(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002f96:	85ce                	mv	a1,s3
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	46850513          	addi	a0,a0,1128 # 80008400 <states.0+0x110>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	5ea080e7          	jalr	1514(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fa8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fac:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fb0:	00005517          	auipc	a0,0x5
    80002fb4:	46050513          	addi	a0,a0,1120 # 80008410 <states.0+0x120>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	5d2080e7          	jalr	1490(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002fc0:	00005517          	auipc	a0,0x5
    80002fc4:	46850513          	addi	a0,a0,1128 # 80008428 <states.0+0x138>
    80002fc8:	ffffd097          	auipc	ra,0xffffd
    80002fcc:	578080e7          	jalr	1400(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	bb6080e7          	jalr	-1098(ra) # 80001b86 <myproc>
    80002fd8:	d541                	beqz	a0,80002f60 <kerneltrap+0x38>
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	bac080e7          	jalr	-1108(ra) # 80001b86 <myproc>
    80002fe2:	4d18                	lw	a4,24(a0)
    80002fe4:	4791                	li	a5,4
    80002fe6:	f6f71de3          	bne	a4,a5,80002f60 <kerneltrap+0x38>
    yield();
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	368080e7          	jalr	872(ra) # 80002352 <yield>
    80002ff2:	b7bd                	j	80002f60 <kerneltrap+0x38>

0000000080002ff4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ff4:	1101                	addi	sp,sp,-32
    80002ff6:	ec06                	sd	ra,24(sp)
    80002ff8:	e822                	sd	s0,16(sp)
    80002ffa:	e426                	sd	s1,8(sp)
    80002ffc:	1000                	addi	s0,sp,32
    80002ffe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	b86080e7          	jalr	-1146(ra) # 80001b86 <myproc>
  switch (n) {
    80003008:	4795                	li	a5,5
    8000300a:	0497e163          	bltu	a5,s1,8000304c <argraw+0x58>
    8000300e:	048a                	slli	s1,s1,0x2
    80003010:	00005717          	auipc	a4,0x5
    80003014:	45070713          	addi	a4,a4,1104 # 80008460 <states.0+0x170>
    80003018:	94ba                	add	s1,s1,a4
    8000301a:	409c                	lw	a5,0(s1)
    8000301c:	97ba                	add	a5,a5,a4
    8000301e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003020:	6d3c                	ld	a5,88(a0)
    80003022:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003024:	60e2                	ld	ra,24(sp)
    80003026:	6442                	ld	s0,16(sp)
    80003028:	64a2                	ld	s1,8(sp)
    8000302a:	6105                	addi	sp,sp,32
    8000302c:	8082                	ret
    return p->trapframe->a1;
    8000302e:	6d3c                	ld	a5,88(a0)
    80003030:	7fa8                	ld	a0,120(a5)
    80003032:	bfcd                	j	80003024 <argraw+0x30>
    return p->trapframe->a2;
    80003034:	6d3c                	ld	a5,88(a0)
    80003036:	63c8                	ld	a0,128(a5)
    80003038:	b7f5                	j	80003024 <argraw+0x30>
    return p->trapframe->a3;
    8000303a:	6d3c                	ld	a5,88(a0)
    8000303c:	67c8                	ld	a0,136(a5)
    8000303e:	b7dd                	j	80003024 <argraw+0x30>
    return p->trapframe->a4;
    80003040:	6d3c                	ld	a5,88(a0)
    80003042:	6bc8                	ld	a0,144(a5)
    80003044:	b7c5                	j	80003024 <argraw+0x30>
    return p->trapframe->a5;
    80003046:	6d3c                	ld	a5,88(a0)
    80003048:	6fc8                	ld	a0,152(a5)
    8000304a:	bfe9                	j	80003024 <argraw+0x30>
  panic("argraw");
    8000304c:	00005517          	auipc	a0,0x5
    80003050:	3ec50513          	addi	a0,a0,1004 # 80008438 <states.0+0x148>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	4ec080e7          	jalr	1260(ra) # 80000540 <panic>

000000008000305c <fetchaddr>:
{
    8000305c:	1101                	addi	sp,sp,-32
    8000305e:	ec06                	sd	ra,24(sp)
    80003060:	e822                	sd	s0,16(sp)
    80003062:	e426                	sd	s1,8(sp)
    80003064:	e04a                	sd	s2,0(sp)
    80003066:	1000                	addi	s0,sp,32
    80003068:	84aa                	mv	s1,a0
    8000306a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	b1a080e7          	jalr	-1254(ra) # 80001b86 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003074:	653c                	ld	a5,72(a0)
    80003076:	02f4f863          	bgeu	s1,a5,800030a6 <fetchaddr+0x4a>
    8000307a:	00848713          	addi	a4,s1,8
    8000307e:	02e7e663          	bltu	a5,a4,800030aa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003082:	46a1                	li	a3,8
    80003084:	8626                	mv	a2,s1
    80003086:	85ca                	mv	a1,s2
    80003088:	6928                	ld	a0,80(a0)
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	848080e7          	jalr	-1976(ra) # 800018d2 <copyin>
    80003092:	00a03533          	snez	a0,a0
    80003096:	40a00533          	neg	a0,a0
}
    8000309a:	60e2                	ld	ra,24(sp)
    8000309c:	6442                	ld	s0,16(sp)
    8000309e:	64a2                	ld	s1,8(sp)
    800030a0:	6902                	ld	s2,0(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret
    return -1;
    800030a6:	557d                	li	a0,-1
    800030a8:	bfcd                	j	8000309a <fetchaddr+0x3e>
    800030aa:	557d                	li	a0,-1
    800030ac:	b7fd                	j	8000309a <fetchaddr+0x3e>

00000000800030ae <fetchstr>:
{
    800030ae:	7179                	addi	sp,sp,-48
    800030b0:	f406                	sd	ra,40(sp)
    800030b2:	f022                	sd	s0,32(sp)
    800030b4:	ec26                	sd	s1,24(sp)
    800030b6:	e84a                	sd	s2,16(sp)
    800030b8:	e44e                	sd	s3,8(sp)
    800030ba:	1800                	addi	s0,sp,48
    800030bc:	892a                	mv	s2,a0
    800030be:	84ae                	mv	s1,a1
    800030c0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030c2:	fffff097          	auipc	ra,0xfffff
    800030c6:	ac4080e7          	jalr	-1340(ra) # 80001b86 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800030ca:	86ce                	mv	a3,s3
    800030cc:	864a                	mv	a2,s2
    800030ce:	85a6                	mv	a1,s1
    800030d0:	6928                	ld	a0,80(a0)
    800030d2:	fffff097          	auipc	ra,0xfffff
    800030d6:	88e080e7          	jalr	-1906(ra) # 80001960 <copyinstr>
    800030da:	00054e63          	bltz	a0,800030f6 <fetchstr+0x48>
  return strlen(buf);
    800030de:	8526                	mv	a0,s1
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	f06080e7          	jalr	-250(ra) # 80000fe6 <strlen>
}
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6942                	ld	s2,16(sp)
    800030f0:	69a2                	ld	s3,8(sp)
    800030f2:	6145                	addi	sp,sp,48
    800030f4:	8082                	ret
    return -1;
    800030f6:	557d                	li	a0,-1
    800030f8:	bfc5                	j	800030e8 <fetchstr+0x3a>

00000000800030fa <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800030fa:	1101                	addi	sp,sp,-32
    800030fc:	ec06                	sd	ra,24(sp)
    800030fe:	e822                	sd	s0,16(sp)
    80003100:	e426                	sd	s1,8(sp)
    80003102:	1000                	addi	s0,sp,32
    80003104:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003106:	00000097          	auipc	ra,0x0
    8000310a:	eee080e7          	jalr	-274(ra) # 80002ff4 <argraw>
    8000310e:	c088                	sw	a0,0(s1)
}
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	64a2                	ld	s1,8(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
    80003124:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003126:	00000097          	auipc	ra,0x0
    8000312a:	ece080e7          	jalr	-306(ra) # 80002ff4 <argraw>
    8000312e:	e088                	sd	a0,0(s1)
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	64a2                	ld	s1,8(sp)
    80003136:	6105                	addi	sp,sp,32
    80003138:	8082                	ret

000000008000313a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000313a:	7179                	addi	sp,sp,-48
    8000313c:	f406                	sd	ra,40(sp)
    8000313e:	f022                	sd	s0,32(sp)
    80003140:	ec26                	sd	s1,24(sp)
    80003142:	e84a                	sd	s2,16(sp)
    80003144:	1800                	addi	s0,sp,48
    80003146:	84ae                	mv	s1,a1
    80003148:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000314a:	fd840593          	addi	a1,s0,-40
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	fcc080e7          	jalr	-52(ra) # 8000311a <argaddr>
  return fetchstr(addr, buf, max);
    80003156:	864a                	mv	a2,s2
    80003158:	85a6                	mv	a1,s1
    8000315a:	fd843503          	ld	a0,-40(s0)
    8000315e:	00000097          	auipc	ra,0x0
    80003162:	f50080e7          	jalr	-176(ra) # 800030ae <fetchstr>
}
    80003166:	70a2                	ld	ra,40(sp)
    80003168:	7402                	ld	s0,32(sp)
    8000316a:	64e2                	ld	s1,24(sp)
    8000316c:	6942                	ld	s2,16(sp)
    8000316e:	6145                	addi	sp,sp,48
    80003170:	8082                	ret

0000000080003172 <syscall>:
[SYS_set_priority] sys_set_priority,
};

void
syscall(void)
{
    80003172:	1101                	addi	sp,sp,-32
    80003174:	ec06                	sd	ra,24(sp)
    80003176:	e822                	sd	s0,16(sp)
    80003178:	e426                	sd	s1,8(sp)
    8000317a:	e04a                	sd	s2,0(sp)
    8000317c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	a08080e7          	jalr	-1528(ra) # 80001b86 <myproc>
    80003186:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003188:	05853903          	ld	s2,88(a0)
    8000318c:	0a893783          	ld	a5,168(s2)
    80003190:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003194:	37fd                	addiw	a5,a5,-1
    80003196:	475d                	li	a4,23
    80003198:	00f76f63          	bltu	a4,a5,800031b6 <syscall+0x44>
    8000319c:	00369713          	slli	a4,a3,0x3
    800031a0:	00005797          	auipc	a5,0x5
    800031a4:	2d878793          	addi	a5,a5,728 # 80008478 <syscalls>
    800031a8:	97ba                	add	a5,a5,a4
    800031aa:	639c                	ld	a5,0(a5)
    800031ac:	c789                	beqz	a5,800031b6 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800031ae:	9782                	jalr	a5
    800031b0:	06a93823          	sd	a0,112(s2)
    800031b4:	a839                	j	800031d2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031b6:	15848613          	addi	a2,s1,344
    800031ba:	588c                	lw	a1,48(s1)
    800031bc:	00005517          	auipc	a0,0x5
    800031c0:	28450513          	addi	a0,a0,644 # 80008440 <states.0+0x150>
    800031c4:	ffffd097          	auipc	ra,0xffffd
    800031c8:	3c6080e7          	jalr	966(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031cc:	6cbc                	ld	a5,88(s1)
    800031ce:	577d                	li	a4,-1
    800031d0:	fbb8                	sd	a4,112(a5)
  }
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6902                	ld	s2,0(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret

00000000800031de <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031de:	1101                	addi	sp,sp,-32
    800031e0:	ec06                	sd	ra,24(sp)
    800031e2:	e822                	sd	s0,16(sp)
    800031e4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800031e6:	fec40593          	addi	a1,s0,-20
    800031ea:	4501                	li	a0,0
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	f0e080e7          	jalr	-242(ra) # 800030fa <argint>
  exit(n);
    800031f4:	fec42503          	lw	a0,-20(s0)
    800031f8:	fffff097          	auipc	ra,0xfffff
    800031fc:	2ca080e7          	jalr	714(ra) # 800024c2 <exit>
  return 0; // not reached
}
    80003200:	4501                	li	a0,0
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	6105                	addi	sp,sp,32
    80003208:	8082                	ret

000000008000320a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000320a:	1141                	addi	sp,sp,-16
    8000320c:	e406                	sd	ra,8(sp)
    8000320e:	e022                	sd	s0,0(sp)
    80003210:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003212:	fffff097          	auipc	ra,0xfffff
    80003216:	974080e7          	jalr	-1676(ra) # 80001b86 <myproc>
}
    8000321a:	5908                	lw	a0,48(a0)
    8000321c:	60a2                	ld	ra,8(sp)
    8000321e:	6402                	ld	s0,0(sp)
    80003220:	0141                	addi	sp,sp,16
    80003222:	8082                	ret

0000000080003224 <sys_fork>:

uint64
sys_fork(void)
{
    80003224:	1141                	addi	sp,sp,-16
    80003226:	e406                	sd	ra,8(sp)
    80003228:	e022                	sd	s0,0(sp)
    8000322a:	0800                	addi	s0,sp,16
  return fork();
    8000322c:	fffff097          	auipc	ra,0xfffff
    80003230:	d46080e7          	jalr	-698(ra) # 80001f72 <fork>
}
    80003234:	60a2                	ld	ra,8(sp)
    80003236:	6402                	ld	s0,0(sp)
    80003238:	0141                	addi	sp,sp,16
    8000323a:	8082                	ret

000000008000323c <sys_wait>:

uint64
sys_wait(void)
{
    8000323c:	1101                	addi	sp,sp,-32
    8000323e:	ec06                	sd	ra,24(sp)
    80003240:	e822                	sd	s0,16(sp)
    80003242:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003244:	fe840593          	addi	a1,s0,-24
    80003248:	4501                	li	a0,0
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	ed0080e7          	jalr	-304(ra) # 8000311a <argaddr>
  return wait(p);
    80003252:	fe843503          	ld	a0,-24(s0)
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	41e080e7          	jalr	1054(ra) # 80002674 <wait>
}
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret

0000000080003266 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003266:	7179                	addi	sp,sp,-48
    80003268:	f406                	sd	ra,40(sp)
    8000326a:	f022                	sd	s0,32(sp)
    8000326c:	ec26                	sd	s1,24(sp)
    8000326e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003270:	fdc40593          	addi	a1,s0,-36
    80003274:	4501                	li	a0,0
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	e84080e7          	jalr	-380(ra) # 800030fa <argint>
  addr = myproc()->sz;
    8000327e:	fffff097          	auipc	ra,0xfffff
    80003282:	908080e7          	jalr	-1784(ra) # 80001b86 <myproc>
    80003286:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003288:	fdc42503          	lw	a0,-36(s0)
    8000328c:	fffff097          	auipc	ra,0xfffff
    80003290:	c8a080e7          	jalr	-886(ra) # 80001f16 <growproc>
    80003294:	00054863          	bltz	a0,800032a4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003298:	8526                	mv	a0,s1
    8000329a:	70a2                	ld	ra,40(sp)
    8000329c:	7402                	ld	s0,32(sp)
    8000329e:	64e2                	ld	s1,24(sp)
    800032a0:	6145                	addi	sp,sp,48
    800032a2:	8082                	ret
    return -1;
    800032a4:	54fd                	li	s1,-1
    800032a6:	bfcd                	j	80003298 <sys_sbrk+0x32>

00000000800032a8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032a8:	7139                	addi	sp,sp,-64
    800032aa:	fc06                	sd	ra,56(sp)
    800032ac:	f822                	sd	s0,48(sp)
    800032ae:	f426                	sd	s1,40(sp)
    800032b0:	f04a                	sd	s2,32(sp)
    800032b2:	ec4e                	sd	s3,24(sp)
    800032b4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032b6:	fcc40593          	addi	a1,s0,-52
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e3e080e7          	jalr	-450(ra) # 800030fa <argint>
  acquire(&tickslock);
    800032c4:	00234517          	auipc	a0,0x234
    800032c8:	13450513          	addi	a0,a0,308 # 802373f8 <tickslock>
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	aa2080e7          	jalr	-1374(ra) # 80000d6e <acquire>
  ticks0 = ticks;
    800032d4:	00005917          	auipc	s2,0x5
    800032d8:	66c92903          	lw	s2,1644(s2) # 80008940 <ticks>
  while (ticks - ticks0 < n)
    800032dc:	fcc42783          	lw	a5,-52(s0)
    800032e0:	cf9d                	beqz	a5,8000331e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032e2:	00234997          	auipc	s3,0x234
    800032e6:	11698993          	addi	s3,s3,278 # 802373f8 <tickslock>
    800032ea:	00005497          	auipc	s1,0x5
    800032ee:	65648493          	addi	s1,s1,1622 # 80008940 <ticks>
    if (killed(myproc()))
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	894080e7          	jalr	-1900(ra) # 80001b86 <myproc>
    800032fa:	fffff097          	auipc	ra,0xfffff
    800032fe:	348080e7          	jalr	840(ra) # 80002642 <killed>
    80003302:	ed15                	bnez	a0,8000333e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003304:	85ce                	mv	a1,s3
    80003306:	8526                	mv	a0,s1
    80003308:	fffff097          	auipc	ra,0xfffff
    8000330c:	086080e7          	jalr	134(ra) # 8000238e <sleep>
  while (ticks - ticks0 < n)
    80003310:	409c                	lw	a5,0(s1)
    80003312:	412787bb          	subw	a5,a5,s2
    80003316:	fcc42703          	lw	a4,-52(s0)
    8000331a:	fce7ece3          	bltu	a5,a4,800032f2 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000331e:	00234517          	auipc	a0,0x234
    80003322:	0da50513          	addi	a0,a0,218 # 802373f8 <tickslock>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	afc080e7          	jalr	-1284(ra) # 80000e22 <release>
  return 0;
    8000332e:	4501                	li	a0,0
}
    80003330:	70e2                	ld	ra,56(sp)
    80003332:	7442                	ld	s0,48(sp)
    80003334:	74a2                	ld	s1,40(sp)
    80003336:	7902                	ld	s2,32(sp)
    80003338:	69e2                	ld	s3,24(sp)
    8000333a:	6121                	addi	sp,sp,64
    8000333c:	8082                	ret
      release(&tickslock);
    8000333e:	00234517          	auipc	a0,0x234
    80003342:	0ba50513          	addi	a0,a0,186 # 802373f8 <tickslock>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	adc080e7          	jalr	-1316(ra) # 80000e22 <release>
      return -1;
    8000334e:	557d                	li	a0,-1
    80003350:	b7c5                	j	80003330 <sys_sleep+0x88>

0000000080003352 <sys_kill>:

uint64
sys_kill(void)
{
    80003352:	1101                	addi	sp,sp,-32
    80003354:	ec06                	sd	ra,24(sp)
    80003356:	e822                	sd	s0,16(sp)
    80003358:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000335a:	fec40593          	addi	a1,s0,-20
    8000335e:	4501                	li	a0,0
    80003360:	00000097          	auipc	ra,0x0
    80003364:	d9a080e7          	jalr	-614(ra) # 800030fa <argint>
  return kill(pid);
    80003368:	fec42503          	lw	a0,-20(s0)
    8000336c:	fffff097          	auipc	ra,0xfffff
    80003370:	238080e7          	jalr	568(ra) # 800025a4 <kill>
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	6105                	addi	sp,sp,32
    8000337a:	8082                	ret

000000008000337c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003386:	00234517          	auipc	a0,0x234
    8000338a:	07250513          	addi	a0,a0,114 # 802373f8 <tickslock>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	9e0080e7          	jalr	-1568(ra) # 80000d6e <acquire>
  xticks = ticks;
    80003396:	00005497          	auipc	s1,0x5
    8000339a:	5aa4a483          	lw	s1,1450(s1) # 80008940 <ticks>
  release(&tickslock);
    8000339e:	00234517          	auipc	a0,0x234
    800033a2:	05a50513          	addi	a0,a0,90 # 802373f8 <tickslock>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	a7c080e7          	jalr	-1412(ra) # 80000e22 <release>
  return xticks;
}
    800033ae:	02049513          	slli	a0,s1,0x20
    800033b2:	9101                	srli	a0,a0,0x20
    800033b4:	60e2                	ld	ra,24(sp)
    800033b6:	6442                	ld	s0,16(sp)
    800033b8:	64a2                	ld	s1,8(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret

00000000800033be <sys_waitx>:

uint64
sys_waitx(void)
{
    800033be:	7139                	addi	sp,sp,-64
    800033c0:	fc06                	sd	ra,56(sp)
    800033c2:	f822                	sd	s0,48(sp)
    800033c4:	f426                	sd	s1,40(sp)
    800033c6:	f04a                	sd	s2,32(sp)
    800033c8:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800033ca:	fd840593          	addi	a1,s0,-40
    800033ce:	4501                	li	a0,0
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	d4a080e7          	jalr	-694(ra) # 8000311a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800033d8:	fd040593          	addi	a1,s0,-48
    800033dc:	4505                	li	a0,1
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	d3c080e7          	jalr	-708(ra) # 8000311a <argaddr>
  argaddr(2, &addr2);
    800033e6:	fc840593          	addi	a1,s0,-56
    800033ea:	4509                	li	a0,2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	d2e080e7          	jalr	-722(ra) # 8000311a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800033f4:	fc040613          	addi	a2,s0,-64
    800033f8:	fc440593          	addi	a1,s0,-60
    800033fc:	fd843503          	ld	a0,-40(s0)
    80003400:	fffff097          	auipc	ra,0xfffff
    80003404:	50a080e7          	jalr	1290(ra) # 8000290a <waitx>
    80003408:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	77c080e7          	jalr	1916(ra) # 80001b86 <myproc>
    80003412:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003414:	4691                	li	a3,4
    80003416:	fc440613          	addi	a2,s0,-60
    8000341a:	fd043583          	ld	a1,-48(s0)
    8000341e:	6928                	ld	a0,80(a0)
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	3ee080e7          	jalr	1006(ra) # 8000180e <copyout>
    return -1;
    80003428:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000342a:	00054f63          	bltz	a0,80003448 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000342e:	4691                	li	a3,4
    80003430:	fc040613          	addi	a2,s0,-64
    80003434:	fc843583          	ld	a1,-56(s0)
    80003438:	68a8                	ld	a0,80(s1)
    8000343a:	ffffe097          	auipc	ra,0xffffe
    8000343e:	3d4080e7          	jalr	980(ra) # 8000180e <copyout>
    80003442:	00054a63          	bltz	a0,80003456 <sys_waitx+0x98>
    return -1;
  return ret;
    80003446:	87ca                	mv	a5,s2
}
    80003448:	853e                	mv	a0,a5
    8000344a:	70e2                	ld	ra,56(sp)
    8000344c:	7442                	ld	s0,48(sp)
    8000344e:	74a2                	ld	s1,40(sp)
    80003450:	7902                	ld	s2,32(sp)
    80003452:	6121                	addi	sp,sp,64
    80003454:	8082                	ret
    return -1;
    80003456:	57fd                	li	a5,-1
    80003458:	bfc5                	j	80003448 <sys_waitx+0x8a>

000000008000345a <sys_set_priority>:

uint64
sys_set_priority(void)
{
    8000345a:	711d                	addi	sp,sp,-96
    8000345c:	ec86                	sd	ra,88(sp)
    8000345e:	e8a2                	sd	s0,80(sp)
    80003460:	e4a6                	sd	s1,72(sp)
    80003462:	e0ca                	sd	s2,64(sp)
    80003464:	fc4e                	sd	s3,56(sp)
    80003466:	f852                	sd	s4,48(sp)
    80003468:	f456                	sd	s5,40(sp)
    8000346a:	f05a                	sd	s6,32(sp)
    8000346c:	ec5e                	sd	s7,24(sp)
    8000346e:	e862                	sd	s8,16(sp)
    80003470:	1080                	addi	s0,sp,96
  int priority, pid, oldpriority=101;
  argint(1, &priority);
    80003472:	fac40593          	addi	a1,s0,-84
    80003476:	4505                	li	a0,1
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	c82080e7          	jalr	-894(ra) # 800030fa <argint>
  argint(0, &pid);
    80003480:	fa840593          	addi	a1,s0,-88
    80003484:	4501                	li	a0,0
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	c74080e7          	jalr	-908(ra) # 800030fa <argint>

  if (priority < 0 || priority > 100)
    8000348e:	fac42703          	lw	a4,-84(s0)
    80003492:	06400793          	li	a5,100
    80003496:	02e7e463          	bltu	a5,a4,800034be <sys_set_priority+0x64>
    printf("Invalid priority\n");
    return -1;
  }
  struct proc *p;
  int old_dp = -1;
  int new_dp = -1;
    8000349a:	5c7d                	li	s8,-1
  int old_dp = -1;
    8000349c:	5a7d                	li	s4,-1

  for (p = proc; p < &proc[NPROC]; p++)
    8000349e:	0022e497          	auipc	s1,0x22e
    800034a2:	b5a48493          	addi	s1,s1,-1190 # 80230ff8 <proc>
  int priority, pid, oldpriority=101;
    800034a6:	06500993          	li	s3,101
    {
      old_dp = p->dynamic_priority;

      oldpriority = p->static_priority;
      p->static_priority = priority;
      p->rbi = 25;
    800034aa:	4b65                	li	s6,25
    800034ac:	06400a93          	li	s5,100
    800034b0:	06400b93          	li	s7,100
  for (p = proc; p < &proc[NPROC]; p++)
    800034b4:	00234917          	auipc	s2,0x234
    800034b8:	f4490913          	addi	s2,s2,-188 # 802373f8 <tickslock>
    800034bc:	a805                	j	800034ec <sys_set_priority+0x92>
    printf("Invalid priority\n");
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	08250513          	addi	a0,a0,130 # 80008540 <syscalls+0xc8>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	0c4080e7          	jalr	196(ra) # 8000058a <printf>
    return -1;
    800034ce:	557d                	li	a0,-1
    800034d0:	a8a1                	j	80003528 <sys_set_priority+0xce>
    800034d2:	00078c1b          	sext.w	s8,a5

      if (p->static_priority + p->rbi <= 100)
        new_dp = p->static_priority + p->rbi;
      else
        new_dp = 100;
      p->dynamic_priority = new_dp;
    800034d6:	16f4ac23          	sw	a5,376(s1)
    }
    release(&p->lock);
    800034da:	8526                	mv	a0,s1
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	946080e7          	jalr	-1722(ra) # 80000e22 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800034e4:	19048493          	addi	s1,s1,400
    800034e8:	03248d63          	beq	s1,s2,80003522 <sys_set_priority+0xc8>
    acquire(&p->lock);
    800034ec:	8526                	mv	a0,s1
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	880080e7          	jalr	-1920(ra) # 80000d6e <acquire>
    if (p->pid == pid)
    800034f6:	5898                	lw	a4,48(s1)
    800034f8:	fa842783          	lw	a5,-88(s0)
    800034fc:	fcf71fe3          	bne	a4,a5,800034da <sys_set_priority+0x80>
      old_dp = p->dynamic_priority;
    80003500:	1784aa03          	lw	s4,376(s1)
      oldpriority = p->static_priority;
    80003504:	1744a983          	lw	s3,372(s1)
      p->static_priority = priority;
    80003508:	fac42783          	lw	a5,-84(s0)
    8000350c:	16f4aa23          	sw	a5,372(s1)
      p->rbi = 25;
    80003510:	1764ae23          	sw	s6,380(s1)
      if (p->static_priority + p->rbi <= 100)
    80003514:	27e5                	addiw	a5,a5,25
    80003516:	0007871b          	sext.w	a4,a5
    8000351a:	faeadce3          	bge	s5,a4,800034d2 <sys_set_priority+0x78>
    8000351e:	87de                	mv	a5,s7
    80003520:	bf4d                	j	800034d2 <sys_set_priority+0x78>
  }
  if (new_dp < old_dp)
    80003522:	014c4f63          	blt	s8,s4,80003540 <sys_set_priority+0xe6>
  {
    yield();
  }
  return oldpriority;
    80003526:	854e                	mv	a0,s3
    80003528:	60e6                	ld	ra,88(sp)
    8000352a:	6446                	ld	s0,80(sp)
    8000352c:	64a6                	ld	s1,72(sp)
    8000352e:	6906                	ld	s2,64(sp)
    80003530:	79e2                	ld	s3,56(sp)
    80003532:	7a42                	ld	s4,48(sp)
    80003534:	7aa2                	ld	s5,40(sp)
    80003536:	7b02                	ld	s6,32(sp)
    80003538:	6be2                	ld	s7,24(sp)
    8000353a:	6c42                	ld	s8,16(sp)
    8000353c:	6125                	addi	sp,sp,96
    8000353e:	8082                	ret
    yield();
    80003540:	fffff097          	auipc	ra,0xfffff
    80003544:	e12080e7          	jalr	-494(ra) # 80002352 <yield>
    80003548:	bff9                	j	80003526 <sys_set_priority+0xcc>

000000008000354a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000354a:	7179                	addi	sp,sp,-48
    8000354c:	f406                	sd	ra,40(sp)
    8000354e:	f022                	sd	s0,32(sp)
    80003550:	ec26                	sd	s1,24(sp)
    80003552:	e84a                	sd	s2,16(sp)
    80003554:	e44e                	sd	s3,8(sp)
    80003556:	e052                	sd	s4,0(sp)
    80003558:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000355a:	00005597          	auipc	a1,0x5
    8000355e:	ffe58593          	addi	a1,a1,-2 # 80008558 <syscalls+0xe0>
    80003562:	00234517          	auipc	a0,0x234
    80003566:	eae50513          	addi	a0,a0,-338 # 80237410 <bcache>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	774080e7          	jalr	1908(ra) # 80000cde <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003572:	0023c797          	auipc	a5,0x23c
    80003576:	e9e78793          	addi	a5,a5,-354 # 8023f410 <bcache+0x8000>
    8000357a:	0023c717          	auipc	a4,0x23c
    8000357e:	0fe70713          	addi	a4,a4,254 # 8023f678 <bcache+0x8268>
    80003582:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003586:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000358a:	00234497          	auipc	s1,0x234
    8000358e:	e9e48493          	addi	s1,s1,-354 # 80237428 <bcache+0x18>
    b->next = bcache.head.next;
    80003592:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003594:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003596:	00005a17          	auipc	s4,0x5
    8000359a:	fcaa0a13          	addi	s4,s4,-54 # 80008560 <syscalls+0xe8>
    b->next = bcache.head.next;
    8000359e:	2b893783          	ld	a5,696(s2)
    800035a2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035a4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035a8:	85d2                	mv	a1,s4
    800035aa:	01048513          	addi	a0,s1,16
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	4c8080e7          	jalr	1224(ra) # 80004a76 <initsleeplock>
    bcache.head.next->prev = b;
    800035b6:	2b893783          	ld	a5,696(s2)
    800035ba:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035bc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035c0:	45848493          	addi	s1,s1,1112
    800035c4:	fd349de3          	bne	s1,s3,8000359e <binit+0x54>
  }
}
    800035c8:	70a2                	ld	ra,40(sp)
    800035ca:	7402                	ld	s0,32(sp)
    800035cc:	64e2                	ld	s1,24(sp)
    800035ce:	6942                	ld	s2,16(sp)
    800035d0:	69a2                	ld	s3,8(sp)
    800035d2:	6a02                	ld	s4,0(sp)
    800035d4:	6145                	addi	sp,sp,48
    800035d6:	8082                	ret

00000000800035d8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035d8:	7179                	addi	sp,sp,-48
    800035da:	f406                	sd	ra,40(sp)
    800035dc:	f022                	sd	s0,32(sp)
    800035de:	ec26                	sd	s1,24(sp)
    800035e0:	e84a                	sd	s2,16(sp)
    800035e2:	e44e                	sd	s3,8(sp)
    800035e4:	1800                	addi	s0,sp,48
    800035e6:	892a                	mv	s2,a0
    800035e8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035ea:	00234517          	auipc	a0,0x234
    800035ee:	e2650513          	addi	a0,a0,-474 # 80237410 <bcache>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	77c080e7          	jalr	1916(ra) # 80000d6e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035fa:	0023c497          	auipc	s1,0x23c
    800035fe:	0ce4b483          	ld	s1,206(s1) # 8023f6c8 <bcache+0x82b8>
    80003602:	0023c797          	auipc	a5,0x23c
    80003606:	07678793          	addi	a5,a5,118 # 8023f678 <bcache+0x8268>
    8000360a:	02f48f63          	beq	s1,a5,80003648 <bread+0x70>
    8000360e:	873e                	mv	a4,a5
    80003610:	a021                	j	80003618 <bread+0x40>
    80003612:	68a4                	ld	s1,80(s1)
    80003614:	02e48a63          	beq	s1,a4,80003648 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003618:	449c                	lw	a5,8(s1)
    8000361a:	ff279ce3          	bne	a5,s2,80003612 <bread+0x3a>
    8000361e:	44dc                	lw	a5,12(s1)
    80003620:	ff3799e3          	bne	a5,s3,80003612 <bread+0x3a>
      b->refcnt++;
    80003624:	40bc                	lw	a5,64(s1)
    80003626:	2785                	addiw	a5,a5,1
    80003628:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000362a:	00234517          	auipc	a0,0x234
    8000362e:	de650513          	addi	a0,a0,-538 # 80237410 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	7f0080e7          	jalr	2032(ra) # 80000e22 <release>
      acquiresleep(&b->lock);
    8000363a:	01048513          	addi	a0,s1,16
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	472080e7          	jalr	1138(ra) # 80004ab0 <acquiresleep>
      return b;
    80003646:	a8b9                	j	800036a4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003648:	0023c497          	auipc	s1,0x23c
    8000364c:	0784b483          	ld	s1,120(s1) # 8023f6c0 <bcache+0x82b0>
    80003650:	0023c797          	auipc	a5,0x23c
    80003654:	02878793          	addi	a5,a5,40 # 8023f678 <bcache+0x8268>
    80003658:	00f48863          	beq	s1,a5,80003668 <bread+0x90>
    8000365c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000365e:	40bc                	lw	a5,64(s1)
    80003660:	cf81                	beqz	a5,80003678 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003662:	64a4                	ld	s1,72(s1)
    80003664:	fee49de3          	bne	s1,a4,8000365e <bread+0x86>
  panic("bget: no buffers");
    80003668:	00005517          	auipc	a0,0x5
    8000366c:	f0050513          	addi	a0,a0,-256 # 80008568 <syscalls+0xf0>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	ed0080e7          	jalr	-304(ra) # 80000540 <panic>
      b->dev = dev;
    80003678:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000367c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003680:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003684:	4785                	li	a5,1
    80003686:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003688:	00234517          	auipc	a0,0x234
    8000368c:	d8850513          	addi	a0,a0,-632 # 80237410 <bcache>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	792080e7          	jalr	1938(ra) # 80000e22 <release>
      acquiresleep(&b->lock);
    80003698:	01048513          	addi	a0,s1,16
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	414080e7          	jalr	1044(ra) # 80004ab0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036a4:	409c                	lw	a5,0(s1)
    800036a6:	cb89                	beqz	a5,800036b8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036a8:	8526                	mv	a0,s1
    800036aa:	70a2                	ld	ra,40(sp)
    800036ac:	7402                	ld	s0,32(sp)
    800036ae:	64e2                	ld	s1,24(sp)
    800036b0:	6942                	ld	s2,16(sp)
    800036b2:	69a2                	ld	s3,8(sp)
    800036b4:	6145                	addi	sp,sp,48
    800036b6:	8082                	ret
    virtio_disk_rw(b, 0);
    800036b8:	4581                	li	a1,0
    800036ba:	8526                	mv	a0,s1
    800036bc:	00003097          	auipc	ra,0x3
    800036c0:	006080e7          	jalr	6(ra) # 800066c2 <virtio_disk_rw>
    b->valid = 1;
    800036c4:	4785                	li	a5,1
    800036c6:	c09c                	sw	a5,0(s1)
  return b;
    800036c8:	b7c5                	j	800036a8 <bread+0xd0>

00000000800036ca <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	1000                	addi	s0,sp,32
    800036d4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036d6:	0541                	addi	a0,a0,16
    800036d8:	00001097          	auipc	ra,0x1
    800036dc:	472080e7          	jalr	1138(ra) # 80004b4a <holdingsleep>
    800036e0:	cd01                	beqz	a0,800036f8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036e2:	4585                	li	a1,1
    800036e4:	8526                	mv	a0,s1
    800036e6:	00003097          	auipc	ra,0x3
    800036ea:	fdc080e7          	jalr	-36(ra) # 800066c2 <virtio_disk_rw>
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6105                	addi	sp,sp,32
    800036f6:	8082                	ret
    panic("bwrite");
    800036f8:	00005517          	auipc	a0,0x5
    800036fc:	e8850513          	addi	a0,a0,-376 # 80008580 <syscalls+0x108>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	e40080e7          	jalr	-448(ra) # 80000540 <panic>

0000000080003708 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003708:	1101                	addi	sp,sp,-32
    8000370a:	ec06                	sd	ra,24(sp)
    8000370c:	e822                	sd	s0,16(sp)
    8000370e:	e426                	sd	s1,8(sp)
    80003710:	e04a                	sd	s2,0(sp)
    80003712:	1000                	addi	s0,sp,32
    80003714:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003716:	01050913          	addi	s2,a0,16
    8000371a:	854a                	mv	a0,s2
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	42e080e7          	jalr	1070(ra) # 80004b4a <holdingsleep>
    80003724:	c92d                	beqz	a0,80003796 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003726:	854a                	mv	a0,s2
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	3de080e7          	jalr	990(ra) # 80004b06 <releasesleep>

  acquire(&bcache.lock);
    80003730:	00234517          	auipc	a0,0x234
    80003734:	ce050513          	addi	a0,a0,-800 # 80237410 <bcache>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	636080e7          	jalr	1590(ra) # 80000d6e <acquire>
  b->refcnt--;
    80003740:	40bc                	lw	a5,64(s1)
    80003742:	37fd                	addiw	a5,a5,-1
    80003744:	0007871b          	sext.w	a4,a5
    80003748:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000374a:	eb05                	bnez	a4,8000377a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000374c:	68bc                	ld	a5,80(s1)
    8000374e:	64b8                	ld	a4,72(s1)
    80003750:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003752:	64bc                	ld	a5,72(s1)
    80003754:	68b8                	ld	a4,80(s1)
    80003756:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003758:	0023c797          	auipc	a5,0x23c
    8000375c:	cb878793          	addi	a5,a5,-840 # 8023f410 <bcache+0x8000>
    80003760:	2b87b703          	ld	a4,696(a5)
    80003764:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003766:	0023c717          	auipc	a4,0x23c
    8000376a:	f1270713          	addi	a4,a4,-238 # 8023f678 <bcache+0x8268>
    8000376e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003770:	2b87b703          	ld	a4,696(a5)
    80003774:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003776:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000377a:	00234517          	auipc	a0,0x234
    8000377e:	c9650513          	addi	a0,a0,-874 # 80237410 <bcache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	6a0080e7          	jalr	1696(ra) # 80000e22 <release>
}
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6902                	ld	s2,0(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret
    panic("brelse");
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	df250513          	addi	a0,a0,-526 # 80008588 <syscalls+0x110>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	da2080e7          	jalr	-606(ra) # 80000540 <panic>

00000000800037a6 <bpin>:

void
bpin(struct buf *b) {
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b2:	00234517          	auipc	a0,0x234
    800037b6:	c5e50513          	addi	a0,a0,-930 # 80237410 <bcache>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	5b4080e7          	jalr	1460(ra) # 80000d6e <acquire>
  b->refcnt++;
    800037c2:	40bc                	lw	a5,64(s1)
    800037c4:	2785                	addiw	a5,a5,1
    800037c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037c8:	00234517          	auipc	a0,0x234
    800037cc:	c4850513          	addi	a0,a0,-952 # 80237410 <bcache>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	652080e7          	jalr	1618(ra) # 80000e22 <release>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret

00000000800037e2 <bunpin>:

void
bunpin(struct buf *b) {
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	1000                	addi	s0,sp,32
    800037ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037ee:	00234517          	auipc	a0,0x234
    800037f2:	c2250513          	addi	a0,a0,-990 # 80237410 <bcache>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	578080e7          	jalr	1400(ra) # 80000d6e <acquire>
  b->refcnt--;
    800037fe:	40bc                	lw	a5,64(s1)
    80003800:	37fd                	addiw	a5,a5,-1
    80003802:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003804:	00234517          	auipc	a0,0x234
    80003808:	c0c50513          	addi	a0,a0,-1012 # 80237410 <bcache>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	616080e7          	jalr	1558(ra) # 80000e22 <release>
}
    80003814:	60e2                	ld	ra,24(sp)
    80003816:	6442                	ld	s0,16(sp)
    80003818:	64a2                	ld	s1,8(sp)
    8000381a:	6105                	addi	sp,sp,32
    8000381c:	8082                	ret

000000008000381e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000381e:	1101                	addi	sp,sp,-32
    80003820:	ec06                	sd	ra,24(sp)
    80003822:	e822                	sd	s0,16(sp)
    80003824:	e426                	sd	s1,8(sp)
    80003826:	e04a                	sd	s2,0(sp)
    80003828:	1000                	addi	s0,sp,32
    8000382a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000382c:	00d5d59b          	srliw	a1,a1,0xd
    80003830:	0023c797          	auipc	a5,0x23c
    80003834:	2bc7a783          	lw	a5,700(a5) # 8023faec <sb+0x1c>
    80003838:	9dbd                	addw	a1,a1,a5
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	d9e080e7          	jalr	-610(ra) # 800035d8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003842:	0074f713          	andi	a4,s1,7
    80003846:	4785                	li	a5,1
    80003848:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000384c:	14ce                	slli	s1,s1,0x33
    8000384e:	90d9                	srli	s1,s1,0x36
    80003850:	00950733          	add	a4,a0,s1
    80003854:	05874703          	lbu	a4,88(a4)
    80003858:	00e7f6b3          	and	a3,a5,a4
    8000385c:	c69d                	beqz	a3,8000388a <bfree+0x6c>
    8000385e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003860:	94aa                	add	s1,s1,a0
    80003862:	fff7c793          	not	a5,a5
    80003866:	8f7d                	and	a4,a4,a5
    80003868:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	126080e7          	jalr	294(ra) # 80004992 <log_write>
  brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	e92080e7          	jalr	-366(ra) # 80003708 <brelse>
}
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6902                	ld	s2,0(sp)
    80003886:	6105                	addi	sp,sp,32
    80003888:	8082                	ret
    panic("freeing free block");
    8000388a:	00005517          	auipc	a0,0x5
    8000388e:	d0650513          	addi	a0,a0,-762 # 80008590 <syscalls+0x118>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	cae080e7          	jalr	-850(ra) # 80000540 <panic>

000000008000389a <balloc>:
{
    8000389a:	711d                	addi	sp,sp,-96
    8000389c:	ec86                	sd	ra,88(sp)
    8000389e:	e8a2                	sd	s0,80(sp)
    800038a0:	e4a6                	sd	s1,72(sp)
    800038a2:	e0ca                	sd	s2,64(sp)
    800038a4:	fc4e                	sd	s3,56(sp)
    800038a6:	f852                	sd	s4,48(sp)
    800038a8:	f456                	sd	s5,40(sp)
    800038aa:	f05a                	sd	s6,32(sp)
    800038ac:	ec5e                	sd	s7,24(sp)
    800038ae:	e862                	sd	s8,16(sp)
    800038b0:	e466                	sd	s9,8(sp)
    800038b2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038b4:	0023c797          	auipc	a5,0x23c
    800038b8:	2207a783          	lw	a5,544(a5) # 8023fad4 <sb+0x4>
    800038bc:	cff5                	beqz	a5,800039b8 <balloc+0x11e>
    800038be:	8baa                	mv	s7,a0
    800038c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038c2:	0023cb17          	auipc	s6,0x23c
    800038c6:	20eb0b13          	addi	s6,s6,526 # 8023fad0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038d0:	6c89                	lui	s9,0x2
    800038d2:	a061                	j	8000395a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038d4:	97ca                	add	a5,a5,s2
    800038d6:	8e55                	or	a2,a2,a3
    800038d8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	0b4080e7          	jalr	180(ra) # 80004992 <log_write>
        brelse(bp);
    800038e6:	854a                	mv	a0,s2
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	e20080e7          	jalr	-480(ra) # 80003708 <brelse>
  bp = bread(dev, bno);
    800038f0:	85a6                	mv	a1,s1
    800038f2:	855e                	mv	a0,s7
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	ce4080e7          	jalr	-796(ra) # 800035d8 <bread>
    800038fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038fe:	40000613          	li	a2,1024
    80003902:	4581                	li	a1,0
    80003904:	05850513          	addi	a0,a0,88
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	562080e7          	jalr	1378(ra) # 80000e6a <memset>
  log_write(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	080080e7          	jalr	128(ra) # 80004992 <log_write>
  brelse(bp);
    8000391a:	854a                	mv	a0,s2
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	dec080e7          	jalr	-532(ra) # 80003708 <brelse>
}
    80003924:	8526                	mv	a0,s1
    80003926:	60e6                	ld	ra,88(sp)
    80003928:	6446                	ld	s0,80(sp)
    8000392a:	64a6                	ld	s1,72(sp)
    8000392c:	6906                	ld	s2,64(sp)
    8000392e:	79e2                	ld	s3,56(sp)
    80003930:	7a42                	ld	s4,48(sp)
    80003932:	7aa2                	ld	s5,40(sp)
    80003934:	7b02                	ld	s6,32(sp)
    80003936:	6be2                	ld	s7,24(sp)
    80003938:	6c42                	ld	s8,16(sp)
    8000393a:	6ca2                	ld	s9,8(sp)
    8000393c:	6125                	addi	sp,sp,96
    8000393e:	8082                	ret
    brelse(bp);
    80003940:	854a                	mv	a0,s2
    80003942:	00000097          	auipc	ra,0x0
    80003946:	dc6080e7          	jalr	-570(ra) # 80003708 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000394a:	015c87bb          	addw	a5,s9,s5
    8000394e:	00078a9b          	sext.w	s5,a5
    80003952:	004b2703          	lw	a4,4(s6)
    80003956:	06eaf163          	bgeu	s5,a4,800039b8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000395a:	41fad79b          	sraiw	a5,s5,0x1f
    8000395e:	0137d79b          	srliw	a5,a5,0x13
    80003962:	015787bb          	addw	a5,a5,s5
    80003966:	40d7d79b          	sraiw	a5,a5,0xd
    8000396a:	01cb2583          	lw	a1,28(s6)
    8000396e:	9dbd                	addw	a1,a1,a5
    80003970:	855e                	mv	a0,s7
    80003972:	00000097          	auipc	ra,0x0
    80003976:	c66080e7          	jalr	-922(ra) # 800035d8 <bread>
    8000397a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000397c:	004b2503          	lw	a0,4(s6)
    80003980:	000a849b          	sext.w	s1,s5
    80003984:	8762                	mv	a4,s8
    80003986:	faa4fde3          	bgeu	s1,a0,80003940 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000398a:	00777693          	andi	a3,a4,7
    8000398e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003992:	41f7579b          	sraiw	a5,a4,0x1f
    80003996:	01d7d79b          	srliw	a5,a5,0x1d
    8000399a:	9fb9                	addw	a5,a5,a4
    8000399c:	4037d79b          	sraiw	a5,a5,0x3
    800039a0:	00f90633          	add	a2,s2,a5
    800039a4:	05864603          	lbu	a2,88(a2)
    800039a8:	00c6f5b3          	and	a1,a3,a2
    800039ac:	d585                	beqz	a1,800038d4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ae:	2705                	addiw	a4,a4,1
    800039b0:	2485                	addiw	s1,s1,1
    800039b2:	fd471ae3          	bne	a4,s4,80003986 <balloc+0xec>
    800039b6:	b769                	j	80003940 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800039b8:	00005517          	auipc	a0,0x5
    800039bc:	bf050513          	addi	a0,a0,-1040 # 800085a8 <syscalls+0x130>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	bca080e7          	jalr	-1078(ra) # 8000058a <printf>
  return 0;
    800039c8:	4481                	li	s1,0
    800039ca:	bfa9                	j	80003924 <balloc+0x8a>

00000000800039cc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800039cc:	7179                	addi	sp,sp,-48
    800039ce:	f406                	sd	ra,40(sp)
    800039d0:	f022                	sd	s0,32(sp)
    800039d2:	ec26                	sd	s1,24(sp)
    800039d4:	e84a                	sd	s2,16(sp)
    800039d6:	e44e                	sd	s3,8(sp)
    800039d8:	e052                	sd	s4,0(sp)
    800039da:	1800                	addi	s0,sp,48
    800039dc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039de:	47ad                	li	a5,11
    800039e0:	02b7e863          	bltu	a5,a1,80003a10 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800039e4:	02059793          	slli	a5,a1,0x20
    800039e8:	01e7d593          	srli	a1,a5,0x1e
    800039ec:	00b504b3          	add	s1,a0,a1
    800039f0:	0504a903          	lw	s2,80(s1)
    800039f4:	06091e63          	bnez	s2,80003a70 <bmap+0xa4>
      addr = balloc(ip->dev);
    800039f8:	4108                	lw	a0,0(a0)
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	ea0080e7          	jalr	-352(ra) # 8000389a <balloc>
    80003a02:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a06:	06090563          	beqz	s2,80003a70 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003a0a:	0524a823          	sw	s2,80(s1)
    80003a0e:	a08d                	j	80003a70 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a10:	ff45849b          	addiw	s1,a1,-12
    80003a14:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a18:	0ff00793          	li	a5,255
    80003a1c:	08e7e563          	bltu	a5,a4,80003aa6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a20:	08052903          	lw	s2,128(a0)
    80003a24:	00091d63          	bnez	s2,80003a3e <bmap+0x72>
      addr = balloc(ip->dev);
    80003a28:	4108                	lw	a0,0(a0)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	e70080e7          	jalr	-400(ra) # 8000389a <balloc>
    80003a32:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a36:	02090d63          	beqz	s2,80003a70 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a3a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a3e:	85ca                	mv	a1,s2
    80003a40:	0009a503          	lw	a0,0(s3)
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	b94080e7          	jalr	-1132(ra) # 800035d8 <bread>
    80003a4c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a4e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a52:	02049713          	slli	a4,s1,0x20
    80003a56:	01e75593          	srli	a1,a4,0x1e
    80003a5a:	00b784b3          	add	s1,a5,a1
    80003a5e:	0004a903          	lw	s2,0(s1)
    80003a62:	02090063          	beqz	s2,80003a82 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a66:	8552                	mv	a0,s4
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	ca0080e7          	jalr	-864(ra) # 80003708 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a70:	854a                	mv	a0,s2
    80003a72:	70a2                	ld	ra,40(sp)
    80003a74:	7402                	ld	s0,32(sp)
    80003a76:	64e2                	ld	s1,24(sp)
    80003a78:	6942                	ld	s2,16(sp)
    80003a7a:	69a2                	ld	s3,8(sp)
    80003a7c:	6a02                	ld	s4,0(sp)
    80003a7e:	6145                	addi	sp,sp,48
    80003a80:	8082                	ret
      addr = balloc(ip->dev);
    80003a82:	0009a503          	lw	a0,0(s3)
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	e14080e7          	jalr	-492(ra) # 8000389a <balloc>
    80003a8e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a92:	fc090ae3          	beqz	s2,80003a66 <bmap+0x9a>
        a[bn] = addr;
    80003a96:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a9a:	8552                	mv	a0,s4
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	ef6080e7          	jalr	-266(ra) # 80004992 <log_write>
    80003aa4:	b7c9                	j	80003a66 <bmap+0x9a>
  panic("bmap: out of range");
    80003aa6:	00005517          	auipc	a0,0x5
    80003aaa:	b1a50513          	addi	a0,a0,-1254 # 800085c0 <syscalls+0x148>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	a92080e7          	jalr	-1390(ra) # 80000540 <panic>

0000000080003ab6 <iget>:
{
    80003ab6:	7179                	addi	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	e052                	sd	s4,0(sp)
    80003ac4:	1800                	addi	s0,sp,48
    80003ac6:	89aa                	mv	s3,a0
    80003ac8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003aca:	0023c517          	auipc	a0,0x23c
    80003ace:	02650513          	addi	a0,a0,38 # 8023faf0 <itable>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	29c080e7          	jalr	668(ra) # 80000d6e <acquire>
  empty = 0;
    80003ada:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003adc:	0023c497          	auipc	s1,0x23c
    80003ae0:	02c48493          	addi	s1,s1,44 # 8023fb08 <itable+0x18>
    80003ae4:	0023e697          	auipc	a3,0x23e
    80003ae8:	ab468693          	addi	a3,a3,-1356 # 80241598 <log>
    80003aec:	a039                	j	80003afa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aee:	02090b63          	beqz	s2,80003b24 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003af2:	08848493          	addi	s1,s1,136
    80003af6:	02d48a63          	beq	s1,a3,80003b2a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003afa:	449c                	lw	a5,8(s1)
    80003afc:	fef059e3          	blez	a5,80003aee <iget+0x38>
    80003b00:	4098                	lw	a4,0(s1)
    80003b02:	ff3716e3          	bne	a4,s3,80003aee <iget+0x38>
    80003b06:	40d8                	lw	a4,4(s1)
    80003b08:	ff4713e3          	bne	a4,s4,80003aee <iget+0x38>
      ip->ref++;
    80003b0c:	2785                	addiw	a5,a5,1
    80003b0e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b10:	0023c517          	auipc	a0,0x23c
    80003b14:	fe050513          	addi	a0,a0,-32 # 8023faf0 <itable>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	30a080e7          	jalr	778(ra) # 80000e22 <release>
      return ip;
    80003b20:	8926                	mv	s2,s1
    80003b22:	a03d                	j	80003b50 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b24:	f7f9                	bnez	a5,80003af2 <iget+0x3c>
    80003b26:	8926                	mv	s2,s1
    80003b28:	b7e9                	j	80003af2 <iget+0x3c>
  if(empty == 0)
    80003b2a:	02090c63          	beqz	s2,80003b62 <iget+0xac>
  ip->dev = dev;
    80003b2e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b32:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b36:	4785                	li	a5,1
    80003b38:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b3c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b40:	0023c517          	auipc	a0,0x23c
    80003b44:	fb050513          	addi	a0,a0,-80 # 8023faf0 <itable>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	2da080e7          	jalr	730(ra) # 80000e22 <release>
}
    80003b50:	854a                	mv	a0,s2
    80003b52:	70a2                	ld	ra,40(sp)
    80003b54:	7402                	ld	s0,32(sp)
    80003b56:	64e2                	ld	s1,24(sp)
    80003b58:	6942                	ld	s2,16(sp)
    80003b5a:	69a2                	ld	s3,8(sp)
    80003b5c:	6a02                	ld	s4,0(sp)
    80003b5e:	6145                	addi	sp,sp,48
    80003b60:	8082                	ret
    panic("iget: no inodes");
    80003b62:	00005517          	auipc	a0,0x5
    80003b66:	a7650513          	addi	a0,a0,-1418 # 800085d8 <syscalls+0x160>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	9d6080e7          	jalr	-1578(ra) # 80000540 <panic>

0000000080003b72 <fsinit>:
fsinit(int dev) {
    80003b72:	7179                	addi	sp,sp,-48
    80003b74:	f406                	sd	ra,40(sp)
    80003b76:	f022                	sd	s0,32(sp)
    80003b78:	ec26                	sd	s1,24(sp)
    80003b7a:	e84a                	sd	s2,16(sp)
    80003b7c:	e44e                	sd	s3,8(sp)
    80003b7e:	1800                	addi	s0,sp,48
    80003b80:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b82:	4585                	li	a1,1
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	a54080e7          	jalr	-1452(ra) # 800035d8 <bread>
    80003b8c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b8e:	0023c997          	auipc	s3,0x23c
    80003b92:	f4298993          	addi	s3,s3,-190 # 8023fad0 <sb>
    80003b96:	02000613          	li	a2,32
    80003b9a:	05850593          	addi	a1,a0,88
    80003b9e:	854e                	mv	a0,s3
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	326080e7          	jalr	806(ra) # 80000ec6 <memmove>
  brelse(bp);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	b5e080e7          	jalr	-1186(ra) # 80003708 <brelse>
  if(sb.magic != FSMAGIC)
    80003bb2:	0009a703          	lw	a4,0(s3)
    80003bb6:	102037b7          	lui	a5,0x10203
    80003bba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bbe:	02f71263          	bne	a4,a5,80003be2 <fsinit+0x70>
  initlog(dev, &sb);
    80003bc2:	0023c597          	auipc	a1,0x23c
    80003bc6:	f0e58593          	addi	a1,a1,-242 # 8023fad0 <sb>
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	b4a080e7          	jalr	-1206(ra) # 80004716 <initlog>
}
    80003bd4:	70a2                	ld	ra,40(sp)
    80003bd6:	7402                	ld	s0,32(sp)
    80003bd8:	64e2                	ld	s1,24(sp)
    80003bda:	6942                	ld	s2,16(sp)
    80003bdc:	69a2                	ld	s3,8(sp)
    80003bde:	6145                	addi	sp,sp,48
    80003be0:	8082                	ret
    panic("invalid file system");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	a0650513          	addi	a0,a0,-1530 # 800085e8 <syscalls+0x170>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	956080e7          	jalr	-1706(ra) # 80000540 <panic>

0000000080003bf2 <iinit>:
{
    80003bf2:	7179                	addi	sp,sp,-48
    80003bf4:	f406                	sd	ra,40(sp)
    80003bf6:	f022                	sd	s0,32(sp)
    80003bf8:	ec26                	sd	s1,24(sp)
    80003bfa:	e84a                	sd	s2,16(sp)
    80003bfc:	e44e                	sd	s3,8(sp)
    80003bfe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c00:	00005597          	auipc	a1,0x5
    80003c04:	a0058593          	addi	a1,a1,-1536 # 80008600 <syscalls+0x188>
    80003c08:	0023c517          	auipc	a0,0x23c
    80003c0c:	ee850513          	addi	a0,a0,-280 # 8023faf0 <itable>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	0ce080e7          	jalr	206(ra) # 80000cde <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c18:	0023c497          	auipc	s1,0x23c
    80003c1c:	f0048493          	addi	s1,s1,-256 # 8023fb18 <itable+0x28>
    80003c20:	0023e997          	auipc	s3,0x23e
    80003c24:	98898993          	addi	s3,s3,-1656 # 802415a8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c28:	00005917          	auipc	s2,0x5
    80003c2c:	9e090913          	addi	s2,s2,-1568 # 80008608 <syscalls+0x190>
    80003c30:	85ca                	mv	a1,s2
    80003c32:	8526                	mv	a0,s1
    80003c34:	00001097          	auipc	ra,0x1
    80003c38:	e42080e7          	jalr	-446(ra) # 80004a76 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c3c:	08848493          	addi	s1,s1,136
    80003c40:	ff3498e3          	bne	s1,s3,80003c30 <iinit+0x3e>
}
    80003c44:	70a2                	ld	ra,40(sp)
    80003c46:	7402                	ld	s0,32(sp)
    80003c48:	64e2                	ld	s1,24(sp)
    80003c4a:	6942                	ld	s2,16(sp)
    80003c4c:	69a2                	ld	s3,8(sp)
    80003c4e:	6145                	addi	sp,sp,48
    80003c50:	8082                	ret

0000000080003c52 <ialloc>:
{
    80003c52:	715d                	addi	sp,sp,-80
    80003c54:	e486                	sd	ra,72(sp)
    80003c56:	e0a2                	sd	s0,64(sp)
    80003c58:	fc26                	sd	s1,56(sp)
    80003c5a:	f84a                	sd	s2,48(sp)
    80003c5c:	f44e                	sd	s3,40(sp)
    80003c5e:	f052                	sd	s4,32(sp)
    80003c60:	ec56                	sd	s5,24(sp)
    80003c62:	e85a                	sd	s6,16(sp)
    80003c64:	e45e                	sd	s7,8(sp)
    80003c66:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c68:	0023c717          	auipc	a4,0x23c
    80003c6c:	e7472703          	lw	a4,-396(a4) # 8023fadc <sb+0xc>
    80003c70:	4785                	li	a5,1
    80003c72:	04e7fa63          	bgeu	a5,a4,80003cc6 <ialloc+0x74>
    80003c76:	8aaa                	mv	s5,a0
    80003c78:	8bae                	mv	s7,a1
    80003c7a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c7c:	0023ca17          	auipc	s4,0x23c
    80003c80:	e54a0a13          	addi	s4,s4,-428 # 8023fad0 <sb>
    80003c84:	00048b1b          	sext.w	s6,s1
    80003c88:	0044d593          	srli	a1,s1,0x4
    80003c8c:	018a2783          	lw	a5,24(s4)
    80003c90:	9dbd                	addw	a1,a1,a5
    80003c92:	8556                	mv	a0,s5
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	944080e7          	jalr	-1724(ra) # 800035d8 <bread>
    80003c9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c9e:	05850993          	addi	s3,a0,88
    80003ca2:	00f4f793          	andi	a5,s1,15
    80003ca6:	079a                	slli	a5,a5,0x6
    80003ca8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003caa:	00099783          	lh	a5,0(s3)
    80003cae:	c3a1                	beqz	a5,80003cee <ialloc+0x9c>
    brelse(bp);
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	a58080e7          	jalr	-1448(ra) # 80003708 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb8:	0485                	addi	s1,s1,1
    80003cba:	00ca2703          	lw	a4,12(s4)
    80003cbe:	0004879b          	sext.w	a5,s1
    80003cc2:	fce7e1e3          	bltu	a5,a4,80003c84 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003cc6:	00005517          	auipc	a0,0x5
    80003cca:	94a50513          	addi	a0,a0,-1718 # 80008610 <syscalls+0x198>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	8bc080e7          	jalr	-1860(ra) # 8000058a <printf>
  return 0;
    80003cd6:	4501                	li	a0,0
}
    80003cd8:	60a6                	ld	ra,72(sp)
    80003cda:	6406                	ld	s0,64(sp)
    80003cdc:	74e2                	ld	s1,56(sp)
    80003cde:	7942                	ld	s2,48(sp)
    80003ce0:	79a2                	ld	s3,40(sp)
    80003ce2:	7a02                	ld	s4,32(sp)
    80003ce4:	6ae2                	ld	s5,24(sp)
    80003ce6:	6b42                	ld	s6,16(sp)
    80003ce8:	6ba2                	ld	s7,8(sp)
    80003cea:	6161                	addi	sp,sp,80
    80003cec:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003cee:	04000613          	li	a2,64
    80003cf2:	4581                	li	a1,0
    80003cf4:	854e                	mv	a0,s3
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	174080e7          	jalr	372(ra) # 80000e6a <memset>
      dip->type = type;
    80003cfe:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d02:	854a                	mv	a0,s2
    80003d04:	00001097          	auipc	ra,0x1
    80003d08:	c8e080e7          	jalr	-882(ra) # 80004992 <log_write>
      brelse(bp);
    80003d0c:	854a                	mv	a0,s2
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	9fa080e7          	jalr	-1542(ra) # 80003708 <brelse>
      return iget(dev, inum);
    80003d16:	85da                	mv	a1,s6
    80003d18:	8556                	mv	a0,s5
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	d9c080e7          	jalr	-612(ra) # 80003ab6 <iget>
    80003d22:	bf5d                	j	80003cd8 <ialloc+0x86>

0000000080003d24 <iupdate>:
{
    80003d24:	1101                	addi	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	e04a                	sd	s2,0(sp)
    80003d2e:	1000                	addi	s0,sp,32
    80003d30:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d32:	415c                	lw	a5,4(a0)
    80003d34:	0047d79b          	srliw	a5,a5,0x4
    80003d38:	0023c597          	auipc	a1,0x23c
    80003d3c:	db05a583          	lw	a1,-592(a1) # 8023fae8 <sb+0x18>
    80003d40:	9dbd                	addw	a1,a1,a5
    80003d42:	4108                	lw	a0,0(a0)
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	894080e7          	jalr	-1900(ra) # 800035d8 <bread>
    80003d4c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d4e:	05850793          	addi	a5,a0,88
    80003d52:	40d8                	lw	a4,4(s1)
    80003d54:	8b3d                	andi	a4,a4,15
    80003d56:	071a                	slli	a4,a4,0x6
    80003d58:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d5a:	04449703          	lh	a4,68(s1)
    80003d5e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d62:	04649703          	lh	a4,70(s1)
    80003d66:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d6a:	04849703          	lh	a4,72(s1)
    80003d6e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d72:	04a49703          	lh	a4,74(s1)
    80003d76:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d7a:	44f8                	lw	a4,76(s1)
    80003d7c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d7e:	03400613          	li	a2,52
    80003d82:	05048593          	addi	a1,s1,80
    80003d86:	00c78513          	addi	a0,a5,12
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	13c080e7          	jalr	316(ra) # 80000ec6 <memmove>
  log_write(bp);
    80003d92:	854a                	mv	a0,s2
    80003d94:	00001097          	auipc	ra,0x1
    80003d98:	bfe080e7          	jalr	-1026(ra) # 80004992 <log_write>
  brelse(bp);
    80003d9c:	854a                	mv	a0,s2
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	96a080e7          	jalr	-1686(ra) # 80003708 <brelse>
}
    80003da6:	60e2                	ld	ra,24(sp)
    80003da8:	6442                	ld	s0,16(sp)
    80003daa:	64a2                	ld	s1,8(sp)
    80003dac:	6902                	ld	s2,0(sp)
    80003dae:	6105                	addi	sp,sp,32
    80003db0:	8082                	ret

0000000080003db2 <idup>:
{
    80003db2:	1101                	addi	sp,sp,-32
    80003db4:	ec06                	sd	ra,24(sp)
    80003db6:	e822                	sd	s0,16(sp)
    80003db8:	e426                	sd	s1,8(sp)
    80003dba:	1000                	addi	s0,sp,32
    80003dbc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dbe:	0023c517          	auipc	a0,0x23c
    80003dc2:	d3250513          	addi	a0,a0,-718 # 8023faf0 <itable>
    80003dc6:	ffffd097          	auipc	ra,0xffffd
    80003dca:	fa8080e7          	jalr	-88(ra) # 80000d6e <acquire>
  ip->ref++;
    80003dce:	449c                	lw	a5,8(s1)
    80003dd0:	2785                	addiw	a5,a5,1
    80003dd2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dd4:	0023c517          	auipc	a0,0x23c
    80003dd8:	d1c50513          	addi	a0,a0,-740 # 8023faf0 <itable>
    80003ddc:	ffffd097          	auipc	ra,0xffffd
    80003de0:	046080e7          	jalr	70(ra) # 80000e22 <release>
}
    80003de4:	8526                	mv	a0,s1
    80003de6:	60e2                	ld	ra,24(sp)
    80003de8:	6442                	ld	s0,16(sp)
    80003dea:	64a2                	ld	s1,8(sp)
    80003dec:	6105                	addi	sp,sp,32
    80003dee:	8082                	ret

0000000080003df0 <ilock>:
{
    80003df0:	1101                	addi	sp,sp,-32
    80003df2:	ec06                	sd	ra,24(sp)
    80003df4:	e822                	sd	s0,16(sp)
    80003df6:	e426                	sd	s1,8(sp)
    80003df8:	e04a                	sd	s2,0(sp)
    80003dfa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dfc:	c115                	beqz	a0,80003e20 <ilock+0x30>
    80003dfe:	84aa                	mv	s1,a0
    80003e00:	451c                	lw	a5,8(a0)
    80003e02:	00f05f63          	blez	a5,80003e20 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e06:	0541                	addi	a0,a0,16
    80003e08:	00001097          	auipc	ra,0x1
    80003e0c:	ca8080e7          	jalr	-856(ra) # 80004ab0 <acquiresleep>
  if(ip->valid == 0){
    80003e10:	40bc                	lw	a5,64(s1)
    80003e12:	cf99                	beqz	a5,80003e30 <ilock+0x40>
}
    80003e14:	60e2                	ld	ra,24(sp)
    80003e16:	6442                	ld	s0,16(sp)
    80003e18:	64a2                	ld	s1,8(sp)
    80003e1a:	6902                	ld	s2,0(sp)
    80003e1c:	6105                	addi	sp,sp,32
    80003e1e:	8082                	ret
    panic("ilock");
    80003e20:	00005517          	auipc	a0,0x5
    80003e24:	80850513          	addi	a0,a0,-2040 # 80008628 <syscalls+0x1b0>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	718080e7          	jalr	1816(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e30:	40dc                	lw	a5,4(s1)
    80003e32:	0047d79b          	srliw	a5,a5,0x4
    80003e36:	0023c597          	auipc	a1,0x23c
    80003e3a:	cb25a583          	lw	a1,-846(a1) # 8023fae8 <sb+0x18>
    80003e3e:	9dbd                	addw	a1,a1,a5
    80003e40:	4088                	lw	a0,0(s1)
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	796080e7          	jalr	1942(ra) # 800035d8 <bread>
    80003e4a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e4c:	05850593          	addi	a1,a0,88
    80003e50:	40dc                	lw	a5,4(s1)
    80003e52:	8bbd                	andi	a5,a5,15
    80003e54:	079a                	slli	a5,a5,0x6
    80003e56:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e58:	00059783          	lh	a5,0(a1)
    80003e5c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e60:	00259783          	lh	a5,2(a1)
    80003e64:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e68:	00459783          	lh	a5,4(a1)
    80003e6c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e70:	00659783          	lh	a5,6(a1)
    80003e74:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e78:	459c                	lw	a5,8(a1)
    80003e7a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e7c:	03400613          	li	a2,52
    80003e80:	05b1                	addi	a1,a1,12
    80003e82:	05048513          	addi	a0,s1,80
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	040080e7          	jalr	64(ra) # 80000ec6 <memmove>
    brelse(bp);
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	878080e7          	jalr	-1928(ra) # 80003708 <brelse>
    ip->valid = 1;
    80003e98:	4785                	li	a5,1
    80003e9a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e9c:	04449783          	lh	a5,68(s1)
    80003ea0:	fbb5                	bnez	a5,80003e14 <ilock+0x24>
      panic("ilock: no type");
    80003ea2:	00004517          	auipc	a0,0x4
    80003ea6:	78e50513          	addi	a0,a0,1934 # 80008630 <syscalls+0x1b8>
    80003eaa:	ffffc097          	auipc	ra,0xffffc
    80003eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>

0000000080003eb2 <iunlock>:
{
    80003eb2:	1101                	addi	sp,sp,-32
    80003eb4:	ec06                	sd	ra,24(sp)
    80003eb6:	e822                	sd	s0,16(sp)
    80003eb8:	e426                	sd	s1,8(sp)
    80003eba:	e04a                	sd	s2,0(sp)
    80003ebc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ebe:	c905                	beqz	a0,80003eee <iunlock+0x3c>
    80003ec0:	84aa                	mv	s1,a0
    80003ec2:	01050913          	addi	s2,a0,16
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	00001097          	auipc	ra,0x1
    80003ecc:	c82080e7          	jalr	-894(ra) # 80004b4a <holdingsleep>
    80003ed0:	cd19                	beqz	a0,80003eee <iunlock+0x3c>
    80003ed2:	449c                	lw	a5,8(s1)
    80003ed4:	00f05d63          	blez	a5,80003eee <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00001097          	auipc	ra,0x1
    80003ede:	c2c080e7          	jalr	-980(ra) # 80004b06 <releasesleep>
}
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6902                	ld	s2,0(sp)
    80003eea:	6105                	addi	sp,sp,32
    80003eec:	8082                	ret
    panic("iunlock");
    80003eee:	00004517          	auipc	a0,0x4
    80003ef2:	75250513          	addi	a0,a0,1874 # 80008640 <syscalls+0x1c8>
    80003ef6:	ffffc097          	auipc	ra,0xffffc
    80003efa:	64a080e7          	jalr	1610(ra) # 80000540 <panic>

0000000080003efe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003efe:	7179                	addi	sp,sp,-48
    80003f00:	f406                	sd	ra,40(sp)
    80003f02:	f022                	sd	s0,32(sp)
    80003f04:	ec26                	sd	s1,24(sp)
    80003f06:	e84a                	sd	s2,16(sp)
    80003f08:	e44e                	sd	s3,8(sp)
    80003f0a:	e052                	sd	s4,0(sp)
    80003f0c:	1800                	addi	s0,sp,48
    80003f0e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f10:	05050493          	addi	s1,a0,80
    80003f14:	08050913          	addi	s2,a0,128
    80003f18:	a021                	j	80003f20 <itrunc+0x22>
    80003f1a:	0491                	addi	s1,s1,4
    80003f1c:	01248d63          	beq	s1,s2,80003f36 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f20:	408c                	lw	a1,0(s1)
    80003f22:	dde5                	beqz	a1,80003f1a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f24:	0009a503          	lw	a0,0(s3)
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	8f6080e7          	jalr	-1802(ra) # 8000381e <bfree>
      ip->addrs[i] = 0;
    80003f30:	0004a023          	sw	zero,0(s1)
    80003f34:	b7dd                	j	80003f1a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f36:	0809a583          	lw	a1,128(s3)
    80003f3a:	e185                	bnez	a1,80003f5a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f3c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	de2080e7          	jalr	-542(ra) # 80003d24 <iupdate>
}
    80003f4a:	70a2                	ld	ra,40(sp)
    80003f4c:	7402                	ld	s0,32(sp)
    80003f4e:	64e2                	ld	s1,24(sp)
    80003f50:	6942                	ld	s2,16(sp)
    80003f52:	69a2                	ld	s3,8(sp)
    80003f54:	6a02                	ld	s4,0(sp)
    80003f56:	6145                	addi	sp,sp,48
    80003f58:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f5a:	0009a503          	lw	a0,0(s3)
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	67a080e7          	jalr	1658(ra) # 800035d8 <bread>
    80003f66:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f68:	05850493          	addi	s1,a0,88
    80003f6c:	45850913          	addi	s2,a0,1112
    80003f70:	a021                	j	80003f78 <itrunc+0x7a>
    80003f72:	0491                	addi	s1,s1,4
    80003f74:	01248b63          	beq	s1,s2,80003f8a <itrunc+0x8c>
      if(a[j])
    80003f78:	408c                	lw	a1,0(s1)
    80003f7a:	dde5                	beqz	a1,80003f72 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f7c:	0009a503          	lw	a0,0(s3)
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	89e080e7          	jalr	-1890(ra) # 8000381e <bfree>
    80003f88:	b7ed                	j	80003f72 <itrunc+0x74>
    brelse(bp);
    80003f8a:	8552                	mv	a0,s4
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	77c080e7          	jalr	1916(ra) # 80003708 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f94:	0809a583          	lw	a1,128(s3)
    80003f98:	0009a503          	lw	a0,0(s3)
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	882080e7          	jalr	-1918(ra) # 8000381e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fa4:	0809a023          	sw	zero,128(s3)
    80003fa8:	bf51                	j	80003f3c <itrunc+0x3e>

0000000080003faa <iput>:
{
    80003faa:	1101                	addi	sp,sp,-32
    80003fac:	ec06                	sd	ra,24(sp)
    80003fae:	e822                	sd	s0,16(sp)
    80003fb0:	e426                	sd	s1,8(sp)
    80003fb2:	e04a                	sd	s2,0(sp)
    80003fb4:	1000                	addi	s0,sp,32
    80003fb6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fb8:	0023c517          	auipc	a0,0x23c
    80003fbc:	b3850513          	addi	a0,a0,-1224 # 8023faf0 <itable>
    80003fc0:	ffffd097          	auipc	ra,0xffffd
    80003fc4:	dae080e7          	jalr	-594(ra) # 80000d6e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fc8:	4498                	lw	a4,8(s1)
    80003fca:	4785                	li	a5,1
    80003fcc:	02f70363          	beq	a4,a5,80003ff2 <iput+0x48>
  ip->ref--;
    80003fd0:	449c                	lw	a5,8(s1)
    80003fd2:	37fd                	addiw	a5,a5,-1
    80003fd4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fd6:	0023c517          	auipc	a0,0x23c
    80003fda:	b1a50513          	addi	a0,a0,-1254 # 8023faf0 <itable>
    80003fde:	ffffd097          	auipc	ra,0xffffd
    80003fe2:	e44080e7          	jalr	-444(ra) # 80000e22 <release>
}
    80003fe6:	60e2                	ld	ra,24(sp)
    80003fe8:	6442                	ld	s0,16(sp)
    80003fea:	64a2                	ld	s1,8(sp)
    80003fec:	6902                	ld	s2,0(sp)
    80003fee:	6105                	addi	sp,sp,32
    80003ff0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ff2:	40bc                	lw	a5,64(s1)
    80003ff4:	dff1                	beqz	a5,80003fd0 <iput+0x26>
    80003ff6:	04a49783          	lh	a5,74(s1)
    80003ffa:	fbf9                	bnez	a5,80003fd0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ffc:	01048913          	addi	s2,s1,16
    80004000:	854a                	mv	a0,s2
    80004002:	00001097          	auipc	ra,0x1
    80004006:	aae080e7          	jalr	-1362(ra) # 80004ab0 <acquiresleep>
    release(&itable.lock);
    8000400a:	0023c517          	auipc	a0,0x23c
    8000400e:	ae650513          	addi	a0,a0,-1306 # 8023faf0 <itable>
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	e10080e7          	jalr	-496(ra) # 80000e22 <release>
    itrunc(ip);
    8000401a:	8526                	mv	a0,s1
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	ee2080e7          	jalr	-286(ra) # 80003efe <itrunc>
    ip->type = 0;
    80004024:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004028:	8526                	mv	a0,s1
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	cfa080e7          	jalr	-774(ra) # 80003d24 <iupdate>
    ip->valid = 0;
    80004032:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004036:	854a                	mv	a0,s2
    80004038:	00001097          	auipc	ra,0x1
    8000403c:	ace080e7          	jalr	-1330(ra) # 80004b06 <releasesleep>
    acquire(&itable.lock);
    80004040:	0023c517          	auipc	a0,0x23c
    80004044:	ab050513          	addi	a0,a0,-1360 # 8023faf0 <itable>
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	d26080e7          	jalr	-730(ra) # 80000d6e <acquire>
    80004050:	b741                	j	80003fd0 <iput+0x26>

0000000080004052 <iunlockput>:
{
    80004052:	1101                	addi	sp,sp,-32
    80004054:	ec06                	sd	ra,24(sp)
    80004056:	e822                	sd	s0,16(sp)
    80004058:	e426                	sd	s1,8(sp)
    8000405a:	1000                	addi	s0,sp,32
    8000405c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	e54080e7          	jalr	-428(ra) # 80003eb2 <iunlock>
  iput(ip);
    80004066:	8526                	mv	a0,s1
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	f42080e7          	jalr	-190(ra) # 80003faa <iput>
}
    80004070:	60e2                	ld	ra,24(sp)
    80004072:	6442                	ld	s0,16(sp)
    80004074:	64a2                	ld	s1,8(sp)
    80004076:	6105                	addi	sp,sp,32
    80004078:	8082                	ret

000000008000407a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000407a:	1141                	addi	sp,sp,-16
    8000407c:	e422                	sd	s0,8(sp)
    8000407e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004080:	411c                	lw	a5,0(a0)
    80004082:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004084:	415c                	lw	a5,4(a0)
    80004086:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004088:	04451783          	lh	a5,68(a0)
    8000408c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004090:	04a51783          	lh	a5,74(a0)
    80004094:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004098:	04c56783          	lwu	a5,76(a0)
    8000409c:	e99c                	sd	a5,16(a1)
}
    8000409e:	6422                	ld	s0,8(sp)
    800040a0:	0141                	addi	sp,sp,16
    800040a2:	8082                	ret

00000000800040a4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040a4:	457c                	lw	a5,76(a0)
    800040a6:	0ed7e963          	bltu	a5,a3,80004198 <readi+0xf4>
{
    800040aa:	7159                	addi	sp,sp,-112
    800040ac:	f486                	sd	ra,104(sp)
    800040ae:	f0a2                	sd	s0,96(sp)
    800040b0:	eca6                	sd	s1,88(sp)
    800040b2:	e8ca                	sd	s2,80(sp)
    800040b4:	e4ce                	sd	s3,72(sp)
    800040b6:	e0d2                	sd	s4,64(sp)
    800040b8:	fc56                	sd	s5,56(sp)
    800040ba:	f85a                	sd	s6,48(sp)
    800040bc:	f45e                	sd	s7,40(sp)
    800040be:	f062                	sd	s8,32(sp)
    800040c0:	ec66                	sd	s9,24(sp)
    800040c2:	e86a                	sd	s10,16(sp)
    800040c4:	e46e                	sd	s11,8(sp)
    800040c6:	1880                	addi	s0,sp,112
    800040c8:	8b2a                	mv	s6,a0
    800040ca:	8bae                	mv	s7,a1
    800040cc:	8a32                	mv	s4,a2
    800040ce:	84b6                	mv	s1,a3
    800040d0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800040d2:	9f35                	addw	a4,a4,a3
    return 0;
    800040d4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040d6:	0ad76063          	bltu	a4,a3,80004176 <readi+0xd2>
  if(off + n > ip->size)
    800040da:	00e7f463          	bgeu	a5,a4,800040e2 <readi+0x3e>
    n = ip->size - off;
    800040de:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040e2:	0a0a8963          	beqz	s5,80004194 <readi+0xf0>
    800040e6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040ec:	5c7d                	li	s8,-1
    800040ee:	a82d                	j	80004128 <readi+0x84>
    800040f0:	020d1d93          	slli	s11,s10,0x20
    800040f4:	020ddd93          	srli	s11,s11,0x20
    800040f8:	05890613          	addi	a2,s2,88
    800040fc:	86ee                	mv	a3,s11
    800040fe:	963a                	add	a2,a2,a4
    80004100:	85d2                	mv	a1,s4
    80004102:	855e                	mv	a0,s7
    80004104:	ffffe097          	auipc	ra,0xffffe
    80004108:	69e080e7          	jalr	1694(ra) # 800027a2 <either_copyout>
    8000410c:	05850d63          	beq	a0,s8,80004166 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004110:	854a                	mv	a0,s2
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	5f6080e7          	jalr	1526(ra) # 80003708 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000411a:	013d09bb          	addw	s3,s10,s3
    8000411e:	009d04bb          	addw	s1,s10,s1
    80004122:	9a6e                	add	s4,s4,s11
    80004124:	0559f763          	bgeu	s3,s5,80004172 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004128:	00a4d59b          	srliw	a1,s1,0xa
    8000412c:	855a                	mv	a0,s6
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	89e080e7          	jalr	-1890(ra) # 800039cc <bmap>
    80004136:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000413a:	cd85                	beqz	a1,80004172 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000413c:	000b2503          	lw	a0,0(s6)
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	498080e7          	jalr	1176(ra) # 800035d8 <bread>
    80004148:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000414a:	3ff4f713          	andi	a4,s1,1023
    8000414e:	40ec87bb          	subw	a5,s9,a4
    80004152:	413a86bb          	subw	a3,s5,s3
    80004156:	8d3e                	mv	s10,a5
    80004158:	2781                	sext.w	a5,a5
    8000415a:	0006861b          	sext.w	a2,a3
    8000415e:	f8f679e3          	bgeu	a2,a5,800040f0 <readi+0x4c>
    80004162:	8d36                	mv	s10,a3
    80004164:	b771                	j	800040f0 <readi+0x4c>
      brelse(bp);
    80004166:	854a                	mv	a0,s2
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	5a0080e7          	jalr	1440(ra) # 80003708 <brelse>
      tot = -1;
    80004170:	59fd                	li	s3,-1
  }
  return tot;
    80004172:	0009851b          	sext.w	a0,s3
}
    80004176:	70a6                	ld	ra,104(sp)
    80004178:	7406                	ld	s0,96(sp)
    8000417a:	64e6                	ld	s1,88(sp)
    8000417c:	6946                	ld	s2,80(sp)
    8000417e:	69a6                	ld	s3,72(sp)
    80004180:	6a06                	ld	s4,64(sp)
    80004182:	7ae2                	ld	s5,56(sp)
    80004184:	7b42                	ld	s6,48(sp)
    80004186:	7ba2                	ld	s7,40(sp)
    80004188:	7c02                	ld	s8,32(sp)
    8000418a:	6ce2                	ld	s9,24(sp)
    8000418c:	6d42                	ld	s10,16(sp)
    8000418e:	6da2                	ld	s11,8(sp)
    80004190:	6165                	addi	sp,sp,112
    80004192:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004194:	89d6                	mv	s3,s5
    80004196:	bff1                	j	80004172 <readi+0xce>
    return 0;
    80004198:	4501                	li	a0,0
}
    8000419a:	8082                	ret

000000008000419c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000419c:	457c                	lw	a5,76(a0)
    8000419e:	10d7e863          	bltu	a5,a3,800042ae <writei+0x112>
{
    800041a2:	7159                	addi	sp,sp,-112
    800041a4:	f486                	sd	ra,104(sp)
    800041a6:	f0a2                	sd	s0,96(sp)
    800041a8:	eca6                	sd	s1,88(sp)
    800041aa:	e8ca                	sd	s2,80(sp)
    800041ac:	e4ce                	sd	s3,72(sp)
    800041ae:	e0d2                	sd	s4,64(sp)
    800041b0:	fc56                	sd	s5,56(sp)
    800041b2:	f85a                	sd	s6,48(sp)
    800041b4:	f45e                	sd	s7,40(sp)
    800041b6:	f062                	sd	s8,32(sp)
    800041b8:	ec66                	sd	s9,24(sp)
    800041ba:	e86a                	sd	s10,16(sp)
    800041bc:	e46e                	sd	s11,8(sp)
    800041be:	1880                	addi	s0,sp,112
    800041c0:	8aaa                	mv	s5,a0
    800041c2:	8bae                	mv	s7,a1
    800041c4:	8a32                	mv	s4,a2
    800041c6:	8936                	mv	s2,a3
    800041c8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041ca:	00e687bb          	addw	a5,a3,a4
    800041ce:	0ed7e263          	bltu	a5,a3,800042b2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041d2:	00043737          	lui	a4,0x43
    800041d6:	0ef76063          	bltu	a4,a5,800042b6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041da:	0c0b0863          	beqz	s6,800042aa <writei+0x10e>
    800041de:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041e4:	5c7d                	li	s8,-1
    800041e6:	a091                	j	8000422a <writei+0x8e>
    800041e8:	020d1d93          	slli	s11,s10,0x20
    800041ec:	020ddd93          	srli	s11,s11,0x20
    800041f0:	05848513          	addi	a0,s1,88
    800041f4:	86ee                	mv	a3,s11
    800041f6:	8652                	mv	a2,s4
    800041f8:	85de                	mv	a1,s7
    800041fa:	953a                	add	a0,a0,a4
    800041fc:	ffffe097          	auipc	ra,0xffffe
    80004200:	5fc080e7          	jalr	1532(ra) # 800027f8 <either_copyin>
    80004204:	07850263          	beq	a0,s8,80004268 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004208:	8526                	mv	a0,s1
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	788080e7          	jalr	1928(ra) # 80004992 <log_write>
    brelse(bp);
    80004212:	8526                	mv	a0,s1
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	4f4080e7          	jalr	1268(ra) # 80003708 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000421c:	013d09bb          	addw	s3,s10,s3
    80004220:	012d093b          	addw	s2,s10,s2
    80004224:	9a6e                	add	s4,s4,s11
    80004226:	0569f663          	bgeu	s3,s6,80004272 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000422a:	00a9559b          	srliw	a1,s2,0xa
    8000422e:	8556                	mv	a0,s5
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	79c080e7          	jalr	1948(ra) # 800039cc <bmap>
    80004238:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000423c:	c99d                	beqz	a1,80004272 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000423e:	000aa503          	lw	a0,0(s5)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	396080e7          	jalr	918(ra) # 800035d8 <bread>
    8000424a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000424c:	3ff97713          	andi	a4,s2,1023
    80004250:	40ec87bb          	subw	a5,s9,a4
    80004254:	413b06bb          	subw	a3,s6,s3
    80004258:	8d3e                	mv	s10,a5
    8000425a:	2781                	sext.w	a5,a5
    8000425c:	0006861b          	sext.w	a2,a3
    80004260:	f8f674e3          	bgeu	a2,a5,800041e8 <writei+0x4c>
    80004264:	8d36                	mv	s10,a3
    80004266:	b749                	j	800041e8 <writei+0x4c>
      brelse(bp);
    80004268:	8526                	mv	a0,s1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	49e080e7          	jalr	1182(ra) # 80003708 <brelse>
  }

  if(off > ip->size)
    80004272:	04caa783          	lw	a5,76(s5)
    80004276:	0127f463          	bgeu	a5,s2,8000427e <writei+0xe2>
    ip->size = off;
    8000427a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000427e:	8556                	mv	a0,s5
    80004280:	00000097          	auipc	ra,0x0
    80004284:	aa4080e7          	jalr	-1372(ra) # 80003d24 <iupdate>

  return tot;
    80004288:	0009851b          	sext.w	a0,s3
}
    8000428c:	70a6                	ld	ra,104(sp)
    8000428e:	7406                	ld	s0,96(sp)
    80004290:	64e6                	ld	s1,88(sp)
    80004292:	6946                	ld	s2,80(sp)
    80004294:	69a6                	ld	s3,72(sp)
    80004296:	6a06                	ld	s4,64(sp)
    80004298:	7ae2                	ld	s5,56(sp)
    8000429a:	7b42                	ld	s6,48(sp)
    8000429c:	7ba2                	ld	s7,40(sp)
    8000429e:	7c02                	ld	s8,32(sp)
    800042a0:	6ce2                	ld	s9,24(sp)
    800042a2:	6d42                	ld	s10,16(sp)
    800042a4:	6da2                	ld	s11,8(sp)
    800042a6:	6165                	addi	sp,sp,112
    800042a8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042aa:	89da                	mv	s3,s6
    800042ac:	bfc9                	j	8000427e <writei+0xe2>
    return -1;
    800042ae:	557d                	li	a0,-1
}
    800042b0:	8082                	ret
    return -1;
    800042b2:	557d                	li	a0,-1
    800042b4:	bfe1                	j	8000428c <writei+0xf0>
    return -1;
    800042b6:	557d                	li	a0,-1
    800042b8:	bfd1                	j	8000428c <writei+0xf0>

00000000800042ba <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042ba:	1141                	addi	sp,sp,-16
    800042bc:	e406                	sd	ra,8(sp)
    800042be:	e022                	sd	s0,0(sp)
    800042c0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042c2:	4639                	li	a2,14
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	c76080e7          	jalr	-906(ra) # 80000f3a <strncmp>
}
    800042cc:	60a2                	ld	ra,8(sp)
    800042ce:	6402                	ld	s0,0(sp)
    800042d0:	0141                	addi	sp,sp,16
    800042d2:	8082                	ret

00000000800042d4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042d4:	7139                	addi	sp,sp,-64
    800042d6:	fc06                	sd	ra,56(sp)
    800042d8:	f822                	sd	s0,48(sp)
    800042da:	f426                	sd	s1,40(sp)
    800042dc:	f04a                	sd	s2,32(sp)
    800042de:	ec4e                	sd	s3,24(sp)
    800042e0:	e852                	sd	s4,16(sp)
    800042e2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042e4:	04451703          	lh	a4,68(a0)
    800042e8:	4785                	li	a5,1
    800042ea:	00f71a63          	bne	a4,a5,800042fe <dirlookup+0x2a>
    800042ee:	892a                	mv	s2,a0
    800042f0:	89ae                	mv	s3,a1
    800042f2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f4:	457c                	lw	a5,76(a0)
    800042f6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042f8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042fa:	e79d                	bnez	a5,80004328 <dirlookup+0x54>
    800042fc:	a8a5                	j	80004374 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042fe:	00004517          	auipc	a0,0x4
    80004302:	34a50513          	addi	a0,a0,842 # 80008648 <syscalls+0x1d0>
    80004306:	ffffc097          	auipc	ra,0xffffc
    8000430a:	23a080e7          	jalr	570(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000430e:	00004517          	auipc	a0,0x4
    80004312:	35250513          	addi	a0,a0,850 # 80008660 <syscalls+0x1e8>
    80004316:	ffffc097          	auipc	ra,0xffffc
    8000431a:	22a080e7          	jalr	554(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000431e:	24c1                	addiw	s1,s1,16
    80004320:	04c92783          	lw	a5,76(s2)
    80004324:	04f4f763          	bgeu	s1,a5,80004372 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004328:	4741                	li	a4,16
    8000432a:	86a6                	mv	a3,s1
    8000432c:	fc040613          	addi	a2,s0,-64
    80004330:	4581                	li	a1,0
    80004332:	854a                	mv	a0,s2
    80004334:	00000097          	auipc	ra,0x0
    80004338:	d70080e7          	jalr	-656(ra) # 800040a4 <readi>
    8000433c:	47c1                	li	a5,16
    8000433e:	fcf518e3          	bne	a0,a5,8000430e <dirlookup+0x3a>
    if(de.inum == 0)
    80004342:	fc045783          	lhu	a5,-64(s0)
    80004346:	dfe1                	beqz	a5,8000431e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004348:	fc240593          	addi	a1,s0,-62
    8000434c:	854e                	mv	a0,s3
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	f6c080e7          	jalr	-148(ra) # 800042ba <namecmp>
    80004356:	f561                	bnez	a0,8000431e <dirlookup+0x4a>
      if(poff)
    80004358:	000a0463          	beqz	s4,80004360 <dirlookup+0x8c>
        *poff = off;
    8000435c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004360:	fc045583          	lhu	a1,-64(s0)
    80004364:	00092503          	lw	a0,0(s2)
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	74e080e7          	jalr	1870(ra) # 80003ab6 <iget>
    80004370:	a011                	j	80004374 <dirlookup+0xa0>
  return 0;
    80004372:	4501                	li	a0,0
}
    80004374:	70e2                	ld	ra,56(sp)
    80004376:	7442                	ld	s0,48(sp)
    80004378:	74a2                	ld	s1,40(sp)
    8000437a:	7902                	ld	s2,32(sp)
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6121                	addi	sp,sp,64
    80004382:	8082                	ret

0000000080004384 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004384:	711d                	addi	sp,sp,-96
    80004386:	ec86                	sd	ra,88(sp)
    80004388:	e8a2                	sd	s0,80(sp)
    8000438a:	e4a6                	sd	s1,72(sp)
    8000438c:	e0ca                	sd	s2,64(sp)
    8000438e:	fc4e                	sd	s3,56(sp)
    80004390:	f852                	sd	s4,48(sp)
    80004392:	f456                	sd	s5,40(sp)
    80004394:	f05a                	sd	s6,32(sp)
    80004396:	ec5e                	sd	s7,24(sp)
    80004398:	e862                	sd	s8,16(sp)
    8000439a:	e466                	sd	s9,8(sp)
    8000439c:	e06a                	sd	s10,0(sp)
    8000439e:	1080                	addi	s0,sp,96
    800043a0:	84aa                	mv	s1,a0
    800043a2:	8b2e                	mv	s6,a1
    800043a4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043a6:	00054703          	lbu	a4,0(a0)
    800043aa:	02f00793          	li	a5,47
    800043ae:	02f70363          	beq	a4,a5,800043d4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	7d4080e7          	jalr	2004(ra) # 80001b86 <myproc>
    800043ba:	15053503          	ld	a0,336(a0)
    800043be:	00000097          	auipc	ra,0x0
    800043c2:	9f4080e7          	jalr	-1548(ra) # 80003db2 <idup>
    800043c6:	8a2a                	mv	s4,a0
  while(*path == '/')
    800043c8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800043cc:	4cb5                	li	s9,13
  len = path - s;
    800043ce:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043d0:	4c05                	li	s8,1
    800043d2:	a87d                	j	80004490 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800043d4:	4585                	li	a1,1
    800043d6:	4505                	li	a0,1
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	6de080e7          	jalr	1758(ra) # 80003ab6 <iget>
    800043e0:	8a2a                	mv	s4,a0
    800043e2:	b7dd                	j	800043c8 <namex+0x44>
      iunlockput(ip);
    800043e4:	8552                	mv	a0,s4
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	c6c080e7          	jalr	-916(ra) # 80004052 <iunlockput>
      return 0;
    800043ee:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043f0:	8552                	mv	a0,s4
    800043f2:	60e6                	ld	ra,88(sp)
    800043f4:	6446                	ld	s0,80(sp)
    800043f6:	64a6                	ld	s1,72(sp)
    800043f8:	6906                	ld	s2,64(sp)
    800043fa:	79e2                	ld	s3,56(sp)
    800043fc:	7a42                	ld	s4,48(sp)
    800043fe:	7aa2                	ld	s5,40(sp)
    80004400:	7b02                	ld	s6,32(sp)
    80004402:	6be2                	ld	s7,24(sp)
    80004404:	6c42                	ld	s8,16(sp)
    80004406:	6ca2                	ld	s9,8(sp)
    80004408:	6d02                	ld	s10,0(sp)
    8000440a:	6125                	addi	sp,sp,96
    8000440c:	8082                	ret
      iunlock(ip);
    8000440e:	8552                	mv	a0,s4
    80004410:	00000097          	auipc	ra,0x0
    80004414:	aa2080e7          	jalr	-1374(ra) # 80003eb2 <iunlock>
      return ip;
    80004418:	bfe1                	j	800043f0 <namex+0x6c>
      iunlockput(ip);
    8000441a:	8552                	mv	a0,s4
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	c36080e7          	jalr	-970(ra) # 80004052 <iunlockput>
      return 0;
    80004424:	8a4e                	mv	s4,s3
    80004426:	b7e9                	j	800043f0 <namex+0x6c>
  len = path - s;
    80004428:	40998633          	sub	a2,s3,s1
    8000442c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004430:	09acd863          	bge	s9,s10,800044c0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004434:	4639                	li	a2,14
    80004436:	85a6                	mv	a1,s1
    80004438:	8556                	mv	a0,s5
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	a8c080e7          	jalr	-1396(ra) # 80000ec6 <memmove>
    80004442:	84ce                	mv	s1,s3
  while(*path == '/')
    80004444:	0004c783          	lbu	a5,0(s1)
    80004448:	01279763          	bne	a5,s2,80004456 <namex+0xd2>
    path++;
    8000444c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000444e:	0004c783          	lbu	a5,0(s1)
    80004452:	ff278de3          	beq	a5,s2,8000444c <namex+0xc8>
    ilock(ip);
    80004456:	8552                	mv	a0,s4
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	998080e7          	jalr	-1640(ra) # 80003df0 <ilock>
    if(ip->type != T_DIR){
    80004460:	044a1783          	lh	a5,68(s4)
    80004464:	f98790e3          	bne	a5,s8,800043e4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004468:	000b0563          	beqz	s6,80004472 <namex+0xee>
    8000446c:	0004c783          	lbu	a5,0(s1)
    80004470:	dfd9                	beqz	a5,8000440e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004472:	865e                	mv	a2,s7
    80004474:	85d6                	mv	a1,s5
    80004476:	8552                	mv	a0,s4
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	e5c080e7          	jalr	-420(ra) # 800042d4 <dirlookup>
    80004480:	89aa                	mv	s3,a0
    80004482:	dd41                	beqz	a0,8000441a <namex+0x96>
    iunlockput(ip);
    80004484:	8552                	mv	a0,s4
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	bcc080e7          	jalr	-1076(ra) # 80004052 <iunlockput>
    ip = next;
    8000448e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004490:	0004c783          	lbu	a5,0(s1)
    80004494:	01279763          	bne	a5,s2,800044a2 <namex+0x11e>
    path++;
    80004498:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000449a:	0004c783          	lbu	a5,0(s1)
    8000449e:	ff278de3          	beq	a5,s2,80004498 <namex+0x114>
  if(*path == 0)
    800044a2:	cb9d                	beqz	a5,800044d8 <namex+0x154>
  while(*path != '/' && *path != 0)
    800044a4:	0004c783          	lbu	a5,0(s1)
    800044a8:	89a6                	mv	s3,s1
  len = path - s;
    800044aa:	8d5e                	mv	s10,s7
    800044ac:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044ae:	01278963          	beq	a5,s2,800044c0 <namex+0x13c>
    800044b2:	dbbd                	beqz	a5,80004428 <namex+0xa4>
    path++;
    800044b4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800044b6:	0009c783          	lbu	a5,0(s3)
    800044ba:	ff279ce3          	bne	a5,s2,800044b2 <namex+0x12e>
    800044be:	b7ad                	j	80004428 <namex+0xa4>
    memmove(name, s, len);
    800044c0:	2601                	sext.w	a2,a2
    800044c2:	85a6                	mv	a1,s1
    800044c4:	8556                	mv	a0,s5
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	a00080e7          	jalr	-1536(ra) # 80000ec6 <memmove>
    name[len] = 0;
    800044ce:	9d56                	add	s10,s10,s5
    800044d0:	000d0023          	sb	zero,0(s10)
    800044d4:	84ce                	mv	s1,s3
    800044d6:	b7bd                	j	80004444 <namex+0xc0>
  if(nameiparent){
    800044d8:	f00b0ce3          	beqz	s6,800043f0 <namex+0x6c>
    iput(ip);
    800044dc:	8552                	mv	a0,s4
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	acc080e7          	jalr	-1332(ra) # 80003faa <iput>
    return 0;
    800044e6:	4a01                	li	s4,0
    800044e8:	b721                	j	800043f0 <namex+0x6c>

00000000800044ea <dirlink>:
{
    800044ea:	7139                	addi	sp,sp,-64
    800044ec:	fc06                	sd	ra,56(sp)
    800044ee:	f822                	sd	s0,48(sp)
    800044f0:	f426                	sd	s1,40(sp)
    800044f2:	f04a                	sd	s2,32(sp)
    800044f4:	ec4e                	sd	s3,24(sp)
    800044f6:	e852                	sd	s4,16(sp)
    800044f8:	0080                	addi	s0,sp,64
    800044fa:	892a                	mv	s2,a0
    800044fc:	8a2e                	mv	s4,a1
    800044fe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004500:	4601                	li	a2,0
    80004502:	00000097          	auipc	ra,0x0
    80004506:	dd2080e7          	jalr	-558(ra) # 800042d4 <dirlookup>
    8000450a:	e93d                	bnez	a0,80004580 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000450c:	04c92483          	lw	s1,76(s2)
    80004510:	c49d                	beqz	s1,8000453e <dirlink+0x54>
    80004512:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004514:	4741                	li	a4,16
    80004516:	86a6                	mv	a3,s1
    80004518:	fc040613          	addi	a2,s0,-64
    8000451c:	4581                	li	a1,0
    8000451e:	854a                	mv	a0,s2
    80004520:	00000097          	auipc	ra,0x0
    80004524:	b84080e7          	jalr	-1148(ra) # 800040a4 <readi>
    80004528:	47c1                	li	a5,16
    8000452a:	06f51163          	bne	a0,a5,8000458c <dirlink+0xa2>
    if(de.inum == 0)
    8000452e:	fc045783          	lhu	a5,-64(s0)
    80004532:	c791                	beqz	a5,8000453e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004534:	24c1                	addiw	s1,s1,16
    80004536:	04c92783          	lw	a5,76(s2)
    8000453a:	fcf4ede3          	bltu	s1,a5,80004514 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000453e:	4639                	li	a2,14
    80004540:	85d2                	mv	a1,s4
    80004542:	fc240513          	addi	a0,s0,-62
    80004546:	ffffd097          	auipc	ra,0xffffd
    8000454a:	a30080e7          	jalr	-1488(ra) # 80000f76 <strncpy>
  de.inum = inum;
    8000454e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004552:	4741                	li	a4,16
    80004554:	86a6                	mv	a3,s1
    80004556:	fc040613          	addi	a2,s0,-64
    8000455a:	4581                	li	a1,0
    8000455c:	854a                	mv	a0,s2
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	c3e080e7          	jalr	-962(ra) # 8000419c <writei>
    80004566:	1541                	addi	a0,a0,-16
    80004568:	00a03533          	snez	a0,a0
    8000456c:	40a00533          	neg	a0,a0
}
    80004570:	70e2                	ld	ra,56(sp)
    80004572:	7442                	ld	s0,48(sp)
    80004574:	74a2                	ld	s1,40(sp)
    80004576:	7902                	ld	s2,32(sp)
    80004578:	69e2                	ld	s3,24(sp)
    8000457a:	6a42                	ld	s4,16(sp)
    8000457c:	6121                	addi	sp,sp,64
    8000457e:	8082                	ret
    iput(ip);
    80004580:	00000097          	auipc	ra,0x0
    80004584:	a2a080e7          	jalr	-1494(ra) # 80003faa <iput>
    return -1;
    80004588:	557d                	li	a0,-1
    8000458a:	b7dd                	j	80004570 <dirlink+0x86>
      panic("dirlink read");
    8000458c:	00004517          	auipc	a0,0x4
    80004590:	0e450513          	addi	a0,a0,228 # 80008670 <syscalls+0x1f8>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	fac080e7          	jalr	-84(ra) # 80000540 <panic>

000000008000459c <namei>:

struct inode*
namei(char *path)
{
    8000459c:	1101                	addi	sp,sp,-32
    8000459e:	ec06                	sd	ra,24(sp)
    800045a0:	e822                	sd	s0,16(sp)
    800045a2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045a4:	fe040613          	addi	a2,s0,-32
    800045a8:	4581                	li	a1,0
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	dda080e7          	jalr	-550(ra) # 80004384 <namex>
}
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045ba:	1141                	addi	sp,sp,-16
    800045bc:	e406                	sd	ra,8(sp)
    800045be:	e022                	sd	s0,0(sp)
    800045c0:	0800                	addi	s0,sp,16
    800045c2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045c4:	4585                	li	a1,1
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	dbe080e7          	jalr	-578(ra) # 80004384 <namex>
}
    800045ce:	60a2                	ld	ra,8(sp)
    800045d0:	6402                	ld	s0,0(sp)
    800045d2:	0141                	addi	sp,sp,16
    800045d4:	8082                	ret

00000000800045d6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045d6:	1101                	addi	sp,sp,-32
    800045d8:	ec06                	sd	ra,24(sp)
    800045da:	e822                	sd	s0,16(sp)
    800045dc:	e426                	sd	s1,8(sp)
    800045de:	e04a                	sd	s2,0(sp)
    800045e0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045e2:	0023d917          	auipc	s2,0x23d
    800045e6:	fb690913          	addi	s2,s2,-74 # 80241598 <log>
    800045ea:	01892583          	lw	a1,24(s2)
    800045ee:	02892503          	lw	a0,40(s2)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	fe6080e7          	jalr	-26(ra) # 800035d8 <bread>
    800045fa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045fc:	02c92683          	lw	a3,44(s2)
    80004600:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004602:	02d05863          	blez	a3,80004632 <write_head+0x5c>
    80004606:	0023d797          	auipc	a5,0x23d
    8000460a:	fc278793          	addi	a5,a5,-62 # 802415c8 <log+0x30>
    8000460e:	05c50713          	addi	a4,a0,92
    80004612:	36fd                	addiw	a3,a3,-1
    80004614:	02069613          	slli	a2,a3,0x20
    80004618:	01e65693          	srli	a3,a2,0x1e
    8000461c:	0023d617          	auipc	a2,0x23d
    80004620:	fb060613          	addi	a2,a2,-80 # 802415cc <log+0x34>
    80004624:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004626:	4390                	lw	a2,0(a5)
    80004628:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000462a:	0791                	addi	a5,a5,4
    8000462c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000462e:	fed79ce3          	bne	a5,a3,80004626 <write_head+0x50>
  }
  bwrite(buf);
    80004632:	8526                	mv	a0,s1
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	096080e7          	jalr	150(ra) # 800036ca <bwrite>
  brelse(buf);
    8000463c:	8526                	mv	a0,s1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	0ca080e7          	jalr	202(ra) # 80003708 <brelse>
}
    80004646:	60e2                	ld	ra,24(sp)
    80004648:	6442                	ld	s0,16(sp)
    8000464a:	64a2                	ld	s1,8(sp)
    8000464c:	6902                	ld	s2,0(sp)
    8000464e:	6105                	addi	sp,sp,32
    80004650:	8082                	ret

0000000080004652 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004652:	0023d797          	auipc	a5,0x23d
    80004656:	f727a783          	lw	a5,-142(a5) # 802415c4 <log+0x2c>
    8000465a:	0af05d63          	blez	a5,80004714 <install_trans+0xc2>
{
    8000465e:	7139                	addi	sp,sp,-64
    80004660:	fc06                	sd	ra,56(sp)
    80004662:	f822                	sd	s0,48(sp)
    80004664:	f426                	sd	s1,40(sp)
    80004666:	f04a                	sd	s2,32(sp)
    80004668:	ec4e                	sd	s3,24(sp)
    8000466a:	e852                	sd	s4,16(sp)
    8000466c:	e456                	sd	s5,8(sp)
    8000466e:	e05a                	sd	s6,0(sp)
    80004670:	0080                	addi	s0,sp,64
    80004672:	8b2a                	mv	s6,a0
    80004674:	0023da97          	auipc	s5,0x23d
    80004678:	f54a8a93          	addi	s5,s5,-172 # 802415c8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000467e:	0023d997          	auipc	s3,0x23d
    80004682:	f1a98993          	addi	s3,s3,-230 # 80241598 <log>
    80004686:	a00d                	j	800046a8 <install_trans+0x56>
    brelse(lbuf);
    80004688:	854a                	mv	a0,s2
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	07e080e7          	jalr	126(ra) # 80003708 <brelse>
    brelse(dbuf);
    80004692:	8526                	mv	a0,s1
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	074080e7          	jalr	116(ra) # 80003708 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469c:	2a05                	addiw	s4,s4,1
    8000469e:	0a91                	addi	s5,s5,4
    800046a0:	02c9a783          	lw	a5,44(s3)
    800046a4:	04fa5e63          	bge	s4,a5,80004700 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046a8:	0189a583          	lw	a1,24(s3)
    800046ac:	014585bb          	addw	a1,a1,s4
    800046b0:	2585                	addiw	a1,a1,1
    800046b2:	0289a503          	lw	a0,40(s3)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	f22080e7          	jalr	-222(ra) # 800035d8 <bread>
    800046be:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046c0:	000aa583          	lw	a1,0(s5)
    800046c4:	0289a503          	lw	a0,40(s3)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	f10080e7          	jalr	-240(ra) # 800035d8 <bread>
    800046d0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046d2:	40000613          	li	a2,1024
    800046d6:	05890593          	addi	a1,s2,88
    800046da:	05850513          	addi	a0,a0,88
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	7e8080e7          	jalr	2024(ra) # 80000ec6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046e6:	8526                	mv	a0,s1
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	fe2080e7          	jalr	-30(ra) # 800036ca <bwrite>
    if(recovering == 0)
    800046f0:	f80b1ce3          	bnez	s6,80004688 <install_trans+0x36>
      bunpin(dbuf);
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	0ec080e7          	jalr	236(ra) # 800037e2 <bunpin>
    800046fe:	b769                	j	80004688 <install_trans+0x36>
}
    80004700:	70e2                	ld	ra,56(sp)
    80004702:	7442                	ld	s0,48(sp)
    80004704:	74a2                	ld	s1,40(sp)
    80004706:	7902                	ld	s2,32(sp)
    80004708:	69e2                	ld	s3,24(sp)
    8000470a:	6a42                	ld	s4,16(sp)
    8000470c:	6aa2                	ld	s5,8(sp)
    8000470e:	6b02                	ld	s6,0(sp)
    80004710:	6121                	addi	sp,sp,64
    80004712:	8082                	ret
    80004714:	8082                	ret

0000000080004716 <initlog>:
{
    80004716:	7179                	addi	sp,sp,-48
    80004718:	f406                	sd	ra,40(sp)
    8000471a:	f022                	sd	s0,32(sp)
    8000471c:	ec26                	sd	s1,24(sp)
    8000471e:	e84a                	sd	s2,16(sp)
    80004720:	e44e                	sd	s3,8(sp)
    80004722:	1800                	addi	s0,sp,48
    80004724:	892a                	mv	s2,a0
    80004726:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004728:	0023d497          	auipc	s1,0x23d
    8000472c:	e7048493          	addi	s1,s1,-400 # 80241598 <log>
    80004730:	00004597          	auipc	a1,0x4
    80004734:	f5058593          	addi	a1,a1,-176 # 80008680 <syscalls+0x208>
    80004738:	8526                	mv	a0,s1
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	5a4080e7          	jalr	1444(ra) # 80000cde <initlock>
  log.start = sb->logstart;
    80004742:	0149a583          	lw	a1,20(s3)
    80004746:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004748:	0109a783          	lw	a5,16(s3)
    8000474c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000474e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004752:	854a                	mv	a0,s2
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	e84080e7          	jalr	-380(ra) # 800035d8 <bread>
  log.lh.n = lh->n;
    8000475c:	4d34                	lw	a3,88(a0)
    8000475e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004760:	02d05663          	blez	a3,8000478c <initlog+0x76>
    80004764:	05c50793          	addi	a5,a0,92
    80004768:	0023d717          	auipc	a4,0x23d
    8000476c:	e6070713          	addi	a4,a4,-416 # 802415c8 <log+0x30>
    80004770:	36fd                	addiw	a3,a3,-1
    80004772:	02069613          	slli	a2,a3,0x20
    80004776:	01e65693          	srli	a3,a2,0x1e
    8000477a:	06050613          	addi	a2,a0,96
    8000477e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004780:	4390                	lw	a2,0(a5)
    80004782:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004784:	0791                	addi	a5,a5,4
    80004786:	0711                	addi	a4,a4,4
    80004788:	fed79ce3          	bne	a5,a3,80004780 <initlog+0x6a>
  brelse(buf);
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	f7c080e7          	jalr	-132(ra) # 80003708 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004794:	4505                	li	a0,1
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	ebc080e7          	jalr	-324(ra) # 80004652 <install_trans>
  log.lh.n = 0;
    8000479e:	0023d797          	auipc	a5,0x23d
    800047a2:	e207a323          	sw	zero,-474(a5) # 802415c4 <log+0x2c>
  write_head(); // clear the log
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	e30080e7          	jalr	-464(ra) # 800045d6 <write_head>
}
    800047ae:	70a2                	ld	ra,40(sp)
    800047b0:	7402                	ld	s0,32(sp)
    800047b2:	64e2                	ld	s1,24(sp)
    800047b4:	6942                	ld	s2,16(sp)
    800047b6:	69a2                	ld	s3,8(sp)
    800047b8:	6145                	addi	sp,sp,48
    800047ba:	8082                	ret

00000000800047bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047bc:	1101                	addi	sp,sp,-32
    800047be:	ec06                	sd	ra,24(sp)
    800047c0:	e822                	sd	s0,16(sp)
    800047c2:	e426                	sd	s1,8(sp)
    800047c4:	e04a                	sd	s2,0(sp)
    800047c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047c8:	0023d517          	auipc	a0,0x23d
    800047cc:	dd050513          	addi	a0,a0,-560 # 80241598 <log>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	59e080e7          	jalr	1438(ra) # 80000d6e <acquire>
  while(1){
    if(log.committing){
    800047d8:	0023d497          	auipc	s1,0x23d
    800047dc:	dc048493          	addi	s1,s1,-576 # 80241598 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047e0:	4979                	li	s2,30
    800047e2:	a039                	j	800047f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047e4:	85a6                	mv	a1,s1
    800047e6:	8526                	mv	a0,s1
    800047e8:	ffffe097          	auipc	ra,0xffffe
    800047ec:	ba6080e7          	jalr	-1114(ra) # 8000238e <sleep>
    if(log.committing){
    800047f0:	50dc                	lw	a5,36(s1)
    800047f2:	fbed                	bnez	a5,800047e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047f4:	5098                	lw	a4,32(s1)
    800047f6:	2705                	addiw	a4,a4,1
    800047f8:	0007069b          	sext.w	a3,a4
    800047fc:	0027179b          	slliw	a5,a4,0x2
    80004800:	9fb9                	addw	a5,a5,a4
    80004802:	0017979b          	slliw	a5,a5,0x1
    80004806:	54d8                	lw	a4,44(s1)
    80004808:	9fb9                	addw	a5,a5,a4
    8000480a:	00f95963          	bge	s2,a5,8000481c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000480e:	85a6                	mv	a1,s1
    80004810:	8526                	mv	a0,s1
    80004812:	ffffe097          	auipc	ra,0xffffe
    80004816:	b7c080e7          	jalr	-1156(ra) # 8000238e <sleep>
    8000481a:	bfd9                	j	800047f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000481c:	0023d517          	auipc	a0,0x23d
    80004820:	d7c50513          	addi	a0,a0,-644 # 80241598 <log>
    80004824:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	5fc080e7          	jalr	1532(ra) # 80000e22 <release>
      break;
    }
  }
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret

000000008000483a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000483a:	7139                	addi	sp,sp,-64
    8000483c:	fc06                	sd	ra,56(sp)
    8000483e:	f822                	sd	s0,48(sp)
    80004840:	f426                	sd	s1,40(sp)
    80004842:	f04a                	sd	s2,32(sp)
    80004844:	ec4e                	sd	s3,24(sp)
    80004846:	e852                	sd	s4,16(sp)
    80004848:	e456                	sd	s5,8(sp)
    8000484a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000484c:	0023d497          	auipc	s1,0x23d
    80004850:	d4c48493          	addi	s1,s1,-692 # 80241598 <log>
    80004854:	8526                	mv	a0,s1
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	518080e7          	jalr	1304(ra) # 80000d6e <acquire>
  log.outstanding -= 1;
    8000485e:	509c                	lw	a5,32(s1)
    80004860:	37fd                	addiw	a5,a5,-1
    80004862:	0007891b          	sext.w	s2,a5
    80004866:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004868:	50dc                	lw	a5,36(s1)
    8000486a:	e7b9                	bnez	a5,800048b8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000486c:	04091e63          	bnez	s2,800048c8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004870:	0023d497          	auipc	s1,0x23d
    80004874:	d2848493          	addi	s1,s1,-728 # 80241598 <log>
    80004878:	4785                	li	a5,1
    8000487a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	5a4080e7          	jalr	1444(ra) # 80000e22 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004886:	54dc                	lw	a5,44(s1)
    80004888:	06f04763          	bgtz	a5,800048f6 <end_op+0xbc>
    acquire(&log.lock);
    8000488c:	0023d497          	auipc	s1,0x23d
    80004890:	d0c48493          	addi	s1,s1,-756 # 80241598 <log>
    80004894:	8526                	mv	a0,s1
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	4d8080e7          	jalr	1240(ra) # 80000d6e <acquire>
    log.committing = 0;
    8000489e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048a2:	8526                	mv	a0,s1
    800048a4:	ffffe097          	auipc	ra,0xffffe
    800048a8:	b4e080e7          	jalr	-1202(ra) # 800023f2 <wakeup>
    release(&log.lock);
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	574080e7          	jalr	1396(ra) # 80000e22 <release>
}
    800048b6:	a03d                	j	800048e4 <end_op+0xaa>
    panic("log.committing");
    800048b8:	00004517          	auipc	a0,0x4
    800048bc:	dd050513          	addi	a0,a0,-560 # 80008688 <syscalls+0x210>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	c80080e7          	jalr	-896(ra) # 80000540 <panic>
    wakeup(&log);
    800048c8:	0023d497          	auipc	s1,0x23d
    800048cc:	cd048493          	addi	s1,s1,-816 # 80241598 <log>
    800048d0:	8526                	mv	a0,s1
    800048d2:	ffffe097          	auipc	ra,0xffffe
    800048d6:	b20080e7          	jalr	-1248(ra) # 800023f2 <wakeup>
  release(&log.lock);
    800048da:	8526                	mv	a0,s1
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	546080e7          	jalr	1350(ra) # 80000e22 <release>
}
    800048e4:	70e2                	ld	ra,56(sp)
    800048e6:	7442                	ld	s0,48(sp)
    800048e8:	74a2                	ld	s1,40(sp)
    800048ea:	7902                	ld	s2,32(sp)
    800048ec:	69e2                	ld	s3,24(sp)
    800048ee:	6a42                	ld	s4,16(sp)
    800048f0:	6aa2                	ld	s5,8(sp)
    800048f2:	6121                	addi	sp,sp,64
    800048f4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f6:	0023da97          	auipc	s5,0x23d
    800048fa:	cd2a8a93          	addi	s5,s5,-814 # 802415c8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048fe:	0023da17          	auipc	s4,0x23d
    80004902:	c9aa0a13          	addi	s4,s4,-870 # 80241598 <log>
    80004906:	018a2583          	lw	a1,24(s4)
    8000490a:	012585bb          	addw	a1,a1,s2
    8000490e:	2585                	addiw	a1,a1,1
    80004910:	028a2503          	lw	a0,40(s4)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	cc4080e7          	jalr	-828(ra) # 800035d8 <bread>
    8000491c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000491e:	000aa583          	lw	a1,0(s5)
    80004922:	028a2503          	lw	a0,40(s4)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	cb2080e7          	jalr	-846(ra) # 800035d8 <bread>
    8000492e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004930:	40000613          	li	a2,1024
    80004934:	05850593          	addi	a1,a0,88
    80004938:	05848513          	addi	a0,s1,88
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	58a080e7          	jalr	1418(ra) # 80000ec6 <memmove>
    bwrite(to);  // write the log
    80004944:	8526                	mv	a0,s1
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	d84080e7          	jalr	-636(ra) # 800036ca <bwrite>
    brelse(from);
    8000494e:	854e                	mv	a0,s3
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	db8080e7          	jalr	-584(ra) # 80003708 <brelse>
    brelse(to);
    80004958:	8526                	mv	a0,s1
    8000495a:	fffff097          	auipc	ra,0xfffff
    8000495e:	dae080e7          	jalr	-594(ra) # 80003708 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004962:	2905                	addiw	s2,s2,1
    80004964:	0a91                	addi	s5,s5,4
    80004966:	02ca2783          	lw	a5,44(s4)
    8000496a:	f8f94ee3          	blt	s2,a5,80004906 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	c68080e7          	jalr	-920(ra) # 800045d6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004976:	4501                	li	a0,0
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	cda080e7          	jalr	-806(ra) # 80004652 <install_trans>
    log.lh.n = 0;
    80004980:	0023d797          	auipc	a5,0x23d
    80004984:	c407a223          	sw	zero,-956(a5) # 802415c4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	c4e080e7          	jalr	-946(ra) # 800045d6 <write_head>
    80004990:	bdf5                	j	8000488c <end_op+0x52>

0000000080004992 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004992:	1101                	addi	sp,sp,-32
    80004994:	ec06                	sd	ra,24(sp)
    80004996:	e822                	sd	s0,16(sp)
    80004998:	e426                	sd	s1,8(sp)
    8000499a:	e04a                	sd	s2,0(sp)
    8000499c:	1000                	addi	s0,sp,32
    8000499e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049a0:	0023d917          	auipc	s2,0x23d
    800049a4:	bf890913          	addi	s2,s2,-1032 # 80241598 <log>
    800049a8:	854a                	mv	a0,s2
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	3c4080e7          	jalr	964(ra) # 80000d6e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049b2:	02c92603          	lw	a2,44(s2)
    800049b6:	47f5                	li	a5,29
    800049b8:	06c7c563          	blt	a5,a2,80004a22 <log_write+0x90>
    800049bc:	0023d797          	auipc	a5,0x23d
    800049c0:	bf87a783          	lw	a5,-1032(a5) # 802415b4 <log+0x1c>
    800049c4:	37fd                	addiw	a5,a5,-1
    800049c6:	04f65e63          	bge	a2,a5,80004a22 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049ca:	0023d797          	auipc	a5,0x23d
    800049ce:	bee7a783          	lw	a5,-1042(a5) # 802415b8 <log+0x20>
    800049d2:	06f05063          	blez	a5,80004a32 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049d6:	4781                	li	a5,0
    800049d8:	06c05563          	blez	a2,80004a42 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049dc:	44cc                	lw	a1,12(s1)
    800049de:	0023d717          	auipc	a4,0x23d
    800049e2:	bea70713          	addi	a4,a4,-1046 # 802415c8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049e6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049e8:	4314                	lw	a3,0(a4)
    800049ea:	04b68c63          	beq	a3,a1,80004a42 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049ee:	2785                	addiw	a5,a5,1
    800049f0:	0711                	addi	a4,a4,4
    800049f2:	fef61be3          	bne	a2,a5,800049e8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049f6:	0621                	addi	a2,a2,8
    800049f8:	060a                	slli	a2,a2,0x2
    800049fa:	0023d797          	auipc	a5,0x23d
    800049fe:	b9e78793          	addi	a5,a5,-1122 # 80241598 <log>
    80004a02:	97b2                	add	a5,a5,a2
    80004a04:	44d8                	lw	a4,12(s1)
    80004a06:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	d9c080e7          	jalr	-612(ra) # 800037a6 <bpin>
    log.lh.n++;
    80004a12:	0023d717          	auipc	a4,0x23d
    80004a16:	b8670713          	addi	a4,a4,-1146 # 80241598 <log>
    80004a1a:	575c                	lw	a5,44(a4)
    80004a1c:	2785                	addiw	a5,a5,1
    80004a1e:	d75c                	sw	a5,44(a4)
    80004a20:	a82d                	j	80004a5a <log_write+0xc8>
    panic("too big a transaction");
    80004a22:	00004517          	auipc	a0,0x4
    80004a26:	c7650513          	addi	a0,a0,-906 # 80008698 <syscalls+0x220>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	b16080e7          	jalr	-1258(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004a32:	00004517          	auipc	a0,0x4
    80004a36:	c7e50513          	addi	a0,a0,-898 # 800086b0 <syscalls+0x238>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	b06080e7          	jalr	-1274(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004a42:	00878693          	addi	a3,a5,8
    80004a46:	068a                	slli	a3,a3,0x2
    80004a48:	0023d717          	auipc	a4,0x23d
    80004a4c:	b5070713          	addi	a4,a4,-1200 # 80241598 <log>
    80004a50:	9736                	add	a4,a4,a3
    80004a52:	44d4                	lw	a3,12(s1)
    80004a54:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a56:	faf609e3          	beq	a2,a5,80004a08 <log_write+0x76>
  }
  release(&log.lock);
    80004a5a:	0023d517          	auipc	a0,0x23d
    80004a5e:	b3e50513          	addi	a0,a0,-1218 # 80241598 <log>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	3c0080e7          	jalr	960(ra) # 80000e22 <release>
}
    80004a6a:	60e2                	ld	ra,24(sp)
    80004a6c:	6442                	ld	s0,16(sp)
    80004a6e:	64a2                	ld	s1,8(sp)
    80004a70:	6902                	ld	s2,0(sp)
    80004a72:	6105                	addi	sp,sp,32
    80004a74:	8082                	ret

0000000080004a76 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a76:	1101                	addi	sp,sp,-32
    80004a78:	ec06                	sd	ra,24(sp)
    80004a7a:	e822                	sd	s0,16(sp)
    80004a7c:	e426                	sd	s1,8(sp)
    80004a7e:	e04a                	sd	s2,0(sp)
    80004a80:	1000                	addi	s0,sp,32
    80004a82:	84aa                	mv	s1,a0
    80004a84:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a86:	00004597          	auipc	a1,0x4
    80004a8a:	c4a58593          	addi	a1,a1,-950 # 800086d0 <syscalls+0x258>
    80004a8e:	0521                	addi	a0,a0,8
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	24e080e7          	jalr	590(ra) # 80000cde <initlock>
  lk->name = name;
    80004a98:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a9c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa0:	0204a423          	sw	zero,40(s1)
}
    80004aa4:	60e2                	ld	ra,24(sp)
    80004aa6:	6442                	ld	s0,16(sp)
    80004aa8:	64a2                	ld	s1,8(sp)
    80004aaa:	6902                	ld	s2,0(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret

0000000080004ab0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec06                	sd	ra,24(sp)
    80004ab4:	e822                	sd	s0,16(sp)
    80004ab6:	e426                	sd	s1,8(sp)
    80004ab8:	e04a                	sd	s2,0(sp)
    80004aba:	1000                	addi	s0,sp,32
    80004abc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004abe:	00850913          	addi	s2,a0,8
    80004ac2:	854a                	mv	a0,s2
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	2aa080e7          	jalr	682(ra) # 80000d6e <acquire>
  while (lk->locked) {
    80004acc:	409c                	lw	a5,0(s1)
    80004ace:	cb89                	beqz	a5,80004ae0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ad0:	85ca                	mv	a1,s2
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffe097          	auipc	ra,0xffffe
    80004ad8:	8ba080e7          	jalr	-1862(ra) # 8000238e <sleep>
  while (lk->locked) {
    80004adc:	409c                	lw	a5,0(s1)
    80004ade:	fbed                	bnez	a5,80004ad0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ae0:	4785                	li	a5,1
    80004ae2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ae4:	ffffd097          	auipc	ra,0xffffd
    80004ae8:	0a2080e7          	jalr	162(ra) # 80001b86 <myproc>
    80004aec:	591c                	lw	a5,48(a0)
    80004aee:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004af0:	854a                	mv	a0,s2
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	330080e7          	jalr	816(ra) # 80000e22 <release>
}
    80004afa:	60e2                	ld	ra,24(sp)
    80004afc:	6442                	ld	s0,16(sp)
    80004afe:	64a2                	ld	s1,8(sp)
    80004b00:	6902                	ld	s2,0(sp)
    80004b02:	6105                	addi	sp,sp,32
    80004b04:	8082                	ret

0000000080004b06 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b06:	1101                	addi	sp,sp,-32
    80004b08:	ec06                	sd	ra,24(sp)
    80004b0a:	e822                	sd	s0,16(sp)
    80004b0c:	e426                	sd	s1,8(sp)
    80004b0e:	e04a                	sd	s2,0(sp)
    80004b10:	1000                	addi	s0,sp,32
    80004b12:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b14:	00850913          	addi	s2,a0,8
    80004b18:	854a                	mv	a0,s2
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	254080e7          	jalr	596(ra) # 80000d6e <acquire>
  lk->locked = 0;
    80004b22:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b26:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffe097          	auipc	ra,0xffffe
    80004b30:	8c6080e7          	jalr	-1850(ra) # 800023f2 <wakeup>
  release(&lk->lk);
    80004b34:	854a                	mv	a0,s2
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	2ec080e7          	jalr	748(ra) # 80000e22 <release>
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6902                	ld	s2,0(sp)
    80004b46:	6105                	addi	sp,sp,32
    80004b48:	8082                	ret

0000000080004b4a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b4a:	7179                	addi	sp,sp,-48
    80004b4c:	f406                	sd	ra,40(sp)
    80004b4e:	f022                	sd	s0,32(sp)
    80004b50:	ec26                	sd	s1,24(sp)
    80004b52:	e84a                	sd	s2,16(sp)
    80004b54:	e44e                	sd	s3,8(sp)
    80004b56:	1800                	addi	s0,sp,48
    80004b58:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b5a:	00850913          	addi	s2,a0,8
    80004b5e:	854a                	mv	a0,s2
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	20e080e7          	jalr	526(ra) # 80000d6e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b68:	409c                	lw	a5,0(s1)
    80004b6a:	ef99                	bnez	a5,80004b88 <holdingsleep+0x3e>
    80004b6c:	4481                	li	s1,0
  release(&lk->lk);
    80004b6e:	854a                	mv	a0,s2
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	2b2080e7          	jalr	690(ra) # 80000e22 <release>
  return r;
}
    80004b78:	8526                	mv	a0,s1
    80004b7a:	70a2                	ld	ra,40(sp)
    80004b7c:	7402                	ld	s0,32(sp)
    80004b7e:	64e2                	ld	s1,24(sp)
    80004b80:	6942                	ld	s2,16(sp)
    80004b82:	69a2                	ld	s3,8(sp)
    80004b84:	6145                	addi	sp,sp,48
    80004b86:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b88:	0284a983          	lw	s3,40(s1)
    80004b8c:	ffffd097          	auipc	ra,0xffffd
    80004b90:	ffa080e7          	jalr	-6(ra) # 80001b86 <myproc>
    80004b94:	5904                	lw	s1,48(a0)
    80004b96:	413484b3          	sub	s1,s1,s3
    80004b9a:	0014b493          	seqz	s1,s1
    80004b9e:	bfc1                	j	80004b6e <holdingsleep+0x24>

0000000080004ba0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ba0:	1141                	addi	sp,sp,-16
    80004ba2:	e406                	sd	ra,8(sp)
    80004ba4:	e022                	sd	s0,0(sp)
    80004ba6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ba8:	00004597          	auipc	a1,0x4
    80004bac:	b3858593          	addi	a1,a1,-1224 # 800086e0 <syscalls+0x268>
    80004bb0:	0023d517          	auipc	a0,0x23d
    80004bb4:	b3050513          	addi	a0,a0,-1232 # 802416e0 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	126080e7          	jalr	294(ra) # 80000cde <initlock>
}
    80004bc0:	60a2                	ld	ra,8(sp)
    80004bc2:	6402                	ld	s0,0(sp)
    80004bc4:	0141                	addi	sp,sp,16
    80004bc6:	8082                	ret

0000000080004bc8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bc8:	1101                	addi	sp,sp,-32
    80004bca:	ec06                	sd	ra,24(sp)
    80004bcc:	e822                	sd	s0,16(sp)
    80004bce:	e426                	sd	s1,8(sp)
    80004bd0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bd2:	0023d517          	auipc	a0,0x23d
    80004bd6:	b0e50513          	addi	a0,a0,-1266 # 802416e0 <ftable>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	194080e7          	jalr	404(ra) # 80000d6e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be2:	0023d497          	auipc	s1,0x23d
    80004be6:	b1648493          	addi	s1,s1,-1258 # 802416f8 <ftable+0x18>
    80004bea:	0023e717          	auipc	a4,0x23e
    80004bee:	aae70713          	addi	a4,a4,-1362 # 80242698 <disk>
    if(f->ref == 0){
    80004bf2:	40dc                	lw	a5,4(s1)
    80004bf4:	cf99                	beqz	a5,80004c12 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bf6:	02848493          	addi	s1,s1,40
    80004bfa:	fee49ce3          	bne	s1,a4,80004bf2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bfe:	0023d517          	auipc	a0,0x23d
    80004c02:	ae250513          	addi	a0,a0,-1310 # 802416e0 <ftable>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	21c080e7          	jalr	540(ra) # 80000e22 <release>
  return 0;
    80004c0e:	4481                	li	s1,0
    80004c10:	a819                	j	80004c26 <filealloc+0x5e>
      f->ref = 1;
    80004c12:	4785                	li	a5,1
    80004c14:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c16:	0023d517          	auipc	a0,0x23d
    80004c1a:	aca50513          	addi	a0,a0,-1334 # 802416e0 <ftable>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	204080e7          	jalr	516(ra) # 80000e22 <release>
}
    80004c26:	8526                	mv	a0,s1
    80004c28:	60e2                	ld	ra,24(sp)
    80004c2a:	6442                	ld	s0,16(sp)
    80004c2c:	64a2                	ld	s1,8(sp)
    80004c2e:	6105                	addi	sp,sp,32
    80004c30:	8082                	ret

0000000080004c32 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c32:	1101                	addi	sp,sp,-32
    80004c34:	ec06                	sd	ra,24(sp)
    80004c36:	e822                	sd	s0,16(sp)
    80004c38:	e426                	sd	s1,8(sp)
    80004c3a:	1000                	addi	s0,sp,32
    80004c3c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c3e:	0023d517          	auipc	a0,0x23d
    80004c42:	aa250513          	addi	a0,a0,-1374 # 802416e0 <ftable>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	128080e7          	jalr	296(ra) # 80000d6e <acquire>
  if(f->ref < 1)
    80004c4e:	40dc                	lw	a5,4(s1)
    80004c50:	02f05263          	blez	a5,80004c74 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c54:	2785                	addiw	a5,a5,1
    80004c56:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c58:	0023d517          	auipc	a0,0x23d
    80004c5c:	a8850513          	addi	a0,a0,-1400 # 802416e0 <ftable>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	1c2080e7          	jalr	450(ra) # 80000e22 <release>
  return f;
}
    80004c68:	8526                	mv	a0,s1
    80004c6a:	60e2                	ld	ra,24(sp)
    80004c6c:	6442                	ld	s0,16(sp)
    80004c6e:	64a2                	ld	s1,8(sp)
    80004c70:	6105                	addi	sp,sp,32
    80004c72:	8082                	ret
    panic("filedup");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	a7450513          	addi	a0,a0,-1420 # 800086e8 <syscalls+0x270>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8c4080e7          	jalr	-1852(ra) # 80000540 <panic>

0000000080004c84 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c84:	7139                	addi	sp,sp,-64
    80004c86:	fc06                	sd	ra,56(sp)
    80004c88:	f822                	sd	s0,48(sp)
    80004c8a:	f426                	sd	s1,40(sp)
    80004c8c:	f04a                	sd	s2,32(sp)
    80004c8e:	ec4e                	sd	s3,24(sp)
    80004c90:	e852                	sd	s4,16(sp)
    80004c92:	e456                	sd	s5,8(sp)
    80004c94:	0080                	addi	s0,sp,64
    80004c96:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c98:	0023d517          	auipc	a0,0x23d
    80004c9c:	a4850513          	addi	a0,a0,-1464 # 802416e0 <ftable>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	0ce080e7          	jalr	206(ra) # 80000d6e <acquire>
  if(f->ref < 1)
    80004ca8:	40dc                	lw	a5,4(s1)
    80004caa:	06f05163          	blez	a5,80004d0c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cae:	37fd                	addiw	a5,a5,-1
    80004cb0:	0007871b          	sext.w	a4,a5
    80004cb4:	c0dc                	sw	a5,4(s1)
    80004cb6:	06e04363          	bgtz	a4,80004d1c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cba:	0004a903          	lw	s2,0(s1)
    80004cbe:	0094ca83          	lbu	s5,9(s1)
    80004cc2:	0104ba03          	ld	s4,16(s1)
    80004cc6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cca:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cce:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cd2:	0023d517          	auipc	a0,0x23d
    80004cd6:	a0e50513          	addi	a0,a0,-1522 # 802416e0 <ftable>
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	148080e7          	jalr	328(ra) # 80000e22 <release>

  if(ff.type == FD_PIPE){
    80004ce2:	4785                	li	a5,1
    80004ce4:	04f90d63          	beq	s2,a5,80004d3e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ce8:	3979                	addiw	s2,s2,-2
    80004cea:	4785                	li	a5,1
    80004cec:	0527e063          	bltu	a5,s2,80004d2c <fileclose+0xa8>
    begin_op();
    80004cf0:	00000097          	auipc	ra,0x0
    80004cf4:	acc080e7          	jalr	-1332(ra) # 800047bc <begin_op>
    iput(ff.ip);
    80004cf8:	854e                	mv	a0,s3
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	2b0080e7          	jalr	688(ra) # 80003faa <iput>
    end_op();
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	b38080e7          	jalr	-1224(ra) # 8000483a <end_op>
    80004d0a:	a00d                	j	80004d2c <fileclose+0xa8>
    panic("fileclose");
    80004d0c:	00004517          	auipc	a0,0x4
    80004d10:	9e450513          	addi	a0,a0,-1564 # 800086f0 <syscalls+0x278>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	82c080e7          	jalr	-2004(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004d1c:	0023d517          	auipc	a0,0x23d
    80004d20:	9c450513          	addi	a0,a0,-1596 # 802416e0 <ftable>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	0fe080e7          	jalr	254(ra) # 80000e22 <release>
  }
}
    80004d2c:	70e2                	ld	ra,56(sp)
    80004d2e:	7442                	ld	s0,48(sp)
    80004d30:	74a2                	ld	s1,40(sp)
    80004d32:	7902                	ld	s2,32(sp)
    80004d34:	69e2                	ld	s3,24(sp)
    80004d36:	6a42                	ld	s4,16(sp)
    80004d38:	6aa2                	ld	s5,8(sp)
    80004d3a:	6121                	addi	sp,sp,64
    80004d3c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d3e:	85d6                	mv	a1,s5
    80004d40:	8552                	mv	a0,s4
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	34c080e7          	jalr	844(ra) # 8000508e <pipeclose>
    80004d4a:	b7cd                	j	80004d2c <fileclose+0xa8>

0000000080004d4c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d4c:	715d                	addi	sp,sp,-80
    80004d4e:	e486                	sd	ra,72(sp)
    80004d50:	e0a2                	sd	s0,64(sp)
    80004d52:	fc26                	sd	s1,56(sp)
    80004d54:	f84a                	sd	s2,48(sp)
    80004d56:	f44e                	sd	s3,40(sp)
    80004d58:	0880                	addi	s0,sp,80
    80004d5a:	84aa                	mv	s1,a0
    80004d5c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	e28080e7          	jalr	-472(ra) # 80001b86 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d66:	409c                	lw	a5,0(s1)
    80004d68:	37f9                	addiw	a5,a5,-2
    80004d6a:	4705                	li	a4,1
    80004d6c:	04f76763          	bltu	a4,a5,80004dba <filestat+0x6e>
    80004d70:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d72:	6c88                	ld	a0,24(s1)
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	07c080e7          	jalr	124(ra) # 80003df0 <ilock>
    stati(f->ip, &st);
    80004d7c:	fb840593          	addi	a1,s0,-72
    80004d80:	6c88                	ld	a0,24(s1)
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	2f8080e7          	jalr	760(ra) # 8000407a <stati>
    iunlock(f->ip);
    80004d8a:	6c88                	ld	a0,24(s1)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	126080e7          	jalr	294(ra) # 80003eb2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d94:	46e1                	li	a3,24
    80004d96:	fb840613          	addi	a2,s0,-72
    80004d9a:	85ce                	mv	a1,s3
    80004d9c:	05093503          	ld	a0,80(s2)
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	a6e080e7          	jalr	-1426(ra) # 8000180e <copyout>
    80004da8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dac:	60a6                	ld	ra,72(sp)
    80004dae:	6406                	ld	s0,64(sp)
    80004db0:	74e2                	ld	s1,56(sp)
    80004db2:	7942                	ld	s2,48(sp)
    80004db4:	79a2                	ld	s3,40(sp)
    80004db6:	6161                	addi	sp,sp,80
    80004db8:	8082                	ret
  return -1;
    80004dba:	557d                	li	a0,-1
    80004dbc:	bfc5                	j	80004dac <filestat+0x60>

0000000080004dbe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dbe:	7179                	addi	sp,sp,-48
    80004dc0:	f406                	sd	ra,40(sp)
    80004dc2:	f022                	sd	s0,32(sp)
    80004dc4:	ec26                	sd	s1,24(sp)
    80004dc6:	e84a                	sd	s2,16(sp)
    80004dc8:	e44e                	sd	s3,8(sp)
    80004dca:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dcc:	00854783          	lbu	a5,8(a0)
    80004dd0:	c3d5                	beqz	a5,80004e74 <fileread+0xb6>
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	89ae                	mv	s3,a1
    80004dd6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dd8:	411c                	lw	a5,0(a0)
    80004dda:	4705                	li	a4,1
    80004ddc:	04e78963          	beq	a5,a4,80004e2e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004de0:	470d                	li	a4,3
    80004de2:	04e78d63          	beq	a5,a4,80004e3c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de6:	4709                	li	a4,2
    80004de8:	06e79e63          	bne	a5,a4,80004e64 <fileread+0xa6>
    ilock(f->ip);
    80004dec:	6d08                	ld	a0,24(a0)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	002080e7          	jalr	2(ra) # 80003df0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004df6:	874a                	mv	a4,s2
    80004df8:	5094                	lw	a3,32(s1)
    80004dfa:	864e                	mv	a2,s3
    80004dfc:	4585                	li	a1,1
    80004dfe:	6c88                	ld	a0,24(s1)
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	2a4080e7          	jalr	676(ra) # 800040a4 <readi>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	00a05563          	blez	a0,80004e14 <fileread+0x56>
      f->off += r;
    80004e0e:	509c                	lw	a5,32(s1)
    80004e10:	9fa9                	addw	a5,a5,a0
    80004e12:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e14:	6c88                	ld	a0,24(s1)
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	09c080e7          	jalr	156(ra) # 80003eb2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e1e:	854a                	mv	a0,s2
    80004e20:	70a2                	ld	ra,40(sp)
    80004e22:	7402                	ld	s0,32(sp)
    80004e24:	64e2                	ld	s1,24(sp)
    80004e26:	6942                	ld	s2,16(sp)
    80004e28:	69a2                	ld	s3,8(sp)
    80004e2a:	6145                	addi	sp,sp,48
    80004e2c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e2e:	6908                	ld	a0,16(a0)
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	3c6080e7          	jalr	966(ra) # 800051f6 <piperead>
    80004e38:	892a                	mv	s2,a0
    80004e3a:	b7d5                	j	80004e1e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e3c:	02451783          	lh	a5,36(a0)
    80004e40:	03079693          	slli	a3,a5,0x30
    80004e44:	92c1                	srli	a3,a3,0x30
    80004e46:	4725                	li	a4,9
    80004e48:	02d76863          	bltu	a4,a3,80004e78 <fileread+0xba>
    80004e4c:	0792                	slli	a5,a5,0x4
    80004e4e:	0023c717          	auipc	a4,0x23c
    80004e52:	7f270713          	addi	a4,a4,2034 # 80241640 <devsw>
    80004e56:	97ba                	add	a5,a5,a4
    80004e58:	639c                	ld	a5,0(a5)
    80004e5a:	c38d                	beqz	a5,80004e7c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e5c:	4505                	li	a0,1
    80004e5e:	9782                	jalr	a5
    80004e60:	892a                	mv	s2,a0
    80004e62:	bf75                	j	80004e1e <fileread+0x60>
    panic("fileread");
    80004e64:	00004517          	auipc	a0,0x4
    80004e68:	89c50513          	addi	a0,a0,-1892 # 80008700 <syscalls+0x288>
    80004e6c:	ffffb097          	auipc	ra,0xffffb
    80004e70:	6d4080e7          	jalr	1748(ra) # 80000540 <panic>
    return -1;
    80004e74:	597d                	li	s2,-1
    80004e76:	b765                	j	80004e1e <fileread+0x60>
      return -1;
    80004e78:	597d                	li	s2,-1
    80004e7a:	b755                	j	80004e1e <fileread+0x60>
    80004e7c:	597d                	li	s2,-1
    80004e7e:	b745                	j	80004e1e <fileread+0x60>

0000000080004e80 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e80:	715d                	addi	sp,sp,-80
    80004e82:	e486                	sd	ra,72(sp)
    80004e84:	e0a2                	sd	s0,64(sp)
    80004e86:	fc26                	sd	s1,56(sp)
    80004e88:	f84a                	sd	s2,48(sp)
    80004e8a:	f44e                	sd	s3,40(sp)
    80004e8c:	f052                	sd	s4,32(sp)
    80004e8e:	ec56                	sd	s5,24(sp)
    80004e90:	e85a                	sd	s6,16(sp)
    80004e92:	e45e                	sd	s7,8(sp)
    80004e94:	e062                	sd	s8,0(sp)
    80004e96:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e98:	00954783          	lbu	a5,9(a0)
    80004e9c:	10078663          	beqz	a5,80004fa8 <filewrite+0x128>
    80004ea0:	892a                	mv	s2,a0
    80004ea2:	8b2e                	mv	s6,a1
    80004ea4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ea6:	411c                	lw	a5,0(a0)
    80004ea8:	4705                	li	a4,1
    80004eaa:	02e78263          	beq	a5,a4,80004ece <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eae:	470d                	li	a4,3
    80004eb0:	02e78663          	beq	a5,a4,80004edc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb4:	4709                	li	a4,2
    80004eb6:	0ee79163          	bne	a5,a4,80004f98 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004eba:	0ac05d63          	blez	a2,80004f74 <filewrite+0xf4>
    int i = 0;
    80004ebe:	4981                	li	s3,0
    80004ec0:	6b85                	lui	s7,0x1
    80004ec2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ec6:	6c05                	lui	s8,0x1
    80004ec8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004ecc:	a861                	j	80004f64 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ece:	6908                	ld	a0,16(a0)
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	22e080e7          	jalr	558(ra) # 800050fe <pipewrite>
    80004ed8:	8a2a                	mv	s4,a0
    80004eda:	a045                	j	80004f7a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004edc:	02451783          	lh	a5,36(a0)
    80004ee0:	03079693          	slli	a3,a5,0x30
    80004ee4:	92c1                	srli	a3,a3,0x30
    80004ee6:	4725                	li	a4,9
    80004ee8:	0cd76263          	bltu	a4,a3,80004fac <filewrite+0x12c>
    80004eec:	0792                	slli	a5,a5,0x4
    80004eee:	0023c717          	auipc	a4,0x23c
    80004ef2:	75270713          	addi	a4,a4,1874 # 80241640 <devsw>
    80004ef6:	97ba                	add	a5,a5,a4
    80004ef8:	679c                	ld	a5,8(a5)
    80004efa:	cbdd                	beqz	a5,80004fb0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004efc:	4505                	li	a0,1
    80004efe:	9782                	jalr	a5
    80004f00:	8a2a                	mv	s4,a0
    80004f02:	a8a5                	j	80004f7a <filewrite+0xfa>
    80004f04:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f08:	00000097          	auipc	ra,0x0
    80004f0c:	8b4080e7          	jalr	-1868(ra) # 800047bc <begin_op>
      ilock(f->ip);
    80004f10:	01893503          	ld	a0,24(s2)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	edc080e7          	jalr	-292(ra) # 80003df0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f1c:	8756                	mv	a4,s5
    80004f1e:	02092683          	lw	a3,32(s2)
    80004f22:	01698633          	add	a2,s3,s6
    80004f26:	4585                	li	a1,1
    80004f28:	01893503          	ld	a0,24(s2)
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	270080e7          	jalr	624(ra) # 8000419c <writei>
    80004f34:	84aa                	mv	s1,a0
    80004f36:	00a05763          	blez	a0,80004f44 <filewrite+0xc4>
        f->off += r;
    80004f3a:	02092783          	lw	a5,32(s2)
    80004f3e:	9fa9                	addw	a5,a5,a0
    80004f40:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f44:	01893503          	ld	a0,24(s2)
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	f6a080e7          	jalr	-150(ra) # 80003eb2 <iunlock>
      end_op();
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	8ea080e7          	jalr	-1814(ra) # 8000483a <end_op>

      if(r != n1){
    80004f58:	009a9f63          	bne	s5,s1,80004f76 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f5c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f60:	0149db63          	bge	s3,s4,80004f76 <filewrite+0xf6>
      int n1 = n - i;
    80004f64:	413a04bb          	subw	s1,s4,s3
    80004f68:	0004879b          	sext.w	a5,s1
    80004f6c:	f8fbdce3          	bge	s7,a5,80004f04 <filewrite+0x84>
    80004f70:	84e2                	mv	s1,s8
    80004f72:	bf49                	j	80004f04 <filewrite+0x84>
    int i = 0;
    80004f74:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f76:	013a1f63          	bne	s4,s3,80004f94 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f7a:	8552                	mv	a0,s4
    80004f7c:	60a6                	ld	ra,72(sp)
    80004f7e:	6406                	ld	s0,64(sp)
    80004f80:	74e2                	ld	s1,56(sp)
    80004f82:	7942                	ld	s2,48(sp)
    80004f84:	79a2                	ld	s3,40(sp)
    80004f86:	7a02                	ld	s4,32(sp)
    80004f88:	6ae2                	ld	s5,24(sp)
    80004f8a:	6b42                	ld	s6,16(sp)
    80004f8c:	6ba2                	ld	s7,8(sp)
    80004f8e:	6c02                	ld	s8,0(sp)
    80004f90:	6161                	addi	sp,sp,80
    80004f92:	8082                	ret
    ret = (i == n ? n : -1);
    80004f94:	5a7d                	li	s4,-1
    80004f96:	b7d5                	j	80004f7a <filewrite+0xfa>
    panic("filewrite");
    80004f98:	00003517          	auipc	a0,0x3
    80004f9c:	77850513          	addi	a0,a0,1912 # 80008710 <syscalls+0x298>
    80004fa0:	ffffb097          	auipc	ra,0xffffb
    80004fa4:	5a0080e7          	jalr	1440(ra) # 80000540 <panic>
    return -1;
    80004fa8:	5a7d                	li	s4,-1
    80004faa:	bfc1                	j	80004f7a <filewrite+0xfa>
      return -1;
    80004fac:	5a7d                	li	s4,-1
    80004fae:	b7f1                	j	80004f7a <filewrite+0xfa>
    80004fb0:	5a7d                	li	s4,-1
    80004fb2:	b7e1                	j	80004f7a <filewrite+0xfa>

0000000080004fb4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fb4:	7179                	addi	sp,sp,-48
    80004fb6:	f406                	sd	ra,40(sp)
    80004fb8:	f022                	sd	s0,32(sp)
    80004fba:	ec26                	sd	s1,24(sp)
    80004fbc:	e84a                	sd	s2,16(sp)
    80004fbe:	e44e                	sd	s3,8(sp)
    80004fc0:	e052                	sd	s4,0(sp)
    80004fc2:	1800                	addi	s0,sp,48
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fc8:	0005b023          	sd	zero,0(a1)
    80004fcc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fd0:	00000097          	auipc	ra,0x0
    80004fd4:	bf8080e7          	jalr	-1032(ra) # 80004bc8 <filealloc>
    80004fd8:	e088                	sd	a0,0(s1)
    80004fda:	c551                	beqz	a0,80005066 <pipealloc+0xb2>
    80004fdc:	00000097          	auipc	ra,0x0
    80004fe0:	bec080e7          	jalr	-1044(ra) # 80004bc8 <filealloc>
    80004fe4:	00aa3023          	sd	a0,0(s4)
    80004fe8:	c92d                	beqz	a0,8000505a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	c80080e7          	jalr	-896(ra) # 80000c6a <kalloc>
    80004ff2:	892a                	mv	s2,a0
    80004ff4:	c125                	beqz	a0,80005054 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ff6:	4985                	li	s3,1
    80004ff8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ffc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005000:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005004:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005008:	00003597          	auipc	a1,0x3
    8000500c:	71858593          	addi	a1,a1,1816 # 80008720 <syscalls+0x2a8>
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	cce080e7          	jalr	-818(ra) # 80000cde <initlock>
  (*f0)->type = FD_PIPE;
    80005018:	609c                	ld	a5,0(s1)
    8000501a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000501e:	609c                	ld	a5,0(s1)
    80005020:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005024:	609c                	ld	a5,0(s1)
    80005026:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000502a:	609c                	ld	a5,0(s1)
    8000502c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005030:	000a3783          	ld	a5,0(s4)
    80005034:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005038:	000a3783          	ld	a5,0(s4)
    8000503c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005040:	000a3783          	ld	a5,0(s4)
    80005044:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005048:	000a3783          	ld	a5,0(s4)
    8000504c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005050:	4501                	li	a0,0
    80005052:	a025                	j	8000507a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005054:	6088                	ld	a0,0(s1)
    80005056:	e501                	bnez	a0,8000505e <pipealloc+0xaa>
    80005058:	a039                	j	80005066 <pipealloc+0xb2>
    8000505a:	6088                	ld	a0,0(s1)
    8000505c:	c51d                	beqz	a0,8000508a <pipealloc+0xd6>
    fileclose(*f0);
    8000505e:	00000097          	auipc	ra,0x0
    80005062:	c26080e7          	jalr	-986(ra) # 80004c84 <fileclose>
  if(*f1)
    80005066:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000506a:	557d                	li	a0,-1
  if(*f1)
    8000506c:	c799                	beqz	a5,8000507a <pipealloc+0xc6>
    fileclose(*f1);
    8000506e:	853e                	mv	a0,a5
    80005070:	00000097          	auipc	ra,0x0
    80005074:	c14080e7          	jalr	-1004(ra) # 80004c84 <fileclose>
  return -1;
    80005078:	557d                	li	a0,-1
}
    8000507a:	70a2                	ld	ra,40(sp)
    8000507c:	7402                	ld	s0,32(sp)
    8000507e:	64e2                	ld	s1,24(sp)
    80005080:	6942                	ld	s2,16(sp)
    80005082:	69a2                	ld	s3,8(sp)
    80005084:	6a02                	ld	s4,0(sp)
    80005086:	6145                	addi	sp,sp,48
    80005088:	8082                	ret
  return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	b7fd                	j	8000507a <pipealloc+0xc6>

000000008000508e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000508e:	1101                	addi	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	e04a                	sd	s2,0(sp)
    80005098:	1000                	addi	s0,sp,32
    8000509a:	84aa                	mv	s1,a0
    8000509c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	cd0080e7          	jalr	-816(ra) # 80000d6e <acquire>
  if(writable){
    800050a6:	02090d63          	beqz	s2,800050e0 <pipeclose+0x52>
    pi->writeopen = 0;
    800050aa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050ae:	21848513          	addi	a0,s1,536
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	340080e7          	jalr	832(ra) # 800023f2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050ba:	2204b783          	ld	a5,544(s1)
    800050be:	eb95                	bnez	a5,800050f2 <pipeclose+0x64>
    release(&pi->lock);
    800050c0:	8526                	mv	a0,s1
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	d60080e7          	jalr	-672(ra) # 80000e22 <release>
    kfree((char*)pi);
    800050ca:	8526                	mv	a0,s1
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	a42080e7          	jalr	-1470(ra) # 80000b0e <kfree>
  } else
    release(&pi->lock);
}
    800050d4:	60e2                	ld	ra,24(sp)
    800050d6:	6442                	ld	s0,16(sp)
    800050d8:	64a2                	ld	s1,8(sp)
    800050da:	6902                	ld	s2,0(sp)
    800050dc:	6105                	addi	sp,sp,32
    800050de:	8082                	ret
    pi->readopen = 0;
    800050e0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050e4:	21c48513          	addi	a0,s1,540
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	30a080e7          	jalr	778(ra) # 800023f2 <wakeup>
    800050f0:	b7e9                	j	800050ba <pipeclose+0x2c>
    release(&pi->lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	d2e080e7          	jalr	-722(ra) # 80000e22 <release>
}
    800050fc:	bfe1                	j	800050d4 <pipeclose+0x46>

00000000800050fe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050fe:	711d                	addi	sp,sp,-96
    80005100:	ec86                	sd	ra,88(sp)
    80005102:	e8a2                	sd	s0,80(sp)
    80005104:	e4a6                	sd	s1,72(sp)
    80005106:	e0ca                	sd	s2,64(sp)
    80005108:	fc4e                	sd	s3,56(sp)
    8000510a:	f852                	sd	s4,48(sp)
    8000510c:	f456                	sd	s5,40(sp)
    8000510e:	f05a                	sd	s6,32(sp)
    80005110:	ec5e                	sd	s7,24(sp)
    80005112:	e862                	sd	s8,16(sp)
    80005114:	1080                	addi	s0,sp,96
    80005116:	84aa                	mv	s1,a0
    80005118:	8aae                	mv	s5,a1
    8000511a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	a6a080e7          	jalr	-1430(ra) # 80001b86 <myproc>
    80005124:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005126:	8526                	mv	a0,s1
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	c46080e7          	jalr	-954(ra) # 80000d6e <acquire>
  while(i < n){
    80005130:	0b405663          	blez	s4,800051dc <pipewrite+0xde>
  int i = 0;
    80005134:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005136:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005138:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000513c:	21c48b93          	addi	s7,s1,540
    80005140:	a089                	j	80005182 <pipewrite+0x84>
      release(&pi->lock);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	cde080e7          	jalr	-802(ra) # 80000e22 <release>
      return -1;
    8000514c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000514e:	854a                	mv	a0,s2
    80005150:	60e6                	ld	ra,88(sp)
    80005152:	6446                	ld	s0,80(sp)
    80005154:	64a6                	ld	s1,72(sp)
    80005156:	6906                	ld	s2,64(sp)
    80005158:	79e2                	ld	s3,56(sp)
    8000515a:	7a42                	ld	s4,48(sp)
    8000515c:	7aa2                	ld	s5,40(sp)
    8000515e:	7b02                	ld	s6,32(sp)
    80005160:	6be2                	ld	s7,24(sp)
    80005162:	6c42                	ld	s8,16(sp)
    80005164:	6125                	addi	sp,sp,96
    80005166:	8082                	ret
      wakeup(&pi->nread);
    80005168:	8562                	mv	a0,s8
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	288080e7          	jalr	648(ra) # 800023f2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005172:	85a6                	mv	a1,s1
    80005174:	855e                	mv	a0,s7
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	218080e7          	jalr	536(ra) # 8000238e <sleep>
  while(i < n){
    8000517e:	07495063          	bge	s2,s4,800051de <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005182:	2204a783          	lw	a5,544(s1)
    80005186:	dfd5                	beqz	a5,80005142 <pipewrite+0x44>
    80005188:	854e                	mv	a0,s3
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	4b8080e7          	jalr	1208(ra) # 80002642 <killed>
    80005192:	f945                	bnez	a0,80005142 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005194:	2184a783          	lw	a5,536(s1)
    80005198:	21c4a703          	lw	a4,540(s1)
    8000519c:	2007879b          	addiw	a5,a5,512
    800051a0:	fcf704e3          	beq	a4,a5,80005168 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051a4:	4685                	li	a3,1
    800051a6:	01590633          	add	a2,s2,s5
    800051aa:	faf40593          	addi	a1,s0,-81
    800051ae:	0509b503          	ld	a0,80(s3)
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	720080e7          	jalr	1824(ra) # 800018d2 <copyin>
    800051ba:	03650263          	beq	a0,s6,800051de <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051be:	21c4a783          	lw	a5,540(s1)
    800051c2:	0017871b          	addiw	a4,a5,1
    800051c6:	20e4ae23          	sw	a4,540(s1)
    800051ca:	1ff7f793          	andi	a5,a5,511
    800051ce:	97a6                	add	a5,a5,s1
    800051d0:	faf44703          	lbu	a4,-81(s0)
    800051d4:	00e78c23          	sb	a4,24(a5)
      i++;
    800051d8:	2905                	addiw	s2,s2,1
    800051da:	b755                	j	8000517e <pipewrite+0x80>
  int i = 0;
    800051dc:	4901                	li	s2,0
  wakeup(&pi->nread);
    800051de:	21848513          	addi	a0,s1,536
    800051e2:	ffffd097          	auipc	ra,0xffffd
    800051e6:	210080e7          	jalr	528(ra) # 800023f2 <wakeup>
  release(&pi->lock);
    800051ea:	8526                	mv	a0,s1
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	c36080e7          	jalr	-970(ra) # 80000e22 <release>
  return i;
    800051f4:	bfa9                	j	8000514e <pipewrite+0x50>

00000000800051f6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051f6:	715d                	addi	sp,sp,-80
    800051f8:	e486                	sd	ra,72(sp)
    800051fa:	e0a2                	sd	s0,64(sp)
    800051fc:	fc26                	sd	s1,56(sp)
    800051fe:	f84a                	sd	s2,48(sp)
    80005200:	f44e                	sd	s3,40(sp)
    80005202:	f052                	sd	s4,32(sp)
    80005204:	ec56                	sd	s5,24(sp)
    80005206:	e85a                	sd	s6,16(sp)
    80005208:	0880                	addi	s0,sp,80
    8000520a:	84aa                	mv	s1,a0
    8000520c:	892e                	mv	s2,a1
    8000520e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005210:	ffffd097          	auipc	ra,0xffffd
    80005214:	976080e7          	jalr	-1674(ra) # 80001b86 <myproc>
    80005218:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	b52080e7          	jalr	-1198(ra) # 80000d6e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005224:	2184a703          	lw	a4,536(s1)
    80005228:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000522c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005230:	02f71763          	bne	a4,a5,8000525e <piperead+0x68>
    80005234:	2244a783          	lw	a5,548(s1)
    80005238:	c39d                	beqz	a5,8000525e <piperead+0x68>
    if(killed(pr)){
    8000523a:	8552                	mv	a0,s4
    8000523c:	ffffd097          	auipc	ra,0xffffd
    80005240:	406080e7          	jalr	1030(ra) # 80002642 <killed>
    80005244:	e949                	bnez	a0,800052d6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005246:	85a6                	mv	a1,s1
    80005248:	854e                	mv	a0,s3
    8000524a:	ffffd097          	auipc	ra,0xffffd
    8000524e:	144080e7          	jalr	324(ra) # 8000238e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005252:	2184a703          	lw	a4,536(s1)
    80005256:	21c4a783          	lw	a5,540(s1)
    8000525a:	fcf70de3          	beq	a4,a5,80005234 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000525e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005260:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005262:	05505463          	blez	s5,800052aa <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005266:	2184a783          	lw	a5,536(s1)
    8000526a:	21c4a703          	lw	a4,540(s1)
    8000526e:	02f70e63          	beq	a4,a5,800052aa <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005272:	0017871b          	addiw	a4,a5,1
    80005276:	20e4ac23          	sw	a4,536(s1)
    8000527a:	1ff7f793          	andi	a5,a5,511
    8000527e:	97a6                	add	a5,a5,s1
    80005280:	0187c783          	lbu	a5,24(a5)
    80005284:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005288:	4685                	li	a3,1
    8000528a:	fbf40613          	addi	a2,s0,-65
    8000528e:	85ca                	mv	a1,s2
    80005290:	050a3503          	ld	a0,80(s4)
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	57a080e7          	jalr	1402(ra) # 8000180e <copyout>
    8000529c:	01650763          	beq	a0,s6,800052aa <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052a0:	2985                	addiw	s3,s3,1
    800052a2:	0905                	addi	s2,s2,1
    800052a4:	fd3a91e3          	bne	s5,s3,80005266 <piperead+0x70>
    800052a8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052aa:	21c48513          	addi	a0,s1,540
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	144080e7          	jalr	324(ra) # 800023f2 <wakeup>
  release(&pi->lock);
    800052b6:	8526                	mv	a0,s1
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	b6a080e7          	jalr	-1174(ra) # 80000e22 <release>
  return i;
}
    800052c0:	854e                	mv	a0,s3
    800052c2:	60a6                	ld	ra,72(sp)
    800052c4:	6406                	ld	s0,64(sp)
    800052c6:	74e2                	ld	s1,56(sp)
    800052c8:	7942                	ld	s2,48(sp)
    800052ca:	79a2                	ld	s3,40(sp)
    800052cc:	7a02                	ld	s4,32(sp)
    800052ce:	6ae2                	ld	s5,24(sp)
    800052d0:	6b42                	ld	s6,16(sp)
    800052d2:	6161                	addi	sp,sp,80
    800052d4:	8082                	ret
      release(&pi->lock);
    800052d6:	8526                	mv	a0,s1
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	b4a080e7          	jalr	-1206(ra) # 80000e22 <release>
      return -1;
    800052e0:	59fd                	li	s3,-1
    800052e2:	bff9                	j	800052c0 <piperead+0xca>

00000000800052e4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052e4:	1141                	addi	sp,sp,-16
    800052e6:	e422                	sd	s0,8(sp)
    800052e8:	0800                	addi	s0,sp,16
    800052ea:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052ec:	8905                	andi	a0,a0,1
    800052ee:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800052f0:	8b89                	andi	a5,a5,2
    800052f2:	c399                	beqz	a5,800052f8 <flags2perm+0x14>
      perm |= PTE_W;
    800052f4:	00456513          	ori	a0,a0,4
    return perm;
}
    800052f8:	6422                	ld	s0,8(sp)
    800052fa:	0141                	addi	sp,sp,16
    800052fc:	8082                	ret

00000000800052fe <exec>:

int
exec(char *path, char **argv)
{
    800052fe:	de010113          	addi	sp,sp,-544
    80005302:	20113c23          	sd	ra,536(sp)
    80005306:	20813823          	sd	s0,528(sp)
    8000530a:	20913423          	sd	s1,520(sp)
    8000530e:	21213023          	sd	s2,512(sp)
    80005312:	ffce                	sd	s3,504(sp)
    80005314:	fbd2                	sd	s4,496(sp)
    80005316:	f7d6                	sd	s5,488(sp)
    80005318:	f3da                	sd	s6,480(sp)
    8000531a:	efde                	sd	s7,472(sp)
    8000531c:	ebe2                	sd	s8,464(sp)
    8000531e:	e7e6                	sd	s9,456(sp)
    80005320:	e3ea                	sd	s10,448(sp)
    80005322:	ff6e                	sd	s11,440(sp)
    80005324:	1400                	addi	s0,sp,544
    80005326:	892a                	mv	s2,a0
    80005328:	dea43423          	sd	a0,-536(s0)
    8000532c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005330:	ffffd097          	auipc	ra,0xffffd
    80005334:	856080e7          	jalr	-1962(ra) # 80001b86 <myproc>
    80005338:	84aa                	mv	s1,a0

  begin_op();
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	482080e7          	jalr	1154(ra) # 800047bc <begin_op>

  if((ip = namei(path)) == 0){
    80005342:	854a                	mv	a0,s2
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	258080e7          	jalr	600(ra) # 8000459c <namei>
    8000534c:	c93d                	beqz	a0,800053c2 <exec+0xc4>
    8000534e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	aa0080e7          	jalr	-1376(ra) # 80003df0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005358:	04000713          	li	a4,64
    8000535c:	4681                	li	a3,0
    8000535e:	e5040613          	addi	a2,s0,-432
    80005362:	4581                	li	a1,0
    80005364:	8556                	mv	a0,s5
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	d3e080e7          	jalr	-706(ra) # 800040a4 <readi>
    8000536e:	04000793          	li	a5,64
    80005372:	00f51a63          	bne	a0,a5,80005386 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005376:	e5042703          	lw	a4,-432(s0)
    8000537a:	464c47b7          	lui	a5,0x464c4
    8000537e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005382:	04f70663          	beq	a4,a5,800053ce <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005386:	8556                	mv	a0,s5
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	cca080e7          	jalr	-822(ra) # 80004052 <iunlockput>
    end_op();
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	4aa080e7          	jalr	1194(ra) # 8000483a <end_op>
  }
  return -1;
    80005398:	557d                	li	a0,-1
}
    8000539a:	21813083          	ld	ra,536(sp)
    8000539e:	21013403          	ld	s0,528(sp)
    800053a2:	20813483          	ld	s1,520(sp)
    800053a6:	20013903          	ld	s2,512(sp)
    800053aa:	79fe                	ld	s3,504(sp)
    800053ac:	7a5e                	ld	s4,496(sp)
    800053ae:	7abe                	ld	s5,488(sp)
    800053b0:	7b1e                	ld	s6,480(sp)
    800053b2:	6bfe                	ld	s7,472(sp)
    800053b4:	6c5e                	ld	s8,464(sp)
    800053b6:	6cbe                	ld	s9,456(sp)
    800053b8:	6d1e                	ld	s10,448(sp)
    800053ba:	7dfa                	ld	s11,440(sp)
    800053bc:	22010113          	addi	sp,sp,544
    800053c0:	8082                	ret
    end_op();
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	478080e7          	jalr	1144(ra) # 8000483a <end_op>
    return -1;
    800053ca:	557d                	li	a0,-1
    800053cc:	b7f9                	j	8000539a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800053ce:	8526                	mv	a0,s1
    800053d0:	ffffd097          	auipc	ra,0xffffd
    800053d4:	87a080e7          	jalr	-1926(ra) # 80001c4a <proc_pagetable>
    800053d8:	8b2a                	mv	s6,a0
    800053da:	d555                	beqz	a0,80005386 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053dc:	e7042783          	lw	a5,-400(s0)
    800053e0:	e8845703          	lhu	a4,-376(s0)
    800053e4:	c735                	beqz	a4,80005450 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053e6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053e8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800053ec:	6a05                	lui	s4,0x1
    800053ee:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800053f2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800053f6:	6d85                	lui	s11,0x1
    800053f8:	7d7d                	lui	s10,0xfffff
    800053fa:	ac3d                	j	80005638 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053fc:	00003517          	auipc	a0,0x3
    80005400:	32c50513          	addi	a0,a0,812 # 80008728 <syscalls+0x2b0>
    80005404:	ffffb097          	auipc	ra,0xffffb
    80005408:	13c080e7          	jalr	316(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000540c:	874a                	mv	a4,s2
    8000540e:	009c86bb          	addw	a3,s9,s1
    80005412:	4581                	li	a1,0
    80005414:	8556                	mv	a0,s5
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	c8e080e7          	jalr	-882(ra) # 800040a4 <readi>
    8000541e:	2501                	sext.w	a0,a0
    80005420:	1aa91963          	bne	s2,a0,800055d2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005424:	009d84bb          	addw	s1,s11,s1
    80005428:	013d09bb          	addw	s3,s10,s3
    8000542c:	1f74f663          	bgeu	s1,s7,80005618 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005430:	02049593          	slli	a1,s1,0x20
    80005434:	9181                	srli	a1,a1,0x20
    80005436:	95e2                	add	a1,a1,s8
    80005438:	855a                	mv	a0,s6
    8000543a:	ffffc097          	auipc	ra,0xffffc
    8000543e:	dba080e7          	jalr	-582(ra) # 800011f4 <walkaddr>
    80005442:	862a                	mv	a2,a0
    if(pa == 0)
    80005444:	dd45                	beqz	a0,800053fc <exec+0xfe>
      n = PGSIZE;
    80005446:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005448:	fd49f2e3          	bgeu	s3,s4,8000540c <exec+0x10e>
      n = sz - i;
    8000544c:	894e                	mv	s2,s3
    8000544e:	bf7d                	j	8000540c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005450:	4901                	li	s2,0
  iunlockput(ip);
    80005452:	8556                	mv	a0,s5
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	bfe080e7          	jalr	-1026(ra) # 80004052 <iunlockput>
  end_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	3de080e7          	jalr	990(ra) # 8000483a <end_op>
  p = myproc();
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	722080e7          	jalr	1826(ra) # 80001b86 <myproc>
    8000546c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000546e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005472:	6785                	lui	a5,0x1
    80005474:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005476:	97ca                	add	a5,a5,s2
    80005478:	777d                	lui	a4,0xfffff
    8000547a:	8ff9                	and	a5,a5,a4
    8000547c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005480:	4691                	li	a3,4
    80005482:	6609                	lui	a2,0x2
    80005484:	963e                	add	a2,a2,a5
    80005486:	85be                	mv	a1,a5
    80005488:	855a                	mv	a0,s6
    8000548a:	ffffc097          	auipc	ra,0xffffc
    8000548e:	11e080e7          	jalr	286(ra) # 800015a8 <uvmalloc>
    80005492:	8c2a                	mv	s8,a0
  ip = 0;
    80005494:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005496:	12050e63          	beqz	a0,800055d2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000549a:	75f9                	lui	a1,0xffffe
    8000549c:	95aa                	add	a1,a1,a0
    8000549e:	855a                	mv	a0,s6
    800054a0:	ffffc097          	auipc	ra,0xffffc
    800054a4:	33c080e7          	jalr	828(ra) # 800017dc <uvmclear>
  stackbase = sp - PGSIZE;
    800054a8:	7afd                	lui	s5,0xfffff
    800054aa:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800054ac:	df043783          	ld	a5,-528(s0)
    800054b0:	6388                	ld	a0,0(a5)
    800054b2:	c925                	beqz	a0,80005522 <exec+0x224>
    800054b4:	e9040993          	addi	s3,s0,-368
    800054b8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054bc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054be:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054c0:	ffffc097          	auipc	ra,0xffffc
    800054c4:	b26080e7          	jalr	-1242(ra) # 80000fe6 <strlen>
    800054c8:	0015079b          	addiw	a5,a0,1
    800054cc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054d0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800054d4:	13596663          	bltu	s2,s5,80005600 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054d8:	df043d83          	ld	s11,-528(s0)
    800054dc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800054e0:	8552                	mv	a0,s4
    800054e2:	ffffc097          	auipc	ra,0xffffc
    800054e6:	b04080e7          	jalr	-1276(ra) # 80000fe6 <strlen>
    800054ea:	0015069b          	addiw	a3,a0,1
    800054ee:	8652                	mv	a2,s4
    800054f0:	85ca                	mv	a1,s2
    800054f2:	855a                	mv	a0,s6
    800054f4:	ffffc097          	auipc	ra,0xffffc
    800054f8:	31a080e7          	jalr	794(ra) # 8000180e <copyout>
    800054fc:	10054663          	bltz	a0,80005608 <exec+0x30a>
    ustack[argc] = sp;
    80005500:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005504:	0485                	addi	s1,s1,1
    80005506:	008d8793          	addi	a5,s11,8
    8000550a:	def43823          	sd	a5,-528(s0)
    8000550e:	008db503          	ld	a0,8(s11)
    80005512:	c911                	beqz	a0,80005526 <exec+0x228>
    if(argc >= MAXARG)
    80005514:	09a1                	addi	s3,s3,8
    80005516:	fb3c95e3          	bne	s9,s3,800054c0 <exec+0x1c2>
  sz = sz1;
    8000551a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000551e:	4a81                	li	s5,0
    80005520:	a84d                	j	800055d2 <exec+0x2d4>
  sp = sz;
    80005522:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005524:	4481                	li	s1,0
  ustack[argc] = 0;
    80005526:	00349793          	slli	a5,s1,0x3
    8000552a:	f9078793          	addi	a5,a5,-112
    8000552e:	97a2                	add	a5,a5,s0
    80005530:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005534:	00148693          	addi	a3,s1,1
    80005538:	068e                	slli	a3,a3,0x3
    8000553a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000553e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005542:	01597663          	bgeu	s2,s5,8000554e <exec+0x250>
  sz = sz1;
    80005546:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000554a:	4a81                	li	s5,0
    8000554c:	a059                	j	800055d2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000554e:	e9040613          	addi	a2,s0,-368
    80005552:	85ca                	mv	a1,s2
    80005554:	855a                	mv	a0,s6
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	2b8080e7          	jalr	696(ra) # 8000180e <copyout>
    8000555e:	0a054963          	bltz	a0,80005610 <exec+0x312>
  p->trapframe->a1 = sp;
    80005562:	058bb783          	ld	a5,88(s7)
    80005566:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000556a:	de843783          	ld	a5,-536(s0)
    8000556e:	0007c703          	lbu	a4,0(a5)
    80005572:	cf11                	beqz	a4,8000558e <exec+0x290>
    80005574:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005576:	02f00693          	li	a3,47
    8000557a:	a039                	j	80005588 <exec+0x28a>
      last = s+1;
    8000557c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005580:	0785                	addi	a5,a5,1
    80005582:	fff7c703          	lbu	a4,-1(a5)
    80005586:	c701                	beqz	a4,8000558e <exec+0x290>
    if(*s == '/')
    80005588:	fed71ce3          	bne	a4,a3,80005580 <exec+0x282>
    8000558c:	bfc5                	j	8000557c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000558e:	4641                	li	a2,16
    80005590:	de843583          	ld	a1,-536(s0)
    80005594:	158b8513          	addi	a0,s7,344
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	a1c080e7          	jalr	-1508(ra) # 80000fb4 <safestrcpy>
  oldpagetable = p->pagetable;
    800055a0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800055a4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800055a8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055ac:	058bb783          	ld	a5,88(s7)
    800055b0:	e6843703          	ld	a4,-408(s0)
    800055b4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055b6:	058bb783          	ld	a5,88(s7)
    800055ba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055be:	85ea                	mv	a1,s10
    800055c0:	ffffc097          	auipc	ra,0xffffc
    800055c4:	726080e7          	jalr	1830(ra) # 80001ce6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055c8:	0004851b          	sext.w	a0,s1
    800055cc:	b3f9                	j	8000539a <exec+0x9c>
    800055ce:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800055d2:	df843583          	ld	a1,-520(s0)
    800055d6:	855a                	mv	a0,s6
    800055d8:	ffffc097          	auipc	ra,0xffffc
    800055dc:	70e080e7          	jalr	1806(ra) # 80001ce6 <proc_freepagetable>
  if(ip){
    800055e0:	da0a93e3          	bnez	s5,80005386 <exec+0x88>
  return -1;
    800055e4:	557d                	li	a0,-1
    800055e6:	bb55                	j	8000539a <exec+0x9c>
    800055e8:	df243c23          	sd	s2,-520(s0)
    800055ec:	b7dd                	j	800055d2 <exec+0x2d4>
    800055ee:	df243c23          	sd	s2,-520(s0)
    800055f2:	b7c5                	j	800055d2 <exec+0x2d4>
    800055f4:	df243c23          	sd	s2,-520(s0)
    800055f8:	bfe9                	j	800055d2 <exec+0x2d4>
    800055fa:	df243c23          	sd	s2,-520(s0)
    800055fe:	bfd1                	j	800055d2 <exec+0x2d4>
  sz = sz1;
    80005600:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005604:	4a81                	li	s5,0
    80005606:	b7f1                	j	800055d2 <exec+0x2d4>
  sz = sz1;
    80005608:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000560c:	4a81                	li	s5,0
    8000560e:	b7d1                	j	800055d2 <exec+0x2d4>
  sz = sz1;
    80005610:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005614:	4a81                	li	s5,0
    80005616:	bf75                	j	800055d2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005618:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000561c:	e0843783          	ld	a5,-504(s0)
    80005620:	0017869b          	addiw	a3,a5,1
    80005624:	e0d43423          	sd	a3,-504(s0)
    80005628:	e0043783          	ld	a5,-512(s0)
    8000562c:	0387879b          	addiw	a5,a5,56
    80005630:	e8845703          	lhu	a4,-376(s0)
    80005634:	e0e6dfe3          	bge	a3,a4,80005452 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005638:	2781                	sext.w	a5,a5
    8000563a:	e0f43023          	sd	a5,-512(s0)
    8000563e:	03800713          	li	a4,56
    80005642:	86be                	mv	a3,a5
    80005644:	e1840613          	addi	a2,s0,-488
    80005648:	4581                	li	a1,0
    8000564a:	8556                	mv	a0,s5
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	a58080e7          	jalr	-1448(ra) # 800040a4 <readi>
    80005654:	03800793          	li	a5,56
    80005658:	f6f51be3          	bne	a0,a5,800055ce <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000565c:	e1842783          	lw	a5,-488(s0)
    80005660:	4705                	li	a4,1
    80005662:	fae79de3          	bne	a5,a4,8000561c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005666:	e4043483          	ld	s1,-448(s0)
    8000566a:	e3843783          	ld	a5,-456(s0)
    8000566e:	f6f4ede3          	bltu	s1,a5,800055e8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005672:	e2843783          	ld	a5,-472(s0)
    80005676:	94be                	add	s1,s1,a5
    80005678:	f6f4ebe3          	bltu	s1,a5,800055ee <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000567c:	de043703          	ld	a4,-544(s0)
    80005680:	8ff9                	and	a5,a5,a4
    80005682:	fbad                	bnez	a5,800055f4 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005684:	e1c42503          	lw	a0,-484(s0)
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	c5c080e7          	jalr	-932(ra) # 800052e4 <flags2perm>
    80005690:	86aa                	mv	a3,a0
    80005692:	8626                	mv	a2,s1
    80005694:	85ca                	mv	a1,s2
    80005696:	855a                	mv	a0,s6
    80005698:	ffffc097          	auipc	ra,0xffffc
    8000569c:	f10080e7          	jalr	-240(ra) # 800015a8 <uvmalloc>
    800056a0:	dea43c23          	sd	a0,-520(s0)
    800056a4:	d939                	beqz	a0,800055fa <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056a6:	e2843c03          	ld	s8,-472(s0)
    800056aa:	e2042c83          	lw	s9,-480(s0)
    800056ae:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056b2:	f60b83e3          	beqz	s7,80005618 <exec+0x31a>
    800056b6:	89de                	mv	s3,s7
    800056b8:	4481                	li	s1,0
    800056ba:	bb9d                	j	80005430 <exec+0x132>

00000000800056bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056bc:	7179                	addi	sp,sp,-48
    800056be:	f406                	sd	ra,40(sp)
    800056c0:	f022                	sd	s0,32(sp)
    800056c2:	ec26                	sd	s1,24(sp)
    800056c4:	e84a                	sd	s2,16(sp)
    800056c6:	1800                	addi	s0,sp,48
    800056c8:	892e                	mv	s2,a1
    800056ca:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800056cc:	fdc40593          	addi	a1,s0,-36
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	a2a080e7          	jalr	-1494(ra) # 800030fa <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056d8:	fdc42703          	lw	a4,-36(s0)
    800056dc:	47bd                	li	a5,15
    800056de:	02e7eb63          	bltu	a5,a4,80005714 <argfd+0x58>
    800056e2:	ffffc097          	auipc	ra,0xffffc
    800056e6:	4a4080e7          	jalr	1188(ra) # 80001b86 <myproc>
    800056ea:	fdc42703          	lw	a4,-36(s0)
    800056ee:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbc842>
    800056f2:	078e                	slli	a5,a5,0x3
    800056f4:	953e                	add	a0,a0,a5
    800056f6:	611c                	ld	a5,0(a0)
    800056f8:	c385                	beqz	a5,80005718 <argfd+0x5c>
    return -1;
  if(pfd)
    800056fa:	00090463          	beqz	s2,80005702 <argfd+0x46>
    *pfd = fd;
    800056fe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005702:	4501                	li	a0,0
  if(pf)
    80005704:	c091                	beqz	s1,80005708 <argfd+0x4c>
    *pf = f;
    80005706:	e09c                	sd	a5,0(s1)
}
    80005708:	70a2                	ld	ra,40(sp)
    8000570a:	7402                	ld	s0,32(sp)
    8000570c:	64e2                	ld	s1,24(sp)
    8000570e:	6942                	ld	s2,16(sp)
    80005710:	6145                	addi	sp,sp,48
    80005712:	8082                	ret
    return -1;
    80005714:	557d                	li	a0,-1
    80005716:	bfcd                	j	80005708 <argfd+0x4c>
    80005718:	557d                	li	a0,-1
    8000571a:	b7fd                	j	80005708 <argfd+0x4c>

000000008000571c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000571c:	1101                	addi	sp,sp,-32
    8000571e:	ec06                	sd	ra,24(sp)
    80005720:	e822                	sd	s0,16(sp)
    80005722:	e426                	sd	s1,8(sp)
    80005724:	1000                	addi	s0,sp,32
    80005726:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005728:	ffffc097          	auipc	ra,0xffffc
    8000572c:	45e080e7          	jalr	1118(ra) # 80001b86 <myproc>
    80005730:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005732:	0d050793          	addi	a5,a0,208
    80005736:	4501                	li	a0,0
    80005738:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000573a:	6398                	ld	a4,0(a5)
    8000573c:	cb19                	beqz	a4,80005752 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000573e:	2505                	addiw	a0,a0,1
    80005740:	07a1                	addi	a5,a5,8
    80005742:	fed51ce3          	bne	a0,a3,8000573a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005746:	557d                	li	a0,-1
}
    80005748:	60e2                	ld	ra,24(sp)
    8000574a:	6442                	ld	s0,16(sp)
    8000574c:	64a2                	ld	s1,8(sp)
    8000574e:	6105                	addi	sp,sp,32
    80005750:	8082                	ret
      p->ofile[fd] = f;
    80005752:	01a50793          	addi	a5,a0,26
    80005756:	078e                	slli	a5,a5,0x3
    80005758:	963e                	add	a2,a2,a5
    8000575a:	e204                	sd	s1,0(a2)
      return fd;
    8000575c:	b7f5                	j	80005748 <fdalloc+0x2c>

000000008000575e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000575e:	715d                	addi	sp,sp,-80
    80005760:	e486                	sd	ra,72(sp)
    80005762:	e0a2                	sd	s0,64(sp)
    80005764:	fc26                	sd	s1,56(sp)
    80005766:	f84a                	sd	s2,48(sp)
    80005768:	f44e                	sd	s3,40(sp)
    8000576a:	f052                	sd	s4,32(sp)
    8000576c:	ec56                	sd	s5,24(sp)
    8000576e:	e85a                	sd	s6,16(sp)
    80005770:	0880                	addi	s0,sp,80
    80005772:	8b2e                	mv	s6,a1
    80005774:	89b2                	mv	s3,a2
    80005776:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005778:	fb040593          	addi	a1,s0,-80
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	e3e080e7          	jalr	-450(ra) # 800045ba <nameiparent>
    80005784:	84aa                	mv	s1,a0
    80005786:	14050f63          	beqz	a0,800058e4 <create+0x186>
    return 0;

  ilock(dp);
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	666080e7          	jalr	1638(ra) # 80003df0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005792:	4601                	li	a2,0
    80005794:	fb040593          	addi	a1,s0,-80
    80005798:	8526                	mv	a0,s1
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	b3a080e7          	jalr	-1222(ra) # 800042d4 <dirlookup>
    800057a2:	8aaa                	mv	s5,a0
    800057a4:	c931                	beqz	a0,800057f8 <create+0x9a>
    iunlockput(dp);
    800057a6:	8526                	mv	a0,s1
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	8aa080e7          	jalr	-1878(ra) # 80004052 <iunlockput>
    ilock(ip);
    800057b0:	8556                	mv	a0,s5
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	63e080e7          	jalr	1598(ra) # 80003df0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057ba:	000b059b          	sext.w	a1,s6
    800057be:	4789                	li	a5,2
    800057c0:	02f59563          	bne	a1,a5,800057ea <create+0x8c>
    800057c4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbc86c>
    800057c8:	37f9                	addiw	a5,a5,-2
    800057ca:	17c2                	slli	a5,a5,0x30
    800057cc:	93c1                	srli	a5,a5,0x30
    800057ce:	4705                	li	a4,1
    800057d0:	00f76d63          	bltu	a4,a5,800057ea <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800057d4:	8556                	mv	a0,s5
    800057d6:	60a6                	ld	ra,72(sp)
    800057d8:	6406                	ld	s0,64(sp)
    800057da:	74e2                	ld	s1,56(sp)
    800057dc:	7942                	ld	s2,48(sp)
    800057de:	79a2                	ld	s3,40(sp)
    800057e0:	7a02                	ld	s4,32(sp)
    800057e2:	6ae2                	ld	s5,24(sp)
    800057e4:	6b42                	ld	s6,16(sp)
    800057e6:	6161                	addi	sp,sp,80
    800057e8:	8082                	ret
    iunlockput(ip);
    800057ea:	8556                	mv	a0,s5
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	866080e7          	jalr	-1946(ra) # 80004052 <iunlockput>
    return 0;
    800057f4:	4a81                	li	s5,0
    800057f6:	bff9                	j	800057d4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800057f8:	85da                	mv	a1,s6
    800057fa:	4088                	lw	a0,0(s1)
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	456080e7          	jalr	1110(ra) # 80003c52 <ialloc>
    80005804:	8a2a                	mv	s4,a0
    80005806:	c539                	beqz	a0,80005854 <create+0xf6>
  ilock(ip);
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	5e8080e7          	jalr	1512(ra) # 80003df0 <ilock>
  ip->major = major;
    80005810:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005814:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005818:	4905                	li	s2,1
    8000581a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000581e:	8552                	mv	a0,s4
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	504080e7          	jalr	1284(ra) # 80003d24 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005828:	000b059b          	sext.w	a1,s6
    8000582c:	03258b63          	beq	a1,s2,80005862 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005830:	004a2603          	lw	a2,4(s4)
    80005834:	fb040593          	addi	a1,s0,-80
    80005838:	8526                	mv	a0,s1
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	cb0080e7          	jalr	-848(ra) # 800044ea <dirlink>
    80005842:	06054f63          	bltz	a0,800058c0 <create+0x162>
  iunlockput(dp);
    80005846:	8526                	mv	a0,s1
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	80a080e7          	jalr	-2038(ra) # 80004052 <iunlockput>
  return ip;
    80005850:	8ad2                	mv	s5,s4
    80005852:	b749                	j	800057d4 <create+0x76>
    iunlockput(dp);
    80005854:	8526                	mv	a0,s1
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	7fc080e7          	jalr	2044(ra) # 80004052 <iunlockput>
    return 0;
    8000585e:	8ad2                	mv	s5,s4
    80005860:	bf95                	j	800057d4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005862:	004a2603          	lw	a2,4(s4)
    80005866:	00003597          	auipc	a1,0x3
    8000586a:	ee258593          	addi	a1,a1,-286 # 80008748 <syscalls+0x2d0>
    8000586e:	8552                	mv	a0,s4
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	c7a080e7          	jalr	-902(ra) # 800044ea <dirlink>
    80005878:	04054463          	bltz	a0,800058c0 <create+0x162>
    8000587c:	40d0                	lw	a2,4(s1)
    8000587e:	00003597          	auipc	a1,0x3
    80005882:	ed258593          	addi	a1,a1,-302 # 80008750 <syscalls+0x2d8>
    80005886:	8552                	mv	a0,s4
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	c62080e7          	jalr	-926(ra) # 800044ea <dirlink>
    80005890:	02054863          	bltz	a0,800058c0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005894:	004a2603          	lw	a2,4(s4)
    80005898:	fb040593          	addi	a1,s0,-80
    8000589c:	8526                	mv	a0,s1
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	c4c080e7          	jalr	-948(ra) # 800044ea <dirlink>
    800058a6:	00054d63          	bltz	a0,800058c0 <create+0x162>
    dp->nlink++;  // for ".."
    800058aa:	04a4d783          	lhu	a5,74(s1)
    800058ae:	2785                	addiw	a5,a5,1
    800058b0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	46e080e7          	jalr	1134(ra) # 80003d24 <iupdate>
    800058be:	b761                	j	80005846 <create+0xe8>
  ip->nlink = 0;
    800058c0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800058c4:	8552                	mv	a0,s4
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	45e080e7          	jalr	1118(ra) # 80003d24 <iupdate>
  iunlockput(ip);
    800058ce:	8552                	mv	a0,s4
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	782080e7          	jalr	1922(ra) # 80004052 <iunlockput>
  iunlockput(dp);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	778080e7          	jalr	1912(ra) # 80004052 <iunlockput>
  return 0;
    800058e2:	bdcd                	j	800057d4 <create+0x76>
    return 0;
    800058e4:	8aaa                	mv	s5,a0
    800058e6:	b5fd                	j	800057d4 <create+0x76>

00000000800058e8 <sys_dup>:
{
    800058e8:	7179                	addi	sp,sp,-48
    800058ea:	f406                	sd	ra,40(sp)
    800058ec:	f022                	sd	s0,32(sp)
    800058ee:	ec26                	sd	s1,24(sp)
    800058f0:	e84a                	sd	s2,16(sp)
    800058f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058f4:	fd840613          	addi	a2,s0,-40
    800058f8:	4581                	li	a1,0
    800058fa:	4501                	li	a0,0
    800058fc:	00000097          	auipc	ra,0x0
    80005900:	dc0080e7          	jalr	-576(ra) # 800056bc <argfd>
    return -1;
    80005904:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005906:	02054363          	bltz	a0,8000592c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000590a:	fd843903          	ld	s2,-40(s0)
    8000590e:	854a                	mv	a0,s2
    80005910:	00000097          	auipc	ra,0x0
    80005914:	e0c080e7          	jalr	-500(ra) # 8000571c <fdalloc>
    80005918:	84aa                	mv	s1,a0
    return -1;
    8000591a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000591c:	00054863          	bltz	a0,8000592c <sys_dup+0x44>
  filedup(f);
    80005920:	854a                	mv	a0,s2
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	310080e7          	jalr	784(ra) # 80004c32 <filedup>
  return fd;
    8000592a:	87a6                	mv	a5,s1
}
    8000592c:	853e                	mv	a0,a5
    8000592e:	70a2                	ld	ra,40(sp)
    80005930:	7402                	ld	s0,32(sp)
    80005932:	64e2                	ld	s1,24(sp)
    80005934:	6942                	ld	s2,16(sp)
    80005936:	6145                	addi	sp,sp,48
    80005938:	8082                	ret

000000008000593a <sys_getreadcount>:
{
    8000593a:	1141                	addi	sp,sp,-16
    8000593c:	e422                	sd	s0,8(sp)
    8000593e:	0800                	addi	s0,sp,16
}
    80005940:	00003517          	auipc	a0,0x3
    80005944:	00452503          	lw	a0,4(a0) # 80008944 <readCount>
    80005948:	6422                	ld	s0,8(sp)
    8000594a:	0141                	addi	sp,sp,16
    8000594c:	8082                	ret

000000008000594e <sys_read>:
{
    8000594e:	7179                	addi	sp,sp,-48
    80005950:	f406                	sd	ra,40(sp)
    80005952:	f022                	sd	s0,32(sp)
    80005954:	1800                	addi	s0,sp,48
  readCount++;
    80005956:	00003717          	auipc	a4,0x3
    8000595a:	fee70713          	addi	a4,a4,-18 # 80008944 <readCount>
    8000595e:	431c                	lw	a5,0(a4)
    80005960:	2785                	addiw	a5,a5,1
    80005962:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005964:	fd840593          	addi	a1,s0,-40
    80005968:	4505                	li	a0,1
    8000596a:	ffffd097          	auipc	ra,0xffffd
    8000596e:	7b0080e7          	jalr	1968(ra) # 8000311a <argaddr>
  argint(2, &n);
    80005972:	fe440593          	addi	a1,s0,-28
    80005976:	4509                	li	a0,2
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	782080e7          	jalr	1922(ra) # 800030fa <argint>
  if(argfd(0, 0, &f) < 0)
    80005980:	fe840613          	addi	a2,s0,-24
    80005984:	4581                	li	a1,0
    80005986:	4501                	li	a0,0
    80005988:	00000097          	auipc	ra,0x0
    8000598c:	d34080e7          	jalr	-716(ra) # 800056bc <argfd>
    80005990:	87aa                	mv	a5,a0
    return -1;
    80005992:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005994:	0007cc63          	bltz	a5,800059ac <sys_read+0x5e>
  return fileread(f, p, n);
    80005998:	fe442603          	lw	a2,-28(s0)
    8000599c:	fd843583          	ld	a1,-40(s0)
    800059a0:	fe843503          	ld	a0,-24(s0)
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	41a080e7          	jalr	1050(ra) # 80004dbe <fileread>
}
    800059ac:	70a2                	ld	ra,40(sp)
    800059ae:	7402                	ld	s0,32(sp)
    800059b0:	6145                	addi	sp,sp,48
    800059b2:	8082                	ret

00000000800059b4 <sys_write>:
{
    800059b4:	7179                	addi	sp,sp,-48
    800059b6:	f406                	sd	ra,40(sp)
    800059b8:	f022                	sd	s0,32(sp)
    800059ba:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800059bc:	fd840593          	addi	a1,s0,-40
    800059c0:	4505                	li	a0,1
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	758080e7          	jalr	1880(ra) # 8000311a <argaddr>
  argint(2, &n);
    800059ca:	fe440593          	addi	a1,s0,-28
    800059ce:	4509                	li	a0,2
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	72a080e7          	jalr	1834(ra) # 800030fa <argint>
  if(argfd(0, 0, &f) < 0)
    800059d8:	fe840613          	addi	a2,s0,-24
    800059dc:	4581                	li	a1,0
    800059de:	4501                	li	a0,0
    800059e0:	00000097          	auipc	ra,0x0
    800059e4:	cdc080e7          	jalr	-804(ra) # 800056bc <argfd>
    800059e8:	87aa                	mv	a5,a0
    return -1;
    800059ea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059ec:	0007cc63          	bltz	a5,80005a04 <sys_write+0x50>
  return filewrite(f, p, n);
    800059f0:	fe442603          	lw	a2,-28(s0)
    800059f4:	fd843583          	ld	a1,-40(s0)
    800059f8:	fe843503          	ld	a0,-24(s0)
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	484080e7          	jalr	1156(ra) # 80004e80 <filewrite>
}
    80005a04:	70a2                	ld	ra,40(sp)
    80005a06:	7402                	ld	s0,32(sp)
    80005a08:	6145                	addi	sp,sp,48
    80005a0a:	8082                	ret

0000000080005a0c <sys_close>:
{
    80005a0c:	1101                	addi	sp,sp,-32
    80005a0e:	ec06                	sd	ra,24(sp)
    80005a10:	e822                	sd	s0,16(sp)
    80005a12:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a14:	fe040613          	addi	a2,s0,-32
    80005a18:	fec40593          	addi	a1,s0,-20
    80005a1c:	4501                	li	a0,0
    80005a1e:	00000097          	auipc	ra,0x0
    80005a22:	c9e080e7          	jalr	-866(ra) # 800056bc <argfd>
    return -1;
    80005a26:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a28:	02054463          	bltz	a0,80005a50 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a2c:	ffffc097          	auipc	ra,0xffffc
    80005a30:	15a080e7          	jalr	346(ra) # 80001b86 <myproc>
    80005a34:	fec42783          	lw	a5,-20(s0)
    80005a38:	07e9                	addi	a5,a5,26
    80005a3a:	078e                	slli	a5,a5,0x3
    80005a3c:	953e                	add	a0,a0,a5
    80005a3e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005a42:	fe043503          	ld	a0,-32(s0)
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	23e080e7          	jalr	574(ra) # 80004c84 <fileclose>
  return 0;
    80005a4e:	4781                	li	a5,0
}
    80005a50:	853e                	mv	a0,a5
    80005a52:	60e2                	ld	ra,24(sp)
    80005a54:	6442                	ld	s0,16(sp)
    80005a56:	6105                	addi	sp,sp,32
    80005a58:	8082                	ret

0000000080005a5a <sys_fstat>:
{
    80005a5a:	1101                	addi	sp,sp,-32
    80005a5c:	ec06                	sd	ra,24(sp)
    80005a5e:	e822                	sd	s0,16(sp)
    80005a60:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a62:	fe040593          	addi	a1,s0,-32
    80005a66:	4505                	li	a0,1
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	6b2080e7          	jalr	1714(ra) # 8000311a <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a70:	fe840613          	addi	a2,s0,-24
    80005a74:	4581                	li	a1,0
    80005a76:	4501                	li	a0,0
    80005a78:	00000097          	auipc	ra,0x0
    80005a7c:	c44080e7          	jalr	-956(ra) # 800056bc <argfd>
    80005a80:	87aa                	mv	a5,a0
    return -1;
    80005a82:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a84:	0007ca63          	bltz	a5,80005a98 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a88:	fe043583          	ld	a1,-32(s0)
    80005a8c:	fe843503          	ld	a0,-24(s0)
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	2bc080e7          	jalr	700(ra) # 80004d4c <filestat>
}
    80005a98:	60e2                	ld	ra,24(sp)
    80005a9a:	6442                	ld	s0,16(sp)
    80005a9c:	6105                	addi	sp,sp,32
    80005a9e:	8082                	ret

0000000080005aa0 <sys_link>:
{
    80005aa0:	7169                	addi	sp,sp,-304
    80005aa2:	f606                	sd	ra,296(sp)
    80005aa4:	f222                	sd	s0,288(sp)
    80005aa6:	ee26                	sd	s1,280(sp)
    80005aa8:	ea4a                	sd	s2,272(sp)
    80005aaa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aac:	08000613          	li	a2,128
    80005ab0:	ed040593          	addi	a1,s0,-304
    80005ab4:	4501                	li	a0,0
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	684080e7          	jalr	1668(ra) # 8000313a <argstr>
    return -1;
    80005abe:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ac0:	10054e63          	bltz	a0,80005bdc <sys_link+0x13c>
    80005ac4:	08000613          	li	a2,128
    80005ac8:	f5040593          	addi	a1,s0,-176
    80005acc:	4505                	li	a0,1
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	66c080e7          	jalr	1644(ra) # 8000313a <argstr>
    return -1;
    80005ad6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ad8:	10054263          	bltz	a0,80005bdc <sys_link+0x13c>
  begin_op();
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	ce0080e7          	jalr	-800(ra) # 800047bc <begin_op>
  if((ip = namei(old)) == 0){
    80005ae4:	ed040513          	addi	a0,s0,-304
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	ab4080e7          	jalr	-1356(ra) # 8000459c <namei>
    80005af0:	84aa                	mv	s1,a0
    80005af2:	c551                	beqz	a0,80005b7e <sys_link+0xde>
  ilock(ip);
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	2fc080e7          	jalr	764(ra) # 80003df0 <ilock>
  if(ip->type == T_DIR){
    80005afc:	04449703          	lh	a4,68(s1)
    80005b00:	4785                	li	a5,1
    80005b02:	08f70463          	beq	a4,a5,80005b8a <sys_link+0xea>
  ip->nlink++;
    80005b06:	04a4d783          	lhu	a5,74(s1)
    80005b0a:	2785                	addiw	a5,a5,1
    80005b0c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	212080e7          	jalr	530(ra) # 80003d24 <iupdate>
  iunlock(ip);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	396080e7          	jalr	918(ra) # 80003eb2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b24:	fd040593          	addi	a1,s0,-48
    80005b28:	f5040513          	addi	a0,s0,-176
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	a8e080e7          	jalr	-1394(ra) # 800045ba <nameiparent>
    80005b34:	892a                	mv	s2,a0
    80005b36:	c935                	beqz	a0,80005baa <sys_link+0x10a>
  ilock(dp);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	2b8080e7          	jalr	696(ra) # 80003df0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b40:	00092703          	lw	a4,0(s2)
    80005b44:	409c                	lw	a5,0(s1)
    80005b46:	04f71d63          	bne	a4,a5,80005ba0 <sys_link+0x100>
    80005b4a:	40d0                	lw	a2,4(s1)
    80005b4c:	fd040593          	addi	a1,s0,-48
    80005b50:	854a                	mv	a0,s2
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	998080e7          	jalr	-1640(ra) # 800044ea <dirlink>
    80005b5a:	04054363          	bltz	a0,80005ba0 <sys_link+0x100>
  iunlockput(dp);
    80005b5e:	854a                	mv	a0,s2
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	4f2080e7          	jalr	1266(ra) # 80004052 <iunlockput>
  iput(ip);
    80005b68:	8526                	mv	a0,s1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	440080e7          	jalr	1088(ra) # 80003faa <iput>
  end_op();
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	cc8080e7          	jalr	-824(ra) # 8000483a <end_op>
  return 0;
    80005b7a:	4781                	li	a5,0
    80005b7c:	a085                	j	80005bdc <sys_link+0x13c>
    end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	cbc080e7          	jalr	-836(ra) # 8000483a <end_op>
    return -1;
    80005b86:	57fd                	li	a5,-1
    80005b88:	a891                	j	80005bdc <sys_link+0x13c>
    iunlockput(ip);
    80005b8a:	8526                	mv	a0,s1
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	4c6080e7          	jalr	1222(ra) # 80004052 <iunlockput>
    end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	ca6080e7          	jalr	-858(ra) # 8000483a <end_op>
    return -1;
    80005b9c:	57fd                	li	a5,-1
    80005b9e:	a83d                	j	80005bdc <sys_link+0x13c>
    iunlockput(dp);
    80005ba0:	854a                	mv	a0,s2
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	4b0080e7          	jalr	1200(ra) # 80004052 <iunlockput>
  ilock(ip);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	244080e7          	jalr	580(ra) # 80003df0 <ilock>
  ip->nlink--;
    80005bb4:	04a4d783          	lhu	a5,74(s1)
    80005bb8:	37fd                	addiw	a5,a5,-1
    80005bba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bbe:	8526                	mv	a0,s1
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	164080e7          	jalr	356(ra) # 80003d24 <iupdate>
  iunlockput(ip);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	488080e7          	jalr	1160(ra) # 80004052 <iunlockput>
  end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	c68080e7          	jalr	-920(ra) # 8000483a <end_op>
  return -1;
    80005bda:	57fd                	li	a5,-1
}
    80005bdc:	853e                	mv	a0,a5
    80005bde:	70b2                	ld	ra,296(sp)
    80005be0:	7412                	ld	s0,288(sp)
    80005be2:	64f2                	ld	s1,280(sp)
    80005be4:	6952                	ld	s2,272(sp)
    80005be6:	6155                	addi	sp,sp,304
    80005be8:	8082                	ret

0000000080005bea <sys_unlink>:
{
    80005bea:	7151                	addi	sp,sp,-240
    80005bec:	f586                	sd	ra,232(sp)
    80005bee:	f1a2                	sd	s0,224(sp)
    80005bf0:	eda6                	sd	s1,216(sp)
    80005bf2:	e9ca                	sd	s2,208(sp)
    80005bf4:	e5ce                	sd	s3,200(sp)
    80005bf6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bf8:	08000613          	li	a2,128
    80005bfc:	f3040593          	addi	a1,s0,-208
    80005c00:	4501                	li	a0,0
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	538080e7          	jalr	1336(ra) # 8000313a <argstr>
    80005c0a:	18054163          	bltz	a0,80005d8c <sys_unlink+0x1a2>
  begin_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	bae080e7          	jalr	-1106(ra) # 800047bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c16:	fb040593          	addi	a1,s0,-80
    80005c1a:	f3040513          	addi	a0,s0,-208
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	99c080e7          	jalr	-1636(ra) # 800045ba <nameiparent>
    80005c26:	84aa                	mv	s1,a0
    80005c28:	c979                	beqz	a0,80005cfe <sys_unlink+0x114>
  ilock(dp);
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	1c6080e7          	jalr	454(ra) # 80003df0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c32:	00003597          	auipc	a1,0x3
    80005c36:	b1658593          	addi	a1,a1,-1258 # 80008748 <syscalls+0x2d0>
    80005c3a:	fb040513          	addi	a0,s0,-80
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	67c080e7          	jalr	1660(ra) # 800042ba <namecmp>
    80005c46:	14050a63          	beqz	a0,80005d9a <sys_unlink+0x1b0>
    80005c4a:	00003597          	auipc	a1,0x3
    80005c4e:	b0658593          	addi	a1,a1,-1274 # 80008750 <syscalls+0x2d8>
    80005c52:	fb040513          	addi	a0,s0,-80
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	664080e7          	jalr	1636(ra) # 800042ba <namecmp>
    80005c5e:	12050e63          	beqz	a0,80005d9a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c62:	f2c40613          	addi	a2,s0,-212
    80005c66:	fb040593          	addi	a1,s0,-80
    80005c6a:	8526                	mv	a0,s1
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	668080e7          	jalr	1640(ra) # 800042d4 <dirlookup>
    80005c74:	892a                	mv	s2,a0
    80005c76:	12050263          	beqz	a0,80005d9a <sys_unlink+0x1b0>
  ilock(ip);
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	176080e7          	jalr	374(ra) # 80003df0 <ilock>
  if(ip->nlink < 1)
    80005c82:	04a91783          	lh	a5,74(s2)
    80005c86:	08f05263          	blez	a5,80005d0a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c8a:	04491703          	lh	a4,68(s2)
    80005c8e:	4785                	li	a5,1
    80005c90:	08f70563          	beq	a4,a5,80005d1a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c94:	4641                	li	a2,16
    80005c96:	4581                	li	a1,0
    80005c98:	fc040513          	addi	a0,s0,-64
    80005c9c:	ffffb097          	auipc	ra,0xffffb
    80005ca0:	1ce080e7          	jalr	462(ra) # 80000e6a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ca4:	4741                	li	a4,16
    80005ca6:	f2c42683          	lw	a3,-212(s0)
    80005caa:	fc040613          	addi	a2,s0,-64
    80005cae:	4581                	li	a1,0
    80005cb0:	8526                	mv	a0,s1
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	4ea080e7          	jalr	1258(ra) # 8000419c <writei>
    80005cba:	47c1                	li	a5,16
    80005cbc:	0af51563          	bne	a0,a5,80005d66 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cc0:	04491703          	lh	a4,68(s2)
    80005cc4:	4785                	li	a5,1
    80005cc6:	0af70863          	beq	a4,a5,80005d76 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cca:	8526                	mv	a0,s1
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	386080e7          	jalr	902(ra) # 80004052 <iunlockput>
  ip->nlink--;
    80005cd4:	04a95783          	lhu	a5,74(s2)
    80005cd8:	37fd                	addiw	a5,a5,-1
    80005cda:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cde:	854a                	mv	a0,s2
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	044080e7          	jalr	68(ra) # 80003d24 <iupdate>
  iunlockput(ip);
    80005ce8:	854a                	mv	a0,s2
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	368080e7          	jalr	872(ra) # 80004052 <iunlockput>
  end_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	b48080e7          	jalr	-1208(ra) # 8000483a <end_op>
  return 0;
    80005cfa:	4501                	li	a0,0
    80005cfc:	a84d                	j	80005dae <sys_unlink+0x1c4>
    end_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	b3c080e7          	jalr	-1220(ra) # 8000483a <end_op>
    return -1;
    80005d06:	557d                	li	a0,-1
    80005d08:	a05d                	j	80005dae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d0a:	00003517          	auipc	a0,0x3
    80005d0e:	a4e50513          	addi	a0,a0,-1458 # 80008758 <syscalls+0x2e0>
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	82e080e7          	jalr	-2002(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d1a:	04c92703          	lw	a4,76(s2)
    80005d1e:	02000793          	li	a5,32
    80005d22:	f6e7f9e3          	bgeu	a5,a4,80005c94 <sys_unlink+0xaa>
    80005d26:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d2a:	4741                	li	a4,16
    80005d2c:	86ce                	mv	a3,s3
    80005d2e:	f1840613          	addi	a2,s0,-232
    80005d32:	4581                	li	a1,0
    80005d34:	854a                	mv	a0,s2
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	36e080e7          	jalr	878(ra) # 800040a4 <readi>
    80005d3e:	47c1                	li	a5,16
    80005d40:	00f51b63          	bne	a0,a5,80005d56 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d44:	f1845783          	lhu	a5,-232(s0)
    80005d48:	e7a1                	bnez	a5,80005d90 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d4a:	29c1                	addiw	s3,s3,16
    80005d4c:	04c92783          	lw	a5,76(s2)
    80005d50:	fcf9ede3          	bltu	s3,a5,80005d2a <sys_unlink+0x140>
    80005d54:	b781                	j	80005c94 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d56:	00003517          	auipc	a0,0x3
    80005d5a:	a1a50513          	addi	a0,a0,-1510 # 80008770 <syscalls+0x2f8>
    80005d5e:	ffffa097          	auipc	ra,0xffffa
    80005d62:	7e2080e7          	jalr	2018(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005d66:	00003517          	auipc	a0,0x3
    80005d6a:	a2250513          	addi	a0,a0,-1502 # 80008788 <syscalls+0x310>
    80005d6e:	ffffa097          	auipc	ra,0xffffa
    80005d72:	7d2080e7          	jalr	2002(ra) # 80000540 <panic>
    dp->nlink--;
    80005d76:	04a4d783          	lhu	a5,74(s1)
    80005d7a:	37fd                	addiw	a5,a5,-1
    80005d7c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	fa2080e7          	jalr	-94(ra) # 80003d24 <iupdate>
    80005d8a:	b781                	j	80005cca <sys_unlink+0xe0>
    return -1;
    80005d8c:	557d                	li	a0,-1
    80005d8e:	a005                	j	80005dae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d90:	854a                	mv	a0,s2
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	2c0080e7          	jalr	704(ra) # 80004052 <iunlockput>
  iunlockput(dp);
    80005d9a:	8526                	mv	a0,s1
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	2b6080e7          	jalr	694(ra) # 80004052 <iunlockput>
  end_op();
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	a96080e7          	jalr	-1386(ra) # 8000483a <end_op>
  return -1;
    80005dac:	557d                	li	a0,-1
}
    80005dae:	70ae                	ld	ra,232(sp)
    80005db0:	740e                	ld	s0,224(sp)
    80005db2:	64ee                	ld	s1,216(sp)
    80005db4:	694e                	ld	s2,208(sp)
    80005db6:	69ae                	ld	s3,200(sp)
    80005db8:	616d                	addi	sp,sp,240
    80005dba:	8082                	ret

0000000080005dbc <sys_open>:

uint64
sys_open(void)
{
    80005dbc:	7131                	addi	sp,sp,-192
    80005dbe:	fd06                	sd	ra,184(sp)
    80005dc0:	f922                	sd	s0,176(sp)
    80005dc2:	f526                	sd	s1,168(sp)
    80005dc4:	f14a                	sd	s2,160(sp)
    80005dc6:	ed4e                	sd	s3,152(sp)
    80005dc8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005dca:	f4c40593          	addi	a1,s0,-180
    80005dce:	4505                	li	a0,1
    80005dd0:	ffffd097          	auipc	ra,0xffffd
    80005dd4:	32a080e7          	jalr	810(ra) # 800030fa <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005dd8:	08000613          	li	a2,128
    80005ddc:	f5040593          	addi	a1,s0,-176
    80005de0:	4501                	li	a0,0
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	358080e7          	jalr	856(ra) # 8000313a <argstr>
    80005dea:	87aa                	mv	a5,a0
    return -1;
    80005dec:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005dee:	0a07c963          	bltz	a5,80005ea0 <sys_open+0xe4>

  begin_op();
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	9ca080e7          	jalr	-1590(ra) # 800047bc <begin_op>

  if(omode & O_CREATE){
    80005dfa:	f4c42783          	lw	a5,-180(s0)
    80005dfe:	2007f793          	andi	a5,a5,512
    80005e02:	cfc5                	beqz	a5,80005eba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e04:	4681                	li	a3,0
    80005e06:	4601                	li	a2,0
    80005e08:	4589                	li	a1,2
    80005e0a:	f5040513          	addi	a0,s0,-176
    80005e0e:	00000097          	auipc	ra,0x0
    80005e12:	950080e7          	jalr	-1712(ra) # 8000575e <create>
    80005e16:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e18:	c959                	beqz	a0,80005eae <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e1a:	04449703          	lh	a4,68(s1)
    80005e1e:	478d                	li	a5,3
    80005e20:	00f71763          	bne	a4,a5,80005e2e <sys_open+0x72>
    80005e24:	0464d703          	lhu	a4,70(s1)
    80005e28:	47a5                	li	a5,9
    80005e2a:	0ce7ed63          	bltu	a5,a4,80005f04 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	d9a080e7          	jalr	-614(ra) # 80004bc8 <filealloc>
    80005e36:	89aa                	mv	s3,a0
    80005e38:	10050363          	beqz	a0,80005f3e <sys_open+0x182>
    80005e3c:	00000097          	auipc	ra,0x0
    80005e40:	8e0080e7          	jalr	-1824(ra) # 8000571c <fdalloc>
    80005e44:	892a                	mv	s2,a0
    80005e46:	0e054763          	bltz	a0,80005f34 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e4a:	04449703          	lh	a4,68(s1)
    80005e4e:	478d                	li	a5,3
    80005e50:	0cf70563          	beq	a4,a5,80005f1a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e54:	4789                	li	a5,2
    80005e56:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e5a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e5e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e62:	f4c42783          	lw	a5,-180(s0)
    80005e66:	0017c713          	xori	a4,a5,1
    80005e6a:	8b05                	andi	a4,a4,1
    80005e6c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e70:	0037f713          	andi	a4,a5,3
    80005e74:	00e03733          	snez	a4,a4
    80005e78:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e7c:	4007f793          	andi	a5,a5,1024
    80005e80:	c791                	beqz	a5,80005e8c <sys_open+0xd0>
    80005e82:	04449703          	lh	a4,68(s1)
    80005e86:	4789                	li	a5,2
    80005e88:	0af70063          	beq	a4,a5,80005f28 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	024080e7          	jalr	36(ra) # 80003eb2 <iunlock>
  end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	9a4080e7          	jalr	-1628(ra) # 8000483a <end_op>

  return fd;
    80005e9e:	854a                	mv	a0,s2
}
    80005ea0:	70ea                	ld	ra,184(sp)
    80005ea2:	744a                	ld	s0,176(sp)
    80005ea4:	74aa                	ld	s1,168(sp)
    80005ea6:	790a                	ld	s2,160(sp)
    80005ea8:	69ea                	ld	s3,152(sp)
    80005eaa:	6129                	addi	sp,sp,192
    80005eac:	8082                	ret
      end_op();
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	98c080e7          	jalr	-1652(ra) # 8000483a <end_op>
      return -1;
    80005eb6:	557d                	li	a0,-1
    80005eb8:	b7e5                	j	80005ea0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005eba:	f5040513          	addi	a0,s0,-176
    80005ebe:	ffffe097          	auipc	ra,0xffffe
    80005ec2:	6de080e7          	jalr	1758(ra) # 8000459c <namei>
    80005ec6:	84aa                	mv	s1,a0
    80005ec8:	c905                	beqz	a0,80005ef8 <sys_open+0x13c>
    ilock(ip);
    80005eca:	ffffe097          	auipc	ra,0xffffe
    80005ece:	f26080e7          	jalr	-218(ra) # 80003df0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ed2:	04449703          	lh	a4,68(s1)
    80005ed6:	4785                	li	a5,1
    80005ed8:	f4f711e3          	bne	a4,a5,80005e1a <sys_open+0x5e>
    80005edc:	f4c42783          	lw	a5,-180(s0)
    80005ee0:	d7b9                	beqz	a5,80005e2e <sys_open+0x72>
      iunlockput(ip);
    80005ee2:	8526                	mv	a0,s1
    80005ee4:	ffffe097          	auipc	ra,0xffffe
    80005ee8:	16e080e7          	jalr	366(ra) # 80004052 <iunlockput>
      end_op();
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	94e080e7          	jalr	-1714(ra) # 8000483a <end_op>
      return -1;
    80005ef4:	557d                	li	a0,-1
    80005ef6:	b76d                	j	80005ea0 <sys_open+0xe4>
      end_op();
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	942080e7          	jalr	-1726(ra) # 8000483a <end_op>
      return -1;
    80005f00:	557d                	li	a0,-1
    80005f02:	bf79                	j	80005ea0 <sys_open+0xe4>
    iunlockput(ip);
    80005f04:	8526                	mv	a0,s1
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	14c080e7          	jalr	332(ra) # 80004052 <iunlockput>
    end_op();
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	92c080e7          	jalr	-1748(ra) # 8000483a <end_op>
    return -1;
    80005f16:	557d                	li	a0,-1
    80005f18:	b761                	j	80005ea0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f1a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f1e:	04649783          	lh	a5,70(s1)
    80005f22:	02f99223          	sh	a5,36(s3)
    80005f26:	bf25                	j	80005e5e <sys_open+0xa2>
    itrunc(ip);
    80005f28:	8526                	mv	a0,s1
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	fd4080e7          	jalr	-44(ra) # 80003efe <itrunc>
    80005f32:	bfa9                	j	80005e8c <sys_open+0xd0>
      fileclose(f);
    80005f34:	854e                	mv	a0,s3
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	d4e080e7          	jalr	-690(ra) # 80004c84 <fileclose>
    iunlockput(ip);
    80005f3e:	8526                	mv	a0,s1
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	112080e7          	jalr	274(ra) # 80004052 <iunlockput>
    end_op();
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	8f2080e7          	jalr	-1806(ra) # 8000483a <end_op>
    return -1;
    80005f50:	557d                	li	a0,-1
    80005f52:	b7b9                	j	80005ea0 <sys_open+0xe4>

0000000080005f54 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f54:	7175                	addi	sp,sp,-144
    80005f56:	e506                	sd	ra,136(sp)
    80005f58:	e122                	sd	s0,128(sp)
    80005f5a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	860080e7          	jalr	-1952(ra) # 800047bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f64:	08000613          	li	a2,128
    80005f68:	f7040593          	addi	a1,s0,-144
    80005f6c:	4501                	li	a0,0
    80005f6e:	ffffd097          	auipc	ra,0xffffd
    80005f72:	1cc080e7          	jalr	460(ra) # 8000313a <argstr>
    80005f76:	02054963          	bltz	a0,80005fa8 <sys_mkdir+0x54>
    80005f7a:	4681                	li	a3,0
    80005f7c:	4601                	li	a2,0
    80005f7e:	4585                	li	a1,1
    80005f80:	f7040513          	addi	a0,s0,-144
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	7da080e7          	jalr	2010(ra) # 8000575e <create>
    80005f8c:	cd11                	beqz	a0,80005fa8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	0c4080e7          	jalr	196(ra) # 80004052 <iunlockput>
  end_op();
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	8a4080e7          	jalr	-1884(ra) # 8000483a <end_op>
  return 0;
    80005f9e:	4501                	li	a0,0
}
    80005fa0:	60aa                	ld	ra,136(sp)
    80005fa2:	640a                	ld	s0,128(sp)
    80005fa4:	6149                	addi	sp,sp,144
    80005fa6:	8082                	ret
    end_op();
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	892080e7          	jalr	-1902(ra) # 8000483a <end_op>
    return -1;
    80005fb0:	557d                	li	a0,-1
    80005fb2:	b7fd                	j	80005fa0 <sys_mkdir+0x4c>

0000000080005fb4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fb4:	7135                	addi	sp,sp,-160
    80005fb6:	ed06                	sd	ra,152(sp)
    80005fb8:	e922                	sd	s0,144(sp)
    80005fba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	800080e7          	jalr	-2048(ra) # 800047bc <begin_op>
  argint(1, &major);
    80005fc4:	f6c40593          	addi	a1,s0,-148
    80005fc8:	4505                	li	a0,1
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	130080e7          	jalr	304(ra) # 800030fa <argint>
  argint(2, &minor);
    80005fd2:	f6840593          	addi	a1,s0,-152
    80005fd6:	4509                	li	a0,2
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	122080e7          	jalr	290(ra) # 800030fa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fe0:	08000613          	li	a2,128
    80005fe4:	f7040593          	addi	a1,s0,-144
    80005fe8:	4501                	li	a0,0
    80005fea:	ffffd097          	auipc	ra,0xffffd
    80005fee:	150080e7          	jalr	336(ra) # 8000313a <argstr>
    80005ff2:	02054b63          	bltz	a0,80006028 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ff6:	f6841683          	lh	a3,-152(s0)
    80005ffa:	f6c41603          	lh	a2,-148(s0)
    80005ffe:	458d                	li	a1,3
    80006000:	f7040513          	addi	a0,s0,-144
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	75a080e7          	jalr	1882(ra) # 8000575e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000600c:	cd11                	beqz	a0,80006028 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000600e:	ffffe097          	auipc	ra,0xffffe
    80006012:	044080e7          	jalr	68(ra) # 80004052 <iunlockput>
  end_op();
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	824080e7          	jalr	-2012(ra) # 8000483a <end_op>
  return 0;
    8000601e:	4501                	li	a0,0
}
    80006020:	60ea                	ld	ra,152(sp)
    80006022:	644a                	ld	s0,144(sp)
    80006024:	610d                	addi	sp,sp,160
    80006026:	8082                	ret
    end_op();
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	812080e7          	jalr	-2030(ra) # 8000483a <end_op>
    return -1;
    80006030:	557d                	li	a0,-1
    80006032:	b7fd                	j	80006020 <sys_mknod+0x6c>

0000000080006034 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006034:	7135                	addi	sp,sp,-160
    80006036:	ed06                	sd	ra,152(sp)
    80006038:	e922                	sd	s0,144(sp)
    8000603a:	e526                	sd	s1,136(sp)
    8000603c:	e14a                	sd	s2,128(sp)
    8000603e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006040:	ffffc097          	auipc	ra,0xffffc
    80006044:	b46080e7          	jalr	-1210(ra) # 80001b86 <myproc>
    80006048:	892a                	mv	s2,a0
  
  begin_op();
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	772080e7          	jalr	1906(ra) # 800047bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006052:	08000613          	li	a2,128
    80006056:	f6040593          	addi	a1,s0,-160
    8000605a:	4501                	li	a0,0
    8000605c:	ffffd097          	auipc	ra,0xffffd
    80006060:	0de080e7          	jalr	222(ra) # 8000313a <argstr>
    80006064:	04054b63          	bltz	a0,800060ba <sys_chdir+0x86>
    80006068:	f6040513          	addi	a0,s0,-160
    8000606c:	ffffe097          	auipc	ra,0xffffe
    80006070:	530080e7          	jalr	1328(ra) # 8000459c <namei>
    80006074:	84aa                	mv	s1,a0
    80006076:	c131                	beqz	a0,800060ba <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	d78080e7          	jalr	-648(ra) # 80003df0 <ilock>
  if(ip->type != T_DIR){
    80006080:	04449703          	lh	a4,68(s1)
    80006084:	4785                	li	a5,1
    80006086:	04f71063          	bne	a4,a5,800060c6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000608a:	8526                	mv	a0,s1
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	e26080e7          	jalr	-474(ra) # 80003eb2 <iunlock>
  iput(p->cwd);
    80006094:	15093503          	ld	a0,336(s2)
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	f12080e7          	jalr	-238(ra) # 80003faa <iput>
  end_op();
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	79a080e7          	jalr	1946(ra) # 8000483a <end_op>
  p->cwd = ip;
    800060a8:	14993823          	sd	s1,336(s2)
  return 0;
    800060ac:	4501                	li	a0,0
}
    800060ae:	60ea                	ld	ra,152(sp)
    800060b0:	644a                	ld	s0,144(sp)
    800060b2:	64aa                	ld	s1,136(sp)
    800060b4:	690a                	ld	s2,128(sp)
    800060b6:	610d                	addi	sp,sp,160
    800060b8:	8082                	ret
    end_op();
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	780080e7          	jalr	1920(ra) # 8000483a <end_op>
    return -1;
    800060c2:	557d                	li	a0,-1
    800060c4:	b7ed                	j	800060ae <sys_chdir+0x7a>
    iunlockput(ip);
    800060c6:	8526                	mv	a0,s1
    800060c8:	ffffe097          	auipc	ra,0xffffe
    800060cc:	f8a080e7          	jalr	-118(ra) # 80004052 <iunlockput>
    end_op();
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	76a080e7          	jalr	1898(ra) # 8000483a <end_op>
    return -1;
    800060d8:	557d                	li	a0,-1
    800060da:	bfd1                	j	800060ae <sys_chdir+0x7a>

00000000800060dc <sys_exec>:

uint64
sys_exec(void)
{
    800060dc:	7145                	addi	sp,sp,-464
    800060de:	e786                	sd	ra,456(sp)
    800060e0:	e3a2                	sd	s0,448(sp)
    800060e2:	ff26                	sd	s1,440(sp)
    800060e4:	fb4a                	sd	s2,432(sp)
    800060e6:	f74e                	sd	s3,424(sp)
    800060e8:	f352                	sd	s4,416(sp)
    800060ea:	ef56                	sd	s5,408(sp)
    800060ec:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800060ee:	e3840593          	addi	a1,s0,-456
    800060f2:	4505                	li	a0,1
    800060f4:	ffffd097          	auipc	ra,0xffffd
    800060f8:	026080e7          	jalr	38(ra) # 8000311a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800060fc:	08000613          	li	a2,128
    80006100:	f4040593          	addi	a1,s0,-192
    80006104:	4501                	li	a0,0
    80006106:	ffffd097          	auipc	ra,0xffffd
    8000610a:	034080e7          	jalr	52(ra) # 8000313a <argstr>
    8000610e:	87aa                	mv	a5,a0
    return -1;
    80006110:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006112:	0c07c363          	bltz	a5,800061d8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006116:	10000613          	li	a2,256
    8000611a:	4581                	li	a1,0
    8000611c:	e4040513          	addi	a0,s0,-448
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	d4a080e7          	jalr	-694(ra) # 80000e6a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006128:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000612c:	89a6                	mv	s3,s1
    8000612e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006130:	02000a13          	li	s4,32
    80006134:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006138:	00391513          	slli	a0,s2,0x3
    8000613c:	e3040593          	addi	a1,s0,-464
    80006140:	e3843783          	ld	a5,-456(s0)
    80006144:	953e                	add	a0,a0,a5
    80006146:	ffffd097          	auipc	ra,0xffffd
    8000614a:	f16080e7          	jalr	-234(ra) # 8000305c <fetchaddr>
    8000614e:	02054a63          	bltz	a0,80006182 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006152:	e3043783          	ld	a5,-464(s0)
    80006156:	c3b9                	beqz	a5,8000619c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006158:	ffffb097          	auipc	ra,0xffffb
    8000615c:	b12080e7          	jalr	-1262(ra) # 80000c6a <kalloc>
    80006160:	85aa                	mv	a1,a0
    80006162:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006166:	cd11                	beqz	a0,80006182 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006168:	6605                	lui	a2,0x1
    8000616a:	e3043503          	ld	a0,-464(s0)
    8000616e:	ffffd097          	auipc	ra,0xffffd
    80006172:	f40080e7          	jalr	-192(ra) # 800030ae <fetchstr>
    80006176:	00054663          	bltz	a0,80006182 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000617a:	0905                	addi	s2,s2,1
    8000617c:	09a1                	addi	s3,s3,8
    8000617e:	fb491be3          	bne	s2,s4,80006134 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006182:	f4040913          	addi	s2,s0,-192
    80006186:	6088                	ld	a0,0(s1)
    80006188:	c539                	beqz	a0,800061d6 <sys_exec+0xfa>
    kfree(argv[i]);
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	984080e7          	jalr	-1660(ra) # 80000b0e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006192:	04a1                	addi	s1,s1,8
    80006194:	ff2499e3          	bne	s1,s2,80006186 <sys_exec+0xaa>
  return -1;
    80006198:	557d                	li	a0,-1
    8000619a:	a83d                	j	800061d8 <sys_exec+0xfc>
      argv[i] = 0;
    8000619c:	0a8e                	slli	s5,s5,0x3
    8000619e:	fc0a8793          	addi	a5,s5,-64
    800061a2:	00878ab3          	add	s5,a5,s0
    800061a6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061aa:	e4040593          	addi	a1,s0,-448
    800061ae:	f4040513          	addi	a0,s0,-192
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	14c080e7          	jalr	332(ra) # 800052fe <exec>
    800061ba:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061bc:	f4040993          	addi	s3,s0,-192
    800061c0:	6088                	ld	a0,0(s1)
    800061c2:	c901                	beqz	a0,800061d2 <sys_exec+0xf6>
    kfree(argv[i]);
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	94a080e7          	jalr	-1718(ra) # 80000b0e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061cc:	04a1                	addi	s1,s1,8
    800061ce:	ff3499e3          	bne	s1,s3,800061c0 <sys_exec+0xe4>
  return ret;
    800061d2:	854a                	mv	a0,s2
    800061d4:	a011                	j	800061d8 <sys_exec+0xfc>
  return -1;
    800061d6:	557d                	li	a0,-1
}
    800061d8:	60be                	ld	ra,456(sp)
    800061da:	641e                	ld	s0,448(sp)
    800061dc:	74fa                	ld	s1,440(sp)
    800061de:	795a                	ld	s2,432(sp)
    800061e0:	79ba                	ld	s3,424(sp)
    800061e2:	7a1a                	ld	s4,416(sp)
    800061e4:	6afa                	ld	s5,408(sp)
    800061e6:	6179                	addi	sp,sp,464
    800061e8:	8082                	ret

00000000800061ea <sys_pipe>:

uint64
sys_pipe(void)
{
    800061ea:	7139                	addi	sp,sp,-64
    800061ec:	fc06                	sd	ra,56(sp)
    800061ee:	f822                	sd	s0,48(sp)
    800061f0:	f426                	sd	s1,40(sp)
    800061f2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061f4:	ffffc097          	auipc	ra,0xffffc
    800061f8:	992080e7          	jalr	-1646(ra) # 80001b86 <myproc>
    800061fc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800061fe:	fd840593          	addi	a1,s0,-40
    80006202:	4501                	li	a0,0
    80006204:	ffffd097          	auipc	ra,0xffffd
    80006208:	f16080e7          	jalr	-234(ra) # 8000311a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000620c:	fc840593          	addi	a1,s0,-56
    80006210:	fd040513          	addi	a0,s0,-48
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	da0080e7          	jalr	-608(ra) # 80004fb4 <pipealloc>
    return -1;
    8000621c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000621e:	0c054463          	bltz	a0,800062e6 <sys_pipe+0xfc>
  fd0 = -1;
    80006222:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006226:	fd043503          	ld	a0,-48(s0)
    8000622a:	fffff097          	auipc	ra,0xfffff
    8000622e:	4f2080e7          	jalr	1266(ra) # 8000571c <fdalloc>
    80006232:	fca42223          	sw	a0,-60(s0)
    80006236:	08054b63          	bltz	a0,800062cc <sys_pipe+0xe2>
    8000623a:	fc843503          	ld	a0,-56(s0)
    8000623e:	fffff097          	auipc	ra,0xfffff
    80006242:	4de080e7          	jalr	1246(ra) # 8000571c <fdalloc>
    80006246:	fca42023          	sw	a0,-64(s0)
    8000624a:	06054863          	bltz	a0,800062ba <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000624e:	4691                	li	a3,4
    80006250:	fc440613          	addi	a2,s0,-60
    80006254:	fd843583          	ld	a1,-40(s0)
    80006258:	68a8                	ld	a0,80(s1)
    8000625a:	ffffb097          	auipc	ra,0xffffb
    8000625e:	5b4080e7          	jalr	1460(ra) # 8000180e <copyout>
    80006262:	02054063          	bltz	a0,80006282 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006266:	4691                	li	a3,4
    80006268:	fc040613          	addi	a2,s0,-64
    8000626c:	fd843583          	ld	a1,-40(s0)
    80006270:	0591                	addi	a1,a1,4
    80006272:	68a8                	ld	a0,80(s1)
    80006274:	ffffb097          	auipc	ra,0xffffb
    80006278:	59a080e7          	jalr	1434(ra) # 8000180e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000627c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000627e:	06055463          	bgez	a0,800062e6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006282:	fc442783          	lw	a5,-60(s0)
    80006286:	07e9                	addi	a5,a5,26
    80006288:	078e                	slli	a5,a5,0x3
    8000628a:	97a6                	add	a5,a5,s1
    8000628c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006290:	fc042783          	lw	a5,-64(s0)
    80006294:	07e9                	addi	a5,a5,26
    80006296:	078e                	slli	a5,a5,0x3
    80006298:	94be                	add	s1,s1,a5
    8000629a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000629e:	fd043503          	ld	a0,-48(s0)
    800062a2:	fffff097          	auipc	ra,0xfffff
    800062a6:	9e2080e7          	jalr	-1566(ra) # 80004c84 <fileclose>
    fileclose(wf);
    800062aa:	fc843503          	ld	a0,-56(s0)
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	9d6080e7          	jalr	-1578(ra) # 80004c84 <fileclose>
    return -1;
    800062b6:	57fd                	li	a5,-1
    800062b8:	a03d                	j	800062e6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800062ba:	fc442783          	lw	a5,-60(s0)
    800062be:	0007c763          	bltz	a5,800062cc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800062c2:	07e9                	addi	a5,a5,26
    800062c4:	078e                	slli	a5,a5,0x3
    800062c6:	97a6                	add	a5,a5,s1
    800062c8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800062cc:	fd043503          	ld	a0,-48(s0)
    800062d0:	fffff097          	auipc	ra,0xfffff
    800062d4:	9b4080e7          	jalr	-1612(ra) # 80004c84 <fileclose>
    fileclose(wf);
    800062d8:	fc843503          	ld	a0,-56(s0)
    800062dc:	fffff097          	auipc	ra,0xfffff
    800062e0:	9a8080e7          	jalr	-1624(ra) # 80004c84 <fileclose>
    return -1;
    800062e4:	57fd                	li	a5,-1
}
    800062e6:	853e                	mv	a0,a5
    800062e8:	70e2                	ld	ra,56(sp)
    800062ea:	7442                	ld	s0,48(sp)
    800062ec:	74a2                	ld	s1,40(sp)
    800062ee:	6121                	addi	sp,sp,64
    800062f0:	8082                	ret
	...

0000000080006300 <kernelvec>:
    80006300:	7111                	addi	sp,sp,-256
    80006302:	e006                	sd	ra,0(sp)
    80006304:	e40a                	sd	sp,8(sp)
    80006306:	e80e                	sd	gp,16(sp)
    80006308:	ec12                	sd	tp,24(sp)
    8000630a:	f016                	sd	t0,32(sp)
    8000630c:	f41a                	sd	t1,40(sp)
    8000630e:	f81e                	sd	t2,48(sp)
    80006310:	fc22                	sd	s0,56(sp)
    80006312:	e0a6                	sd	s1,64(sp)
    80006314:	e4aa                	sd	a0,72(sp)
    80006316:	e8ae                	sd	a1,80(sp)
    80006318:	ecb2                	sd	a2,88(sp)
    8000631a:	f0b6                	sd	a3,96(sp)
    8000631c:	f4ba                	sd	a4,104(sp)
    8000631e:	f8be                	sd	a5,112(sp)
    80006320:	fcc2                	sd	a6,120(sp)
    80006322:	e146                	sd	a7,128(sp)
    80006324:	e54a                	sd	s2,136(sp)
    80006326:	e94e                	sd	s3,144(sp)
    80006328:	ed52                	sd	s4,152(sp)
    8000632a:	f156                	sd	s5,160(sp)
    8000632c:	f55a                	sd	s6,168(sp)
    8000632e:	f95e                	sd	s7,176(sp)
    80006330:	fd62                	sd	s8,184(sp)
    80006332:	e1e6                	sd	s9,192(sp)
    80006334:	e5ea                	sd	s10,200(sp)
    80006336:	e9ee                	sd	s11,208(sp)
    80006338:	edf2                	sd	t3,216(sp)
    8000633a:	f1f6                	sd	t4,224(sp)
    8000633c:	f5fa                	sd	t5,232(sp)
    8000633e:	f9fe                	sd	t6,240(sp)
    80006340:	be9fc0ef          	jal	ra,80002f28 <kerneltrap>
    80006344:	6082                	ld	ra,0(sp)
    80006346:	6122                	ld	sp,8(sp)
    80006348:	61c2                	ld	gp,16(sp)
    8000634a:	7282                	ld	t0,32(sp)
    8000634c:	7322                	ld	t1,40(sp)
    8000634e:	73c2                	ld	t2,48(sp)
    80006350:	7462                	ld	s0,56(sp)
    80006352:	6486                	ld	s1,64(sp)
    80006354:	6526                	ld	a0,72(sp)
    80006356:	65c6                	ld	a1,80(sp)
    80006358:	6666                	ld	a2,88(sp)
    8000635a:	7686                	ld	a3,96(sp)
    8000635c:	7726                	ld	a4,104(sp)
    8000635e:	77c6                	ld	a5,112(sp)
    80006360:	7866                	ld	a6,120(sp)
    80006362:	688a                	ld	a7,128(sp)
    80006364:	692a                	ld	s2,136(sp)
    80006366:	69ca                	ld	s3,144(sp)
    80006368:	6a6a                	ld	s4,152(sp)
    8000636a:	7a8a                	ld	s5,160(sp)
    8000636c:	7b2a                	ld	s6,168(sp)
    8000636e:	7bca                	ld	s7,176(sp)
    80006370:	7c6a                	ld	s8,184(sp)
    80006372:	6c8e                	ld	s9,192(sp)
    80006374:	6d2e                	ld	s10,200(sp)
    80006376:	6dce                	ld	s11,208(sp)
    80006378:	6e6e                	ld	t3,216(sp)
    8000637a:	7e8e                	ld	t4,224(sp)
    8000637c:	7f2e                	ld	t5,232(sp)
    8000637e:	7fce                	ld	t6,240(sp)
    80006380:	6111                	addi	sp,sp,256
    80006382:	10200073          	sret
    80006386:	00000013          	nop
    8000638a:	00000013          	nop
    8000638e:	0001                	nop

0000000080006390 <timervec>:
    80006390:	34051573          	csrrw	a0,mscratch,a0
    80006394:	e10c                	sd	a1,0(a0)
    80006396:	e510                	sd	a2,8(a0)
    80006398:	e914                	sd	a3,16(a0)
    8000639a:	6d0c                	ld	a1,24(a0)
    8000639c:	7110                	ld	a2,32(a0)
    8000639e:	6194                	ld	a3,0(a1)
    800063a0:	96b2                	add	a3,a3,a2
    800063a2:	e194                	sd	a3,0(a1)
    800063a4:	4589                	li	a1,2
    800063a6:	14459073          	csrw	sip,a1
    800063aa:	6914                	ld	a3,16(a0)
    800063ac:	6510                	ld	a2,8(a0)
    800063ae:	610c                	ld	a1,0(a0)
    800063b0:	34051573          	csrrw	a0,mscratch,a0
    800063b4:	30200073          	mret
	...

00000000800063ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ba:	1141                	addi	sp,sp,-16
    800063bc:	e422                	sd	s0,8(sp)
    800063be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063c0:	0c0007b7          	lui	a5,0xc000
    800063c4:	4705                	li	a4,1
    800063c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063c8:	c3d8                	sw	a4,4(a5)
}
    800063ca:	6422                	ld	s0,8(sp)
    800063cc:	0141                	addi	sp,sp,16
    800063ce:	8082                	ret

00000000800063d0 <plicinithart>:

void
plicinithart(void)
{
    800063d0:	1141                	addi	sp,sp,-16
    800063d2:	e406                	sd	ra,8(sp)
    800063d4:	e022                	sd	s0,0(sp)
    800063d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063d8:	ffffb097          	auipc	ra,0xffffb
    800063dc:	782080e7          	jalr	1922(ra) # 80001b5a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063e0:	0085171b          	slliw	a4,a0,0x8
    800063e4:	0c0027b7          	lui	a5,0xc002
    800063e8:	97ba                	add	a5,a5,a4
    800063ea:	40200713          	li	a4,1026
    800063ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063f2:	00d5151b          	slliw	a0,a0,0xd
    800063f6:	0c2017b7          	lui	a5,0xc201
    800063fa:	97aa                	add	a5,a5,a0
    800063fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006400:	60a2                	ld	ra,8(sp)
    80006402:	6402                	ld	s0,0(sp)
    80006404:	0141                	addi	sp,sp,16
    80006406:	8082                	ret

0000000080006408 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006408:	1141                	addi	sp,sp,-16
    8000640a:	e406                	sd	ra,8(sp)
    8000640c:	e022                	sd	s0,0(sp)
    8000640e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	74a080e7          	jalr	1866(ra) # 80001b5a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006418:	00d5151b          	slliw	a0,a0,0xd
    8000641c:	0c2017b7          	lui	a5,0xc201
    80006420:	97aa                	add	a5,a5,a0
  return irq;
}
    80006422:	43c8                	lw	a0,4(a5)
    80006424:	60a2                	ld	ra,8(sp)
    80006426:	6402                	ld	s0,0(sp)
    80006428:	0141                	addi	sp,sp,16
    8000642a:	8082                	ret

000000008000642c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000642c:	1101                	addi	sp,sp,-32
    8000642e:	ec06                	sd	ra,24(sp)
    80006430:	e822                	sd	s0,16(sp)
    80006432:	e426                	sd	s1,8(sp)
    80006434:	1000                	addi	s0,sp,32
    80006436:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006438:	ffffb097          	auipc	ra,0xffffb
    8000643c:	722080e7          	jalr	1826(ra) # 80001b5a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006440:	00d5151b          	slliw	a0,a0,0xd
    80006444:	0c2017b7          	lui	a5,0xc201
    80006448:	97aa                	add	a5,a5,a0
    8000644a:	c3c4                	sw	s1,4(a5)
}
    8000644c:	60e2                	ld	ra,24(sp)
    8000644e:	6442                	ld	s0,16(sp)
    80006450:	64a2                	ld	s1,8(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret

0000000080006456 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006456:	1141                	addi	sp,sp,-16
    80006458:	e406                	sd	ra,8(sp)
    8000645a:	e022                	sd	s0,0(sp)
    8000645c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000645e:	479d                	li	a5,7
    80006460:	04a7cc63          	blt	a5,a0,800064b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006464:	0023c797          	auipc	a5,0x23c
    80006468:	23478793          	addi	a5,a5,564 # 80242698 <disk>
    8000646c:	97aa                	add	a5,a5,a0
    8000646e:	0187c783          	lbu	a5,24(a5)
    80006472:	ebb9                	bnez	a5,800064c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006474:	00451693          	slli	a3,a0,0x4
    80006478:	0023c797          	auipc	a5,0x23c
    8000647c:	22078793          	addi	a5,a5,544 # 80242698 <disk>
    80006480:	6398                	ld	a4,0(a5)
    80006482:	9736                	add	a4,a4,a3
    80006484:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006488:	6398                	ld	a4,0(a5)
    8000648a:	9736                	add	a4,a4,a3
    8000648c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006490:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006494:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006498:	97aa                	add	a5,a5,a0
    8000649a:	4705                	li	a4,1
    8000649c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800064a0:	0023c517          	auipc	a0,0x23c
    800064a4:	21050513          	addi	a0,a0,528 # 802426b0 <disk+0x18>
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	f4a080e7          	jalr	-182(ra) # 800023f2 <wakeup>
}
    800064b0:	60a2                	ld	ra,8(sp)
    800064b2:	6402                	ld	s0,0(sp)
    800064b4:	0141                	addi	sp,sp,16
    800064b6:	8082                	ret
    panic("free_desc 1");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	2e050513          	addi	a0,a0,736 # 80008798 <syscalls+0x320>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	080080e7          	jalr	128(ra) # 80000540 <panic>
    panic("free_desc 2");
    800064c8:	00002517          	auipc	a0,0x2
    800064cc:	2e050513          	addi	a0,a0,736 # 800087a8 <syscalls+0x330>
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	070080e7          	jalr	112(ra) # 80000540 <panic>

00000000800064d8 <virtio_disk_init>:
{
    800064d8:	1101                	addi	sp,sp,-32
    800064da:	ec06                	sd	ra,24(sp)
    800064dc:	e822                	sd	s0,16(sp)
    800064de:	e426                	sd	s1,8(sp)
    800064e0:	e04a                	sd	s2,0(sp)
    800064e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064e4:	00002597          	auipc	a1,0x2
    800064e8:	2d458593          	addi	a1,a1,724 # 800087b8 <syscalls+0x340>
    800064ec:	0023c517          	auipc	a0,0x23c
    800064f0:	2d450513          	addi	a0,a0,724 # 802427c0 <disk+0x128>
    800064f4:	ffffa097          	auipc	ra,0xffffa
    800064f8:	7ea080e7          	jalr	2026(ra) # 80000cde <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064fc:	100017b7          	lui	a5,0x10001
    80006500:	4398                	lw	a4,0(a5)
    80006502:	2701                	sext.w	a4,a4
    80006504:	747277b7          	lui	a5,0x74727
    80006508:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000650c:	14f71b63          	bne	a4,a5,80006662 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006510:	100017b7          	lui	a5,0x10001
    80006514:	43dc                	lw	a5,4(a5)
    80006516:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006518:	4709                	li	a4,2
    8000651a:	14e79463          	bne	a5,a4,80006662 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000651e:	100017b7          	lui	a5,0x10001
    80006522:	479c                	lw	a5,8(a5)
    80006524:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006526:	12e79e63          	bne	a5,a4,80006662 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000652a:	100017b7          	lui	a5,0x10001
    8000652e:	47d8                	lw	a4,12(a5)
    80006530:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006532:	554d47b7          	lui	a5,0x554d4
    80006536:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000653a:	12f71463          	bne	a4,a5,80006662 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000653e:	100017b7          	lui	a5,0x10001
    80006542:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006546:	4705                	li	a4,1
    80006548:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000654a:	470d                	li	a4,3
    8000654c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000654e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006550:	c7ffe6b7          	lui	a3,0xc7ffe
    80006554:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbbf87>
    80006558:	8f75                	and	a4,a4,a3
    8000655a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000655c:	472d                	li	a4,11
    8000655e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006560:	5bbc                	lw	a5,112(a5)
    80006562:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006566:	8ba1                	andi	a5,a5,8
    80006568:	10078563          	beqz	a5,80006672 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000656c:	100017b7          	lui	a5,0x10001
    80006570:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006574:	43fc                	lw	a5,68(a5)
    80006576:	2781                	sext.w	a5,a5
    80006578:	10079563          	bnez	a5,80006682 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000657c:	100017b7          	lui	a5,0x10001
    80006580:	5bdc                	lw	a5,52(a5)
    80006582:	2781                	sext.w	a5,a5
  if(max == 0)
    80006584:	10078763          	beqz	a5,80006692 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006588:	471d                	li	a4,7
    8000658a:	10f77c63          	bgeu	a4,a5,800066a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	6dc080e7          	jalr	1756(ra) # 80000c6a <kalloc>
    80006596:	0023c497          	auipc	s1,0x23c
    8000659a:	10248493          	addi	s1,s1,258 # 80242698 <disk>
    8000659e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	6ca080e7          	jalr	1738(ra) # 80000c6a <kalloc>
    800065a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	6c0080e7          	jalr	1728(ra) # 80000c6a <kalloc>
    800065b2:	87aa                	mv	a5,a0
    800065b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800065b6:	6088                	ld	a0,0(s1)
    800065b8:	cd6d                	beqz	a0,800066b2 <virtio_disk_init+0x1da>
    800065ba:	0023c717          	auipc	a4,0x23c
    800065be:	0e673703          	ld	a4,230(a4) # 802426a0 <disk+0x8>
    800065c2:	cb65                	beqz	a4,800066b2 <virtio_disk_init+0x1da>
    800065c4:	c7fd                	beqz	a5,800066b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800065c6:	6605                	lui	a2,0x1
    800065c8:	4581                	li	a1,0
    800065ca:	ffffb097          	auipc	ra,0xffffb
    800065ce:	8a0080e7          	jalr	-1888(ra) # 80000e6a <memset>
  memset(disk.avail, 0, PGSIZE);
    800065d2:	0023c497          	auipc	s1,0x23c
    800065d6:	0c648493          	addi	s1,s1,198 # 80242698 <disk>
    800065da:	6605                	lui	a2,0x1
    800065dc:	4581                	li	a1,0
    800065de:	6488                	ld	a0,8(s1)
    800065e0:	ffffb097          	auipc	ra,0xffffb
    800065e4:	88a080e7          	jalr	-1910(ra) # 80000e6a <memset>
  memset(disk.used, 0, PGSIZE);
    800065e8:	6605                	lui	a2,0x1
    800065ea:	4581                	li	a1,0
    800065ec:	6888                	ld	a0,16(s1)
    800065ee:	ffffb097          	auipc	ra,0xffffb
    800065f2:	87c080e7          	jalr	-1924(ra) # 80000e6a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065f6:	100017b7          	lui	a5,0x10001
    800065fa:	4721                	li	a4,8
    800065fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800065fe:	4098                	lw	a4,0(s1)
    80006600:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006604:	40d8                	lw	a4,4(s1)
    80006606:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000660a:	6498                	ld	a4,8(s1)
    8000660c:	0007069b          	sext.w	a3,a4
    80006610:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006614:	9701                	srai	a4,a4,0x20
    80006616:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000661a:	6898                	ld	a4,16(s1)
    8000661c:	0007069b          	sext.w	a3,a4
    80006620:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006624:	9701                	srai	a4,a4,0x20
    80006626:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000662a:	4705                	li	a4,1
    8000662c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000662e:	00e48c23          	sb	a4,24(s1)
    80006632:	00e48ca3          	sb	a4,25(s1)
    80006636:	00e48d23          	sb	a4,26(s1)
    8000663a:	00e48da3          	sb	a4,27(s1)
    8000663e:	00e48e23          	sb	a4,28(s1)
    80006642:	00e48ea3          	sb	a4,29(s1)
    80006646:	00e48f23          	sb	a4,30(s1)
    8000664a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000664e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006652:	0727a823          	sw	s2,112(a5)
}
    80006656:	60e2                	ld	ra,24(sp)
    80006658:	6442                	ld	s0,16(sp)
    8000665a:	64a2                	ld	s1,8(sp)
    8000665c:	6902                	ld	s2,0(sp)
    8000665e:	6105                	addi	sp,sp,32
    80006660:	8082                	ret
    panic("could not find virtio disk");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	16650513          	addi	a0,a0,358 # 800087c8 <syscalls+0x350>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed6080e7          	jalr	-298(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006672:	00002517          	auipc	a0,0x2
    80006676:	17650513          	addi	a0,a0,374 # 800087e8 <syscalls+0x370>
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	ec6080e7          	jalr	-314(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006682:	00002517          	auipc	a0,0x2
    80006686:	18650513          	addi	a0,a0,390 # 80008808 <syscalls+0x390>
    8000668a:	ffffa097          	auipc	ra,0xffffa
    8000668e:	eb6080e7          	jalr	-330(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006692:	00002517          	auipc	a0,0x2
    80006696:	19650513          	addi	a0,a0,406 # 80008828 <syscalls+0x3b0>
    8000669a:	ffffa097          	auipc	ra,0xffffa
    8000669e:	ea6080e7          	jalr	-346(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800066a2:	00002517          	auipc	a0,0x2
    800066a6:	1a650513          	addi	a0,a0,422 # 80008848 <syscalls+0x3d0>
    800066aa:	ffffa097          	auipc	ra,0xffffa
    800066ae:	e96080e7          	jalr	-362(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800066b2:	00002517          	auipc	a0,0x2
    800066b6:	1b650513          	addi	a0,a0,438 # 80008868 <syscalls+0x3f0>
    800066ba:	ffffa097          	auipc	ra,0xffffa
    800066be:	e86080e7          	jalr	-378(ra) # 80000540 <panic>

00000000800066c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066c2:	7119                	addi	sp,sp,-128
    800066c4:	fc86                	sd	ra,120(sp)
    800066c6:	f8a2                	sd	s0,112(sp)
    800066c8:	f4a6                	sd	s1,104(sp)
    800066ca:	f0ca                	sd	s2,96(sp)
    800066cc:	ecce                	sd	s3,88(sp)
    800066ce:	e8d2                	sd	s4,80(sp)
    800066d0:	e4d6                	sd	s5,72(sp)
    800066d2:	e0da                	sd	s6,64(sp)
    800066d4:	fc5e                	sd	s7,56(sp)
    800066d6:	f862                	sd	s8,48(sp)
    800066d8:	f466                	sd	s9,40(sp)
    800066da:	f06a                	sd	s10,32(sp)
    800066dc:	ec6e                	sd	s11,24(sp)
    800066de:	0100                	addi	s0,sp,128
    800066e0:	8aaa                	mv	s5,a0
    800066e2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066e4:	00c52d03          	lw	s10,12(a0)
    800066e8:	001d1d1b          	slliw	s10,s10,0x1
    800066ec:	1d02                	slli	s10,s10,0x20
    800066ee:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800066f2:	0023c517          	auipc	a0,0x23c
    800066f6:	0ce50513          	addi	a0,a0,206 # 802427c0 <disk+0x128>
    800066fa:	ffffa097          	auipc	ra,0xffffa
    800066fe:	674080e7          	jalr	1652(ra) # 80000d6e <acquire>
  for(int i = 0; i < 3; i++){
    80006702:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006704:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006706:	0023cb97          	auipc	s7,0x23c
    8000670a:	f92b8b93          	addi	s7,s7,-110 # 80242698 <disk>
  for(int i = 0; i < 3; i++){
    8000670e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006710:	0023cc97          	auipc	s9,0x23c
    80006714:	0b0c8c93          	addi	s9,s9,176 # 802427c0 <disk+0x128>
    80006718:	a08d                	j	8000677a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000671a:	00fb8733          	add	a4,s7,a5
    8000671e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006722:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006724:	0207c563          	bltz	a5,8000674e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006728:	2905                	addiw	s2,s2,1
    8000672a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000672c:	05690c63          	beq	s2,s6,80006784 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006730:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006732:	0023c717          	auipc	a4,0x23c
    80006736:	f6670713          	addi	a4,a4,-154 # 80242698 <disk>
    8000673a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000673c:	01874683          	lbu	a3,24(a4)
    80006740:	fee9                	bnez	a3,8000671a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006742:	2785                	addiw	a5,a5,1
    80006744:	0705                	addi	a4,a4,1
    80006746:	fe979be3          	bne	a5,s1,8000673c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000674a:	57fd                	li	a5,-1
    8000674c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000674e:	01205d63          	blez	s2,80006768 <virtio_disk_rw+0xa6>
    80006752:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006754:	000a2503          	lw	a0,0(s4)
    80006758:	00000097          	auipc	ra,0x0
    8000675c:	cfe080e7          	jalr	-770(ra) # 80006456 <free_desc>
      for(int j = 0; j < i; j++)
    80006760:	2d85                	addiw	s11,s11,1
    80006762:	0a11                	addi	s4,s4,4
    80006764:	ff2d98e3          	bne	s11,s2,80006754 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006768:	85e6                	mv	a1,s9
    8000676a:	0023c517          	auipc	a0,0x23c
    8000676e:	f4650513          	addi	a0,a0,-186 # 802426b0 <disk+0x18>
    80006772:	ffffc097          	auipc	ra,0xffffc
    80006776:	c1c080e7          	jalr	-996(ra) # 8000238e <sleep>
  for(int i = 0; i < 3; i++){
    8000677a:	f8040a13          	addi	s4,s0,-128
{
    8000677e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006780:	894e                	mv	s2,s3
    80006782:	b77d                	j	80006730 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006784:	f8042503          	lw	a0,-128(s0)
    80006788:	00a50713          	addi	a4,a0,10
    8000678c:	0712                	slli	a4,a4,0x4

  if(write)
    8000678e:	0023c797          	auipc	a5,0x23c
    80006792:	f0a78793          	addi	a5,a5,-246 # 80242698 <disk>
    80006796:	00e786b3          	add	a3,a5,a4
    8000679a:	01803633          	snez	a2,s8
    8000679e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800067a4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067a8:	f6070613          	addi	a2,a4,-160
    800067ac:	6394                	ld	a3,0(a5)
    800067ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067b0:	00870593          	addi	a1,a4,8
    800067b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800067b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067b8:	0007b803          	ld	a6,0(a5)
    800067bc:	9642                	add	a2,a2,a6
    800067be:	46c1                	li	a3,16
    800067c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067c2:	4585                	li	a1,1
    800067c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800067c8:	f8442683          	lw	a3,-124(s0)
    800067cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800067d0:	0692                	slli	a3,a3,0x4
    800067d2:	9836                	add	a6,a6,a3
    800067d4:	058a8613          	addi	a2,s5,88
    800067d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800067dc:	0007b803          	ld	a6,0(a5)
    800067e0:	96c2                	add	a3,a3,a6
    800067e2:	40000613          	li	a2,1024
    800067e6:	c690                	sw	a2,8(a3)
  if(write)
    800067e8:	001c3613          	seqz	a2,s8
    800067ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067f0:	00166613          	ori	a2,a2,1
    800067f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067f8:	f8842603          	lw	a2,-120(s0)
    800067fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006800:	00250693          	addi	a3,a0,2
    80006804:	0692                	slli	a3,a3,0x4
    80006806:	96be                	add	a3,a3,a5
    80006808:	58fd                	li	a7,-1
    8000680a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000680e:	0612                	slli	a2,a2,0x4
    80006810:	9832                	add	a6,a6,a2
    80006812:	f9070713          	addi	a4,a4,-112
    80006816:	973e                	add	a4,a4,a5
    80006818:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000681c:	6398                	ld	a4,0(a5)
    8000681e:	9732                	add	a4,a4,a2
    80006820:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006822:	4609                	li	a2,2
    80006824:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006828:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000682c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006830:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006834:	6794                	ld	a3,8(a5)
    80006836:	0026d703          	lhu	a4,2(a3)
    8000683a:	8b1d                	andi	a4,a4,7
    8000683c:	0706                	slli	a4,a4,0x1
    8000683e:	96ba                	add	a3,a3,a4
    80006840:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006844:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006848:	6798                	ld	a4,8(a5)
    8000684a:	00275783          	lhu	a5,2(a4)
    8000684e:	2785                	addiw	a5,a5,1
    80006850:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006854:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006858:	100017b7          	lui	a5,0x10001
    8000685c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006860:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006864:	0023c917          	auipc	s2,0x23c
    80006868:	f5c90913          	addi	s2,s2,-164 # 802427c0 <disk+0x128>
  while(b->disk == 1) {
    8000686c:	4485                	li	s1,1
    8000686e:	00b79c63          	bne	a5,a1,80006886 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006872:	85ca                	mv	a1,s2
    80006874:	8556                	mv	a0,s5
    80006876:	ffffc097          	auipc	ra,0xffffc
    8000687a:	b18080e7          	jalr	-1256(ra) # 8000238e <sleep>
  while(b->disk == 1) {
    8000687e:	004aa783          	lw	a5,4(s5)
    80006882:	fe9788e3          	beq	a5,s1,80006872 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006886:	f8042903          	lw	s2,-128(s0)
    8000688a:	00290713          	addi	a4,s2,2
    8000688e:	0712                	slli	a4,a4,0x4
    80006890:	0023c797          	auipc	a5,0x23c
    80006894:	e0878793          	addi	a5,a5,-504 # 80242698 <disk>
    80006898:	97ba                	add	a5,a5,a4
    8000689a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000689e:	0023c997          	auipc	s3,0x23c
    800068a2:	dfa98993          	addi	s3,s3,-518 # 80242698 <disk>
    800068a6:	00491713          	slli	a4,s2,0x4
    800068aa:	0009b783          	ld	a5,0(s3)
    800068ae:	97ba                	add	a5,a5,a4
    800068b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068b4:	854a                	mv	a0,s2
    800068b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068ba:	00000097          	auipc	ra,0x0
    800068be:	b9c080e7          	jalr	-1124(ra) # 80006456 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068c2:	8885                	andi	s1,s1,1
    800068c4:	f0ed                	bnez	s1,800068a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068c6:	0023c517          	auipc	a0,0x23c
    800068ca:	efa50513          	addi	a0,a0,-262 # 802427c0 <disk+0x128>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	554080e7          	jalr	1364(ra) # 80000e22 <release>
}
    800068d6:	70e6                	ld	ra,120(sp)
    800068d8:	7446                	ld	s0,112(sp)
    800068da:	74a6                	ld	s1,104(sp)
    800068dc:	7906                	ld	s2,96(sp)
    800068de:	69e6                	ld	s3,88(sp)
    800068e0:	6a46                	ld	s4,80(sp)
    800068e2:	6aa6                	ld	s5,72(sp)
    800068e4:	6b06                	ld	s6,64(sp)
    800068e6:	7be2                	ld	s7,56(sp)
    800068e8:	7c42                	ld	s8,48(sp)
    800068ea:	7ca2                	ld	s9,40(sp)
    800068ec:	7d02                	ld	s10,32(sp)
    800068ee:	6de2                	ld	s11,24(sp)
    800068f0:	6109                	addi	sp,sp,128
    800068f2:	8082                	ret

00000000800068f4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068f4:	1101                	addi	sp,sp,-32
    800068f6:	ec06                	sd	ra,24(sp)
    800068f8:	e822                	sd	s0,16(sp)
    800068fa:	e426                	sd	s1,8(sp)
    800068fc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068fe:	0023c497          	auipc	s1,0x23c
    80006902:	d9a48493          	addi	s1,s1,-614 # 80242698 <disk>
    80006906:	0023c517          	auipc	a0,0x23c
    8000690a:	eba50513          	addi	a0,a0,-326 # 802427c0 <disk+0x128>
    8000690e:	ffffa097          	auipc	ra,0xffffa
    80006912:	460080e7          	jalr	1120(ra) # 80000d6e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006916:	10001737          	lui	a4,0x10001
    8000691a:	533c                	lw	a5,96(a4)
    8000691c:	8b8d                	andi	a5,a5,3
    8000691e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006920:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006924:	689c                	ld	a5,16(s1)
    80006926:	0204d703          	lhu	a4,32(s1)
    8000692a:	0027d783          	lhu	a5,2(a5)
    8000692e:	04f70863          	beq	a4,a5,8000697e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006932:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006936:	6898                	ld	a4,16(s1)
    80006938:	0204d783          	lhu	a5,32(s1)
    8000693c:	8b9d                	andi	a5,a5,7
    8000693e:	078e                	slli	a5,a5,0x3
    80006940:	97ba                	add	a5,a5,a4
    80006942:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006944:	00278713          	addi	a4,a5,2
    80006948:	0712                	slli	a4,a4,0x4
    8000694a:	9726                	add	a4,a4,s1
    8000694c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006950:	e721                	bnez	a4,80006998 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006952:	0789                	addi	a5,a5,2
    80006954:	0792                	slli	a5,a5,0x4
    80006956:	97a6                	add	a5,a5,s1
    80006958:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000695a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000695e:	ffffc097          	auipc	ra,0xffffc
    80006962:	a94080e7          	jalr	-1388(ra) # 800023f2 <wakeup>

    disk.used_idx += 1;
    80006966:	0204d783          	lhu	a5,32(s1)
    8000696a:	2785                	addiw	a5,a5,1
    8000696c:	17c2                	slli	a5,a5,0x30
    8000696e:	93c1                	srli	a5,a5,0x30
    80006970:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006974:	6898                	ld	a4,16(s1)
    80006976:	00275703          	lhu	a4,2(a4)
    8000697a:	faf71ce3          	bne	a4,a5,80006932 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000697e:	0023c517          	auipc	a0,0x23c
    80006982:	e4250513          	addi	a0,a0,-446 # 802427c0 <disk+0x128>
    80006986:	ffffa097          	auipc	ra,0xffffa
    8000698a:	49c080e7          	jalr	1180(ra) # 80000e22 <release>
}
    8000698e:	60e2                	ld	ra,24(sp)
    80006990:	6442                	ld	s0,16(sp)
    80006992:	64a2                	ld	s1,8(sp)
    80006994:	6105                	addi	sp,sp,32
    80006996:	8082                	ret
      panic("virtio_disk_intr status");
    80006998:	00002517          	auipc	a0,0x2
    8000699c:	ee850513          	addi	a0,a0,-280 # 80008880 <syscalls+0x408>
    800069a0:	ffffa097          	auipc	ra,0xffffa
    800069a4:	ba0080e7          	jalr	-1120(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
